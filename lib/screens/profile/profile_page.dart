import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/api_config.dart';
import '../../screens/order/orders_page.dart';
import '../../screens/main/favorites_page.dart';
import '../../screens/product/recently_viewed_page.dart';
import '../../screens/profile/notification_page.dart';
import '../../screens/profile/settings_page.dart';
import '../../screens/profile/view_profile_page.dart';
import '../../screens/auth/login_page.dart';
import '../../screens/product/product_detail_page.dart';
import '../../screens/main/cart_page.dart';
import '../../screens/chat/chat_list_page.dart';
import '../../main.dart';
import '../../screens/review/my_reviews_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedBottomNavIndex = 3;
  bool _isVacationMode = false;
  String _fullName = '';
  String _email = '';
  String _profilePictureUrl = '';

  List<dynamic> _myProducts = [];
  bool _isLoadingProducts = false;
  int _myUserId = 0;
  int _unreadChatCount = 0;
  int _unreadNotificationsCount = 0;
  int _unreadOrdersCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  String _formatPrice(dynamic price) {
    final str = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullName = prefs.getString('full_name') ?? 'Pengguna';
      _email = prefs.getString('email') ?? '';
      _profilePictureUrl = prefs.getString('profile_picture_url') ?? '';
      _myUserId = prefs.getInt('user_id') ?? 0;
      _isVacationMode = prefs.getBool('is_vacation') ?? false;
      _isVacationMode = prefs.getBool('is_vacation') ?? false;
    });
    _fetchProfile();
    _fetchMyProducts();
    _fetchUnreadCount();
    _fetchNotificationBadges();
  }

  Future<void> _fetchNotificationBadges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/notifications/unread-count'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _unreadNotificationsCount = data['data']['total_unread'] ?? 0;
            _unreadOrdersCount = data['data']['order_unread'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching badges: $e');
    }
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/chats/unread-count'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _unreadChatCount = data['unread_count'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }

  Future<void> _fetchMyProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/products'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> allProducts = data['data'] ?? [];
        setState(() {
          _myProducts = allProducts
              .where((p) => p['user_id'] == _myUserId)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching my products: $e');
    } finally {
      setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _toggleVacationMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/user/vacation'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isVacation = data['is_vacation'] == true;
        setState(() => _isVacationMode = isVacation);
        await prefs.setBool('is_vacation', isVacation);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['message'] ??
                    (isVacation
                        ? 'Mode liburan diaktifkan'
                        : 'Mode liburan dinonaktifkan'),
                style: GoogleFonts.inter(),
              ),
              backgroundColor: const Color(0xFF74070E),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling vacation mode: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal mengubah mode liburan',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: const Color(0xFF74070E),
          ),
        );
      }
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/profile'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['user'] != null) {
          final isVac =
              data['user']['is_vacation'] == 1 ||
              data['user']['is_vacation'] == true;
          setState(() {
            _isVacationMode = isVac;
          });
          await prefs.setBool('is_vacation', isVac);
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  void _showFullImage() {
    if (_profilePictureUrl.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                child: Image.network(
                  '${ApiConfig.host}/uploads/profiles/$_profilePictureUrl',
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Gradient at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 180,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFD36B6B).withOpacity(0.8),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: RefreshIndicator(
              color: const Color(0xFF74070E),
              backgroundColor: Colors.white,
              onRefresh: _loadUserData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  // Header (Profile + Icons)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        GestureDetector(
                          onTap: _showFullImage,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[300],
                            ),
                            child: ClipOval(
                              child: _profilePictureUrl.isNotEmpty
                                  ? Image.network(
                                      '${ApiConfig.host}/uploads/profiles/$_profilePictureUrl',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                              ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Name and 'Lihat Profil'
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ViewProfilePage(),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fullName,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Lihat Profil',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_forward,
                                      size: 14,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Icons (Basket, Chat)
                        // Icons (Basket, Chat)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CartPage(),
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.shopping_basket_outlined,
                            color: Color(0xFF74070E),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ChatListPage(),
                              ),
                            ).then((_) => _fetchUnreadCount());
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(
                                Icons.chat_outlined,
                                color: Color(0xFF74070E),
                                size: 28,
                              ),
                              if (_unreadChatCount > 0)
                                Positioned(
                                  right: -6,
                                  top: -6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      '$_unreadChatCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // First Menu Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.receipt_long_outlined,
                          title: 'Pesanan',
                          trailing: _unreadOrdersCount > 0
                              ? Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OrdersPage(),
                              ),
                            ).then((_) => _fetchNotificationBadges());
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.favorite_border,
                          title: 'Favorit',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FavoritesPage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.access_time,
                          title: 'Terakhir Dilihat',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RecentlyViewedPage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.star_border,
                          title: 'Ulasan Saya',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyReviewsPage(),
                              ),
                            );
                          },
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Second Menu Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.settings_outlined,
                          title: 'Pengaturan',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsPage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.spa_outlined,
                          title: 'Mode Liburan',
                          onTap: () => _toggleVacationMode(),
                          showDivider: false,
                          trailing: Switch(
                            value: _isVacationMode,
                            onChanged: (value) => _toggleVacationMode(),
                            activeColor: Colors.white,
                            activeTrackColor: const Color(0xFF74070E),
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Logout Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: OutlinedButton(
                      onPressed: () {
                        _logout();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.grey, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'Logout',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildMyProductsSection(),
                ],
              ),
            ),
          ),

          // Bottom Navigation
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 347,
                height: 51,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(25.5),
                  border: Border.all(color: const Color(0xFFA2A2A2), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomNavItem(0, Icons.home_outlined, 'Home'),
                    _buildBottomNavItem(1, Icons.shopping_bag_outlined, 'Sell'),
                    _buildBottomNavItem(
                      2,
                      Icons.notifications_none_outlined,
                      'Notification',
                    ),
                    _buildBottomNavItem(3, Icons.person_outline, 'Profile'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right,
                  color: Colors.black54,
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Text(
            'Produk yang Saya Jual',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        if (_myProducts.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(vertical: 32),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  size: 48,
                  color: Colors.black26,
                ),
                const SizedBox(height: 12),
                Text(
                  'Belum ada produk yang Anda jual.',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.black45),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.70,
            ),
            itemCount: _myProducts.length,
            itemBuilder: (context, index) {
              final prod = _myProducts[index];

              String brand = 'Tanpa Brand';
              String size = '';
              final List<dynamic> cats = prod['categories'] is String
                  ? jsonDecode(prod['categories'])
                  : (prod['categories'] ?? []);
              for (var cat in cats) {
                final s = cat.toString();
                if (s.startsWith('Brand:')) {
                  brand = s.replaceAll('Brand:', '').trim();
                }
                if (s.contains('(') && s.contains(')')) {
                  final start = s.indexOf('(');
                  final end = s.indexOf(')');
                  size = s.substring(start + 1, end);
                }
              }

              final List<dynamic> images = prod['image_paths'] is String
                  ? jsonDecode(prod['image_paths'])
                  : (prod['image_paths'] ?? []);
              final String imageUrl = images.isNotEmpty
                  ? '${ApiConfig.host}${images[0]}'
                  : '';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailPage(product: prod),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                          child: Stack(
                            children: [
                              imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: Colors.grey.shade100,
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.black26,
                                                ),
                                              ),
                                    )
                                  : Container(
                                      color: Colors.grey.shade100,
                                      child: const Icon(
                                        Icons.image,
                                        color: Colors.black26,
                                      ),
                                    ),
                              if (size.isNotEmpty)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF74070E),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      size,
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prod['title'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              brand,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.black45,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatPrice(prod['price']),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF74070E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildBottomNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedBottomNavIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HomePage(initialBottomNavIndex: 0),
            ),
          );
        } else if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HomePage(initialBottomNavIndex: 1),
            ),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const NotificationPage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            ),
          );
        }
      },
      child: Container(
        width: 75,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDEDEDE) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: const Color(0xFF74070E), size: 20),
                if (label == 'Notification' && _unreadNotificationsCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: const Color(0xFF74070E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
