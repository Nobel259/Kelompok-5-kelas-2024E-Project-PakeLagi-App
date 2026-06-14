import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_config.dart';
import '../../screens/order/checkout_page.dart';
import '../../screens/product/product_detail_page.dart';
import '../../screens/seller/seller_profile_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<dynamic> _cartItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  Future<void> _fetchCartItems() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/cart'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        setState(() {
          _cartItems = resData['data'] ?? [];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memuat keranjang belanja: ${response.statusCode}',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: const Color(0xFF74070E),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error fetching cart items: $e');
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem(int itemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/cart/$itemId'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Barang berhasil dihapus dari keranjang.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xFF74070E),
          ),
        );
        _fetchCartItems();
      } else {
        final resData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resData['message'] ?? 'Gagal menghapus barang.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: const Color(0xFF74070E),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting cart item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Terjadi kesalahan jaringan.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: const Color(0xFF74070E),
        ),
      );
    }
  }

  Future<void> _checkoutSeller(
    int sellerId,
    String sellerName,
    List<dynamic> items,
  ) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPage(
          sellerId: sellerId,
          sellerName: sellerName,
          items: items,
        ),
      ),
    );
  }

  void _showSuccessDialog(String sellerName) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Checkout Success',
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Pembelian Berhasil!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF74070E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pesanan Anda dari penjual "$sellerName" berhasil dibuat dan sedang diproses.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF74070E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Tutup',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

  Map<int, List<dynamic>> _groupItemsBySeller() {
    Map<int, List<dynamic>> grouped = {};
    for (var item in _cartItems) {
      final product = item['product'];
      if (product != null && product['user'] != null) {
        final sellerId = product['user']['id'] as int;
        if (!grouped.containsKey(sellerId)) {
          grouped[sellerId] = [];
        }
        grouped[sellerId]!.add(item);
      }
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupItemsBySeller();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF74070E),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Keranjang Saya',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFF74070E),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF74070E)),
              ),
            )
          : _cartItems.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.only(
                top: 12,
                bottom: 24,
                left: 16,
                right: 16,
              ),
              itemCount: grouped.keys.length,
              itemBuilder: (context, index) {
                final sellerId = grouped.keys.elementAt(index);
                final items = grouped[sellerId]!;
                final seller = items.first['product']['user'];
                final sellerName =
                    seller['username'] ?? seller['full_name'] ?? 'user';
                final profilePic =
                    seller['profile_picture_url'] ?? seller['profile_picture'];
                final profilePicStr = profilePic?.toString() ?? '';
                final profileImageUrl = profilePicStr.isNotEmpty
                    ? (profilePicStr.startsWith('http')
                          ? profilePicStr
                          : '${ApiConfig.host}/uploads/profiles/$profilePicStr')
                    : null;

                final sellerAddress = items.first['product']['address'];
                final sellerCity =
                    (sellerAddress != null &&
                        sellerAddress['city'] != null &&
                        sellerAddress['city'].toString().trim().isNotEmpty)
                    ? sellerAddress['city'].toString().trim()
                    : 'Seller';

                // Compute Subtotal
                int subtotal = 0;
                for (var item in items) {
                  subtotal +=
                      int.tryParse(item['product']['price'].toString()) ?? 0;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Seller Header
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SellerProfilePage(
                                sellerId: seller['id'],
                                sellerName: sellerName,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(
                                  0xFF74070E,
                                ).withOpacity(0.08),
                                backgroundImage: profileImageUrl != null
                                    ? NetworkImage(profileImageUrl)
                                    : null,
                                child: profileImageUrl == null
                                    ? Text(
                                        sellerName
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF74070E),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '@$sellerName',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Row(
                                    children: [
                                      Icon(
                                        sellerCity == 'Seller'
                                            ? Icons.star
                                            : Icons.location_on,
                                        color: sellerCity == 'Seller'
                                            ? Colors.amber
                                            : Colors.grey.shade600,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        sellerCity,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFEEEEEE),
                      ),

                      // Items List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (context, idx) => const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFF1F1F1),
                        ),
                        itemBuilder: (context, idx) {
                          final item = items[idx];
                          final product = item['product'];

                          String brand = 'Tanpa Brand';
                          String size = '-';
                          String condition = '-';

                          final List<dynamic> cats =
                              product['categories'] is String
                              ? jsonDecode(product['categories'])
                              : (product['categories'] ?? []);
                          for (var cat in cats) {
                            final s = cat.toString();
                            if (s.startsWith('Brand:')) {
                              brand = s.replaceAll('Brand:', '').trim();
                            }
                            if (s.startsWith('Condition:') ||
                                s.startsWith('Kondisi:')) {
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

                          final List<dynamic> images =
                              product['image_paths'] is String
                              ? jsonDecode(product['image_paths'])
                              : (product['image_paths'] ?? []);
                          final String imageUrl = images.isNotEmpty
                              ? '${ApiConfig.host}${images[0]}'
                              : '';

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProductDetailPage(product: product),
                                ),
                              ).then((_) => _fetchCartItems());
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: imageUrl.isNotEmpty
                                        ? Image.network(
                                            imageUrl,
                                            width: 76,
                                            height: 76,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    width: 76,
                                                    height: 76,
                                                    color: Colors.grey.shade100,
                                                    child: const Icon(
                                                      Icons
                                                          .broken_image_outlined,
                                                      color: Colors.black26,
                                                      size: 20,
                                                    ),
                                                  );
                                                },
                                          )
                                        : Container(
                                            width: 76,
                                            height: 76,
                                            color: Colors.grey.shade100,
                                            child: const Icon(
                                              Icons.image_outlined,
                                              color: Colors.black26,
                                              size: 20,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Product Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['title'] ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Brand: $brand',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF5F5F5),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Ukuran: $size',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE8F5E9),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                condition,
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  color: Colors.green.shade800,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatPrice(product['price']),
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: const Color(0xFF74070E),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () =>
                                                  _deleteItem(item['id']),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFF74070E,
                                                    ),
                                                    width: 1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'Hapus',
                                                  style: GoogleFonts.inter(
                                                    color: const Color(
                                                      0xFF74070E,
                                                    ),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
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
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFEEEEEE),
                      ),

                      // Seller Footer
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFCFCFC),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () =>
                                  _checkoutSeller(sellerId, sellerName, items),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF74070E),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                elevation: 0,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Lanjut beli',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Subtotal',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.black45,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatPrice(subtotal),
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF74070E).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Color(0xFF74070E),
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Keranjang Anda Kosong',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF74070E),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Belum ada barang di keranjang belanja Anda. Cari barang bekas berkualitas sekarang!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF74070E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              elevation: 0,
            ),
            child: Text(
              'Mulai Belanja',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
