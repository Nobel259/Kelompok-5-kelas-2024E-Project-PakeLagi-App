import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'core/api_config.dart';
import 'screens/auth/landing_page.dart';
import 'screens/main/search_page.dart';
import 'screens/profile/notification_page.dart';
import 'screens/profile/profile_page.dart';
import 'screens/seller/sell_page.dart';
import 'screens/chat/chat_list_page.dart';
import 'screens/main/cart_page.dart';
import 'screens/product/product_detail_page.dart';
import 'screens/product/category_products_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getHome() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null && token.isNotEmpty) {
      return const HomePage();
    }
    return const LandingPage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pake Lagi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      home: FutureBuilder<Widget>(
        future: _getHome(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF74070E)),
                ),
              ),
            );
          }
          return snapshot.data ?? const LandingPage();
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final int initialBottomNavIndex;

  const HomePage({super.key, this.initialBottomNavIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['WANITA', 'PRIA', 'ANAK'];
  late int _selectedBottomNavIndex;

  List<dynamic> _products = [];
  bool _isLoadingProducts = false;
  Set<int> _favoriteIds = {};
  int _unreadChatCount = 0;
  int _unreadNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    _selectedBottomNavIndex = widget.initialBottomNavIndex;
    _fetchProducts();
    _fetchFavoriteIds();
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

  List<String> _getCategoriesForGender() {
    if (_tabs[_selectedTabIndex] == 'PRIA') {
      return ['Bottoms', 'Tops', 'Footwear', 'Outerwear'];
    }
    return ['Bottoms', 'Tops', 'Dresses', 'Footwear', 'Outerwear'];
  }

  Future<void> _fetchProducts() async {
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
        setState(() {
          _products = data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    } finally {
      setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _fetchFavoriteIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/favorites'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> favs = data['data'] ?? [];
        setState(() {
          _favoriteIds = favs.map<int>((f) => f['product_id'] as int).toSet();
        });
      }
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
    }
  }

  Future<void> _toggleFavHome(int productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/favorites'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'product_id': productId}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data['is_favorited'] == true) {
            _favoriteIds.add(productId);
          } else {
            _favoriteIds.remove(productId);
          }
        });
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Content
          _selectedBottomNavIndex == 0
              ? Column(
                  children: [
                    // Top Section with Gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF972B31),
                            const Color(0xFFEB8C8C).withOpacity(0.07),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Column(
                          children: [
                            // Search Bar & Cart
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFFFF),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFFDEDEDE),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 12),
                                          Icon(
                                            Icons.search,
                                            color: const Color(
                                              0xFF972B31,
                                            ).withOpacity(0.80),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextField(
                                              readOnly: true,
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  PageRouteBuilder(
                                                    pageBuilder:
                                                        (
                                                          context,
                                                          animation,
                                                          secondaryAnimation,
                                                        ) => const SearchPage(),
                                                    transitionsBuilder:
                                                        (
                                                          context,
                                                          animation,
                                                          secondaryAnimation,
                                                          child,
                                                        ) {
                                                          return FadeTransition(
                                                            opacity: animation,
                                                            child: child,
                                                          );
                                                        },
                                                  ),
                                                );
                                              },
                                              decoration: InputDecoration(
                                                hintText: 'Apa yang Anda cari?',
                                                hintStyle: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 14,
                                                  color: const Color(
                                                    0xFF972B31,
                                                  ).withOpacity(0.80),
                                                ),
                                                border: InputBorder.none,
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                    ),
                                              ),
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w400,
                                                fontSize: 14,
                                                color: const Color(
                                                  0xFF972B31,
                                                ).withOpacity(0.80),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CartPage(),
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
                                          builder: (context) =>
                                              const ChatListPage(),
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

                            // Tabs
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(_tabs.length, (index) {
                                  final isSelected = _selectedTabIndex == index;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedTabIndex = index;
                                      });
                                    },
                                    child: Column(
                                      children: [
                                        Text(
                                          _tabs[index],
                                          style: GoogleFonts.playfairDisplay(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: const Color(0xFF74070E),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          height: 1,
                                          width: 50,
                                          color: isSelected
                                              ? const Color(0xFF74070E)
                                              : Colors.transparent,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),

                    // Categories (White background)
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        child: RefreshIndicator(
                          color: const Color(0xFF74070E),
                          onRefresh: () async {
                            await Future.wait([
                              _fetchProducts(),
                              _fetchFavoriteIds(),
                              _fetchUnreadCount(),
                            ]);
                          },
                          child: ListView(
                            padding: const EdgeInsets.only(bottom: 80, top: 8),
                            children: [
                              ..._getCategoriesForGender().map(
                                (cat) => _buildCategoryRow(cat),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : const SellPage(),

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

  Widget _buildCategoryRow(String title) {
    final currentGender = _tabs[_selectedTabIndex].toLowerCase();

    final filteredProducts = _products.where((prod) {
      final List<dynamic> cats = prod['categories'] is String
          ? jsonDecode(prod['categories'])
          : (prod['categories'] ?? []);

      return cats.any((c) {
        final s = c.toString().toLowerCase();
        return s.contains(currentGender) && s.contains(title.toLowerCase());
      });
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryProductsPage(
                        gender: _tabs[_selectedTabIndex].toLowerCase(),
                        category: title,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF74070E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Color(0xFF74070E),
                    ),
                  ],
                ),
              ),
              if (filteredProducts.isNotEmpty)
                Text(
                  '${filteredProducts.length} Barang',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        if (filteredProducts.isEmpty)
          Container(
            height: 100,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF74070E).withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    color: const Color(0xFF74070E).withOpacity(0.3),
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Belum ada produk untuk kategori ini.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final prod = filteredProducts[index];

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
                    width: 140,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(11),
                          ),
                          child: Stack(
                            children: [
                              imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      height: 110,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              height: 110,
                                              color: Colors.grey.shade100,
                                              child: const Icon(
                                                Icons.broken_image_outlined,
                                                color: Colors.black26,
                                                size: 28,
                                              ),
                                            );
                                          },
                                    )
                                  : Container(
                                      height: 110,
                                      color: Colors.grey.shade100,
                                      child: const Icon(
                                        Icons.image_outlined,
                                        color: Colors.black26,
                                        size: 28,
                                      ),
                                    ),
                              if (size.isNotEmpty)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF74070E),
                                      borderRadius: BorderRadius.circular(6),
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
                        // Favorite Heart Button
                        Positioned(
                          bottom: 46,
                          right: 6,
                          child: GestureDetector(
                            onTap: () => _toggleFavHome(prod['id']),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _favoriteIds.contains(prod['id'])
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _favoriteIds.contains(prod['id'])
                                    ? Colors.red
                                    : Colors.black38,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prod['title'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
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
                                  fontSize: 10,
                                  color: Colors.black45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatPrice(prod['price']),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
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
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBottomNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedBottomNavIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 2) {
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
          ).then((result) {
            _fetchNotificationBadges();
            _fetchUnreadCount();
            if (result != null && result is int) {
              setState(() {
                _selectedBottomNavIndex = result;
              });
            }
          });
        } else if (index == 3) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const ProfilePage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            ),
          ).then((result) {
            _fetchNotificationBadges();
            _fetchUnreadCount();
            if (result != null && result is int) {
              setState(() {
                _selectedBottomNavIndex = result;
              });
            }
          });
        } else {
          setState(() {
            _selectedBottomNavIndex = index;
          });
          if (index == 0) {
            _fetchProducts();
          }
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
                fontWeight: FontWeight.w500,
                color: const Color(0xFF74070E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
