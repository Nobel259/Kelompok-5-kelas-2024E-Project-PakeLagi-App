import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/api_config.dart';
import '../../screens/product/product_detail_page.dart';
import '../../widgets/review_list_widget.dart';
import '../../screens/chat/chat_room_page.dart';

class SellerProfilePage extends StatefulWidget {
  final int sellerId;
  final String? sellerName;

  const SellerProfilePage({super.key, required this.sellerId, this.sellerName});

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  Map<String, dynamic>? _sellerData;
  List<dynamic> _products = [];
  List<dynamic> _reviews = [];
  bool _isLoading = true;
  bool _isLoadingReviews = false;
  int _selectedTabIndex = 0; // 0 for Products, 1 for Reviews
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _fetchSellerProfile();
    _fetchReviews();
  }

  Future<void> _getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('user_id');
    });
  }

  String _formatPrice(dynamic price) {
    final p = price is String
        ? int.tryParse(price.replaceAll('.', '')) ?? 0
        : (price is double ? price.toInt() : price as int);
    final str = p.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  Future<void> _fetchSellerProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/${widget.sellerId}/profile'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _sellerData = data['user'];
          _products = data['products'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching seller profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoadingReviews = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/reviews?seller_id=${widget.sellerId}'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _reviews = data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
    } finally {
      setState(() => _isLoadingReviews = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF74070E)),
            )
          : CustomScrollView(
              slivers: [
                // AppBar
                SliverAppBar(
                  expandedHeight: 320,
                  pinned: true,
                  backgroundColor: Colors.white,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF74070E),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    'Profil Penjual',
                    style: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF74070E),
                      fontSize: 18,
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF74070E).withValues(alpha: 0.12),
                            Colors.white,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Column(
                            children: [
                              // Profile Picture
                              GestureDetector(
                                onTap: () {
                                  if (_sellerData?['profile_picture_url'] !=
                                          null &&
                                      _sellerData!['profile_picture_url']
                                          .toString()
                                          .isNotEmpty) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                        backgroundColor: Colors.transparent,
                                        insetPadding: EdgeInsets.zero,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            InteractiveViewer(
                                              child: Image.network(
                                                '${ApiConfig.host}/uploads/profiles/${_sellerData!['profile_picture_url']}',
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                            Positioned(
                                              top: 40,
                                              right: 20,
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: CircleAvatar(
                                  radius: 45,
                                  backgroundColor: const Color(
                                    0xFF74070E,
                                  ).withValues(alpha: 0.1),
                                  backgroundImage:
                                      _sellerData?['profile_picture_url'] !=
                                              null &&
                                          _sellerData!['profile_picture_url']
                                              .toString()
                                              .isNotEmpty
                                      ? NetworkImage(
                                          '${ApiConfig.host}/uploads/profiles/${_sellerData!['profile_picture_url']}',
                                        )
                                      : null,
                                  child:
                                      _sellerData?['profile_picture_url'] ==
                                              null ||
                                          _sellerData!['profile_picture_url']
                                              .toString()
                                              .isEmpty
                                      ? Text(
                                          (_sellerData?['username'] ?? 'U')
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: GoogleFonts.inter(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF74070E),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Username
                              Text(
                                '@${_sellerData?['username'] ?? 'user'}',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Full name
                              Text(
                                _sellerData?['full_name'] ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Bio
                              if (_sellerData?['bio'] != null &&
                                  _sellerData!['bio'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                  ),
                                  child: Text(
                                    _sellerData!['bio'],
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              if (_currentUserId != null &&
                                  _currentUserId != widget.sellerId)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF74070E),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 8,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatRoomPage(
                                          receiverId: widget.sellerId,
                                          receiverName:
                                              _sellerData?['full_name'] ??
                                              widget.sellerName ??
                                              'User',
                                          profilePictureUrl:
                                              _sellerData?['profile_picture_url'],
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 18,
                                  ),
                                  label: Text(
                                    'Chat',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Tabs
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedTabIndex = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedTabIndex == 0
                                      ? const Color(0xFF74070E)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Text(
                                  'Produk (${_products.length})',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedTabIndex == 0
                                        ? Colors.white
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedTabIndex = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedTabIndex == 1
                                      ? const Color(0xFF74070E)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Text(
                                  'Ulasan (${_reviews.length})',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedTabIndex == 1
                                        ? Colors.white
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Vacation Banner
                if (_sellerData?['is_vacation'] == true ||
                    _sellerData?['is_vacation'] == 1)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.beach_access, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Toko ini sedang libur. Produk tidak akan muncul sampai toko kembali aktif.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Content
                if (_selectedTabIndex == 0)
                  _products.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.storefront_outlined,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum ada produk dijual',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.70,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final prod = _products[index];
                              final List<dynamic> images =
                                  prod['image_paths'] is String
                                  ? jsonDecode(prod['image_paths'])
                                  : (prod['image_paths'] ?? []);
                              final String imageUrl = images.isNotEmpty
                                  ? '${ApiConfig.host}${images[0]}'
                                  : '';

                              String brand = '';
                              final List<dynamic> cats =
                                  prod['categories'] is String
                                  ? jsonDecode(prod['categories'])
                                  : (prod['categories'] ?? []);
                              for (var cat in cats) {
                                if (cat.toString().startsWith('Brand:')) {
                                  brand = cat
                                      .toString()
                                      .replaceAll('Brand:', '')
                                      .trim();
                                }
                              }

                              return GestureDetector(
                                onTap: () {
                                  final productWithUser =
                                      Map<String, dynamic>.from(prod);
                                  productWithUser['user'] = _sellerData;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailPage(
                                        product: productWithUser,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.03,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(15),
                                              ),
                                          child: imageUrl.isNotEmpty
                                              ? Image.network(
                                                  imageUrl,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c, e, s) =>
                                                      Container(
                                                        color: Colors
                                                            .grey
                                                            .shade100,
                                                        child: const Center(
                                                          child: Icon(
                                                            Icons.broken_image,
                                                            color:
                                                                Colors.black26,
                                                          ),
                                                        ),
                                                      ),
                                                )
                                              : Container(
                                                  color: Colors.grey.shade100,
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.image,
                                                      color: Colors.black26,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                            if (brand.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                brand,
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: Colors.black45,
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 6),
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
                            }, childCount: _products.length),
                          ),
                        )
                else
                  _isLoadingReviews
                      ? const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF74070E),
                            ),
                          ),
                        )
                      : SliverToBoxAdapter(
                          child: ReviewListWidget(reviews: _reviews),
                        ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }
}
