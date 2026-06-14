import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_config.dart';
import '../../screens/main/cart_page.dart';
import '../../screens/review/review_page.dart';
import '../../screens/seller/seller_profile_page.dart';
import '../../screens/chat/chat_room_page.dart';
import '../../screens/main/search_page.dart';

class ProductDetailPage extends StatefulWidget {
  final dynamic product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  List<dynamic> _reviews = [];
  bool _isLoadingReviews = false;
  bool _isAddingToCart = false;
  int _currentImageIndex = 0;
  bool _isFavorited = false;
  int _currentUserId = 0;

  @override
  void initState() {
    super.initState();
    _fetchSellerReviews();
    _loadUserAndCheckFavorite();
    _saveToRecentlyViewed();
  }

  Future<void> _loadUserAndCheckFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('user_id') ?? 0;
    setState(() {});
    // Check favorite status
    try {
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/favorites/check?product_id=${widget.product['id']}',
        ),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _isFavorited = data['is_favorited'] == true);
      }
    } catch (e) {
      debugPrint('Error checking favorite: $e');
    }
  }

  Future<void> _toggleFavorite() async {
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
        body: jsonEncode({'product_id': widget.product['id']}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() => _isFavorited = data['is_favorited'] == true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? '', style: GoogleFonts.inter()),
              backgroundColor: const Color(0xFF74070E),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  Future<void> _deleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Hapus Produk',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus produk ini?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(color: Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Hapus',
              style: GoogleFonts.inter(
                color: const Color(0xFF74070E),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/products/${widget.product['id']}'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Produk berhasil dihapus',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: const Color(0xFF74070E),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate deletion
      }
    } catch (e) {
      debugPrint('Error deleting product: $e');
    }
  }

  Future<void> _saveToRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('recently_viewed_products') ?? '[]';
      final List<dynamic> list = jsonDecode(raw);
      // Remove duplicate
      list.removeWhere((item) => item['id'] == widget.product['id']);
      // Add to front
      list.insert(0, widget.product);
      // Limit to 20
      if (list.length > 20) list.removeRange(20, list.length);
      await prefs.setString('recently_viewed_products', jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving recently viewed: $e');
    }
  }

  Future<void> _fetchSellerReviews() async {
    final seller = widget.product['user'] ?? {};
    final sellerId = seller['id'];
    if (sellerId == null) return;

    setState(() => _isLoadingReviews = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/reviews?seller_id=$sellerId'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        setState(() {
          _reviews = resData['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
    } finally {
      setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _addToCart() async {
    setState(() => _isAddingToCart = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/cart'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'product_id': widget.product['id']}),
      );

      final resData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Barang berhasil ditambahkan ke keranjang.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xFF74070E),
            action: SnackBarAction(
              label: 'LIHAT',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resData['message'] ?? 'Gagal menambahkan barang ke keranjang.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: const Color(0xFF74070E),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Terjadi kesalahan jaringan.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: const Color(0xFF74070E),
        ),
      );
    } finally {
      setState(() => _isAddingToCart = false);
    }
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
    return 'Rp${buffer.toString()}';
  }

  Widget _buildStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 14,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isSold =
        product['is_sold'] == true ||
        product['is_sold'] == 1 ||
        product['is_sold'] == '1';

    String brand = 'Tanpa Brand';
    String size = '-';
    String condition = '-';

    final List<dynamic> cats = product['categories'] is String
        ? jsonDecode(product['categories'])
        : (product['categories'] ?? []);
    for (var cat in cats) {
      final s = cat.toString();
      if (s.startsWith('Brand:')) {
        brand = s.replaceAll('Brand:', '').trim();
      }
      if (s.startsWith('Condition:') || s.startsWith('Kondisi:')) {
        condition = s
            .replaceAll('Condition:', '')
            .replaceAll('Kondisi:', '')
            .trim();
      }
      if (s.contains('(') && s.contains(')')) {
        final start = s.indexOf('(');
        final end = s.indexOf(')');
        size = s.substring(start + 1, end);
      }
    }

    final List<dynamic> images = product['image_paths'] is String
        ? jsonDecode(product['image_paths'])
        : (product['image_paths'] ?? []);

    final seller = product['user'] ?? {};
    // REQUIREMENT: username displayed instead of full name
    final sellerName = seller['username'] ?? seller['name'] ?? 'penjual';
    final sellerAddress = product['address'] != null
        ? '${product['address']['city'] ?? ''}'
        : 'Lokasi tidak tersedia';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Gradient Background at the top header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF74070E).withOpacity(0.2),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Main product scroll
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: kToolbarHeight),

                      // Image Carousel
                      if (images.isNotEmpty)
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            SizedBox(
                              height: 380,
                              child: PageView.builder(
                                itemCount: images.length,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentImageIndex = index;
                                  });
                                },
                                itemBuilder: (context, idx) {
                                  final imgUrl =
                                      '${ApiConfig.host}${images[idx]}';
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              _FullScreenImageViewer(
                                                images: images,
                                                initialIndex: idx,
                                              ),
                                        ),
                                      );
                                    },
                                    child: Image.network(
                                      imgUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey.shade100,
                                              child: const Icon(
                                                Icons.broken_image_outlined,
                                                color: Colors.black26,
                                                size: 64,
                                              ),
                                            );
                                          },
                                    ),
                                  );
                                },
                              ),
                            ),
                            // 1/5 page indicator (Mockup style)
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_currentImageIndex + 1}/${images.length}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          height: 300,
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: Colors.black26,
                              size: 64,
                            ),
                          ),
                        ),

                      // "Terjual" Banner if sold
                      if (isSold)
                        Container(
                          width: double.infinity,
                          color: const Color(0xFF74070E),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          child: Text(
                            'Terjual',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title & Favorites Icon
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    product['title'] ?? '',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _toggleFavorite,
                                  child: Icon(
                                    _isFavorited
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: _isFavorited
                                        ? Colors.red
                                        : Colors.black54,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Specs: Ukuran, Kondisi, Brand (Faded text)
                            Text(
                              'Ukuran: $size',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kondisi: $condition',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Brand: $brand',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Price
                            Text(
                              _formatPrice(product['price']),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Divider
                            Container(height: 1, color: Colors.grey.shade200),
                            const SizedBox(height: 16),

                            // Detail Header & Description
                            Text(
                              'Detail',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              product['description'] ?? 'Tidak ada deskripsi.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Divider
                            Container(height: 1, color: Colors.grey.shade200),
                            const SizedBox(height: 16),

                            // Seller Profile Row (Clickable)
                            GestureDetector(
                              onTap: () {
                                final sellId = seller['id'];
                                if (sellId != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SellerProfilePage(
                                        sellerId: sellId,
                                        sellerName: sellerName,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: const Color(
                                      0xFF74070E,
                                    ).withOpacity(0.08),
                                    backgroundImage:
                                        (seller['profile_picture_url'] ??
                                                seller['profile_picture']) !=
                                            null
                                        ? NetworkImage(
                                            '${ApiConfig.host}/uploads/profiles/${seller['profile_picture_url'] ?? seller['profile_picture']}',
                                          )
                                        : null,
                                    child:
                                        (seller['profile_picture_url'] ??
                                                seller['profile_picture']) ==
                                            null
                                        ? Text(
                                            sellerName
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFF74070E),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sellerName,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          sellerAddress,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            _buildStars(5),
                                            const SizedBox(width: 4),
                                            Text(
                                              '(${_reviews.length})',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: Colors.black45,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.black38,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Divider
                            Container(height: 1, color: Colors.grey.shade200),
                            const SizedBox(height: 16),

                            // Review Header (Clickable)
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReviewPage(
                                      seller: seller,
                                      reviews: _reviews,
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Review',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Horizontal Review List
                            _isLoadingReviews
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation(
                                          Color(0xFF74070E),
                                        ),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : _reviews.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: Text(
                                      'Belum ada ulasan untuk toko ini.',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.black38,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  )
                                : SizedBox(
                                    height: 130,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: _reviews.length,
                                      itemBuilder: (context, index) {
                                        final review = _reviews[index];
                                        final reviewer =
                                            review['reviewer'] ?? {};
                                        final reviewerName =
                                            reviewer['full_name'] ??
                                            reviewer['username'] ??
                                            'User';

                                        return Container(
                                          width: 240,
                                          margin: const EdgeInsets.only(
                                            right: 12,
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  _buildStars(
                                                    review['rating'] ?? 5,
                                                  ),
                                                  Text(
                                                    '10 hari lalu',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 9,
                                                      color: Colors.black38,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Expanded(
                                                child: Text(
                                                  review['comment'] ?? '',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: Colors.black87,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 10,
                                                    backgroundColor:
                                                        const Color(
                                                          0xFF74070E,
                                                        ).withOpacity(0.08),
                                                    backgroundImage:
                                                        reviewer['profile_picture'] !=
                                                            null
                                                        ? NetworkImage(
                                                            '${ApiConfig.host}/uploads/profiles/${reviewer['profile_picture']}',
                                                          )
                                                        : null,
                                                    child:
                                                        reviewer['profile_picture'] ==
                                                            null
                                                        ? Text(
                                                            reviewerName
                                                                .substring(0, 1)
                                                                .toUpperCase(),
                                                            style: GoogleFonts.inter(
                                                              color:
                                                                  const Color(
                                                                    0xFF74070E,
                                                                  ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 7,
                                                            ),
                                                          )
                                                        : null,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    reviewerName,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 10,
                                                      color: Colors.black54,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Navigation Action Bar (Only shown if NOT sold)
              if (!isSold)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, -4),
                      ),
                    ],
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade100),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        // Chat Button
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton(
                              onPressed: () {
                                final seller = widget.product['user'];
                                if (seller != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatRoomPage(
                                        receiverId: seller['id'],
                                        receiverName:
                                            seller['username'] ??
                                            seller['full_name'] ??
                                            'Penjual',
                                        profilePictureUrl:
                                            seller['profile_picture_url'],
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF74070E),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Chat',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF74070E),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Beli Button
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _isAddingToCart ? null : _addToCart,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF74070E),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isAddingToCart
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Beli',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Custom AppBar Overlay (Burgundy theme buttons)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF74070E),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Row(
                      children: [
                        if (widget.product['user_id'] == _currentUserId &&
                            _currentUserId != 0)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFF74070E),
                            ),
                            onPressed: _deleteProduct,
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.search,
                            color: Color(0xFF74070E),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SearchPage(),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.shopping_basket_outlined,
                            color: Color(0xFF74070E),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CartPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final List<dynamic> images;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: PageView.builder(
        itemCount: images.length,
        controller: PageController(initialPage: initialIndex),
        itemBuilder: (context, index) {
          final imgUrl = '${ApiConfig.host}${images[index]}';
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(child: Image.network(imgUrl, fit: BoxFit.contain)),
          );
        },
      ),
    );
  }
}
