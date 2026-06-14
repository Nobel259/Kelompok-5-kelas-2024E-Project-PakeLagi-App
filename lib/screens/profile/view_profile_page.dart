import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_config.dart';
import '../../screens/profile/notification_page.dart';
import '../../screens/profile/profile_page.dart';
import '../../main.dart';
import '../../screens/product/product_detail_page.dart';
import '../../widgets/review_list_widget.dart';
import '../../screens/seller/sell_page.dart';

class ViewProfilePage extends StatefulWidget {
  const ViewProfilePage({super.key});

  @override
  State<ViewProfilePage> createState() => _ViewProfilePageState();
}

class _ViewProfilePageState extends State<ViewProfilePage>
    with SingleTickerProviderStateMixin {
  final int _selectedBottomNavIndex = 3;
  late TabController _tabController;
  String _fullName = '';
  String _profilePictureUrl = '';
  int _myUserId = 0;
  List<dynamic> _myProducts = [];
  bool _isLoadingProducts = false;
  List<dynamic> _myReviews = [];
  bool _isLoadingReviews = false;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullName = prefs.getString('full_name') ?? 'Pengguna';
      _profilePictureUrl = prefs.getString('profile_picture_url') ?? '';
      _myUserId = prefs.getInt('user_id') ?? 0;
    });
    _fetchMyProducts();
    _fetchMyReviews();
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
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _fetchMyReviews() async {
    if (_myUserId == 0) return;
    setState(() => _isLoadingReviews = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/reviews?seller_id=$_myUserId'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _myReviews = data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching my reviews: $e');
    } finally {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _uploadProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SellPage()),
    ).then((_) => _fetchMyProducts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top Gradient
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

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF74070E),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            _fullName,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // balance
                    ],
                  ),
                ),

                // Tabs
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.black,
                  indicatorWeight: 2,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Toko'),
                    Tab(text: 'Review'),
                  ],
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Toko Tab
                      _buildTokoTab(),
                      // Review Tab
                      _buildReviewTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Nav
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildTokoTab() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        // Empty Product State or Grid
        const SizedBox(height: 24),
        if (_isLoadingProducts)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFF74070E)),
          )
        else if (_myProducts.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 120,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 32),
                Text(
                  'Belum ada produk',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 160,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF74070E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    onPressed: _uploadProduct,
                    child: Text(
                      'Upload',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.70,
            ),
            itemCount: _myProducts.length,
            itemBuilder: (context, index) {
              final prod = _myProducts[index];
              final List<dynamic> images = prod['image_paths'] is String
                  ? jsonDecode(prod['image_paths'])
                  : (prod['image_paths'] ?? []);
              final String imageUrl = images.isNotEmpty
                  ? '${ApiConfig.host}${images[0]}'
                  : '';

              String brand = '';
              final List<dynamic> cats = prod['categories'] is String
                  ? jsonDecode(prod['categories'])
                  : (prod['categories'] ?? []);
              for (var cat in cats) {
                if (cat.toString().startsWith('Brand:')) {
                  brand = cat.toString().replaceAll('Brand:', '').trim();
                }
              }

              final bool isSold =
                  prod['is_sold'] == 1 || prod['is_sold'] == true;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailPage(product: prod),
                    ),
                  ).then((_) => _fetchMyProducts());
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (imageUrl.isNotEmpty)
                                Image.network(imageUrl, fit: BoxFit.cover)
                              else
                                Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.image,
                                    color: Colors.grey,
                                  ),
                                ),
                              if (isSold)
                                Container(
                                  color: Colors.black54,
                                  alignment: Alignment.center,
                                  child: Text(
                                    'TERJUAL',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                            ],
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
      ],
    );
  }

  Widget _buildReviewTab() {
    if (_isLoadingReviews) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF74070E)),
      );
    }

    if (_myReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Belum ada ulasan',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.black45),
            ),
            const SizedBox(height: 80),
          ],
        ),
      );
    }

    return ReviewListWidget(reviews: _myReviews);
  }

  Widget _buildBottomNav() {
    return Positioned(
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
            Icon(icon, color: const Color(0xFF74070E), size: 20),
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
