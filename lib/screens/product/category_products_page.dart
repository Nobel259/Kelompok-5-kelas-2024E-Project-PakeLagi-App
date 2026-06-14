import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/api_config.dart';
import '../../screens/product/product_detail_page.dart';

class CategoryProductsPage extends StatefulWidget {
  final String gender;
  final String category;
  const CategoryProductsPage({
    super.key,
    required this.gender,
    required this.category,
  });

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  List<dynamic> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
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
          _products = allProducts.where((prod) {
            final List<dynamic> cats = prod['categories'] is String
                ? jsonDecode(prod['categories'])
                : (prod['categories'] ?? []);
            return cats.any((c) {
              final s = c.toString().toLowerCase();
              return s.contains(widget.gender.toLowerCase()) &&
                  s.contains(widget.category.toLowerCase());
            });
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatPrice(dynamic price) {
    final str = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final genderLabel = widget.gender == 'wanita'
        ? 'Wanita'
        : widget.gender == 'pria'
        ? 'Pria'
        : 'Anak';
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF972B31),
                  const Color(0xFFEB8C8C).withValues(alpha: 0.07),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
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
                      child: Column(
                        children: [
                          Text(
                            widget.category,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF74070E),
                            ),
                          ),
                          Text(
                            genderLabel,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(
                                0xFF74070E,
                              ).withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF74070E),
                      ),
                    ),
                  )
                : _products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          color: const Color(0xFF74070E).withValues(alpha: 0.3),
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada produk untuk kategori ini.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: const Color(0xFF74070E),
                    onRefresh: _fetchProducts,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final prod = _products[index];
                        final List<dynamic> cats = prod['categories'] is String
                            ? jsonDecode(prod['categories'])
                            : (prod['categories'] ?? []);
                        String brand = 'Tanpa Brand';
                        String size = '';
                        for (var cat in cats) {
                          final s = cat.toString();
                          if (s.startsWith('Brand:'))
                            brand = s.replaceAll('Brand:', '').trim();
                          if (s.contains('(') && s.contains(')')) {
                            size = s.substring(
                              s.indexOf('(') + 1,
                              s.indexOf(')'),
                            );
                          }
                        }
                        final List<dynamic> images =
                            prod['image_paths'] is String
                            ? jsonDecode(prod['image_paths'])
                            : (prod['image_paths'] ?? []);
                        final imageUrl = images.isNotEmpty
                            ? '${ApiConfig.host}${images[0]}'
                            : '';

                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailPage(product: prod),
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(color: Colors.grey.shade200),
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
                                              height: 140,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) =>
                                                  Container(
                                                    height: 140,
                                                    color: Colors.grey.shade100,
                                                    child: const Icon(
                                                      Icons
                                                          .broken_image_outlined,
                                                      color: Colors.black26,
                                                      size: 28,
                                                    ),
                                                  ),
                                            )
                                          : Container(
                                              height: 140,
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
                                              borderRadius:
                                                  BorderRadius.circular(6),
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
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
          ),
        ],
      ),
    );
  }
}
