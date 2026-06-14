import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/api_config.dart';
import '../../screens/product/product_detail_page.dart';

class RecentlyViewedPage extends StatefulWidget {
  const RecentlyViewedPage({super.key});

  @override
  State<RecentlyViewedPage> createState() => _RecentlyViewedPageState();
}

class _RecentlyViewedPageState extends State<RecentlyViewedPage> {
  List<dynamic> _recentProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentlyViewed();
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

  Future<void> _loadRecentlyViewed() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('recently_viewed_products') ?? '[]';
      final List<dynamic> list = jsonDecode(raw);
      setState(() {
        _recentProducts = list;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading recently viewed: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Hapus Semua',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Hapus semua riwayat produk yang terakhir dilihat?',
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('recently_viewed_products', '[]');
    setState(() => _recentProducts = []);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Riwayat dihapus', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFF74070E),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF74070E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Terakhir Dilihat',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF74070E),
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_recentProducts.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: Text(
                'Hapus Semua',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF74070E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF74070E)),
            )
          : _recentProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF74070E).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.history,
                      size: 40,
                      color: Color(0xFF74070E),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Belum ada produk yang dilihat',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Produk yang Anda lihat akan\nmuncul di sini.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF74070E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Mulai Jelajahi',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.70,
              ),
              itemCount: _recentProducts.length,
              itemBuilder: (context, index) {
                final prod = _recentProducts[index];
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

                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailPage(product: prod),
                      ),
                    );
                    _loadRecentlyViewed(); // Refresh
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
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
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      color: Colors.grey.shade100,
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.black26,
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
              },
            ),
    );
  }
}
