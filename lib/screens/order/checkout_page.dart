import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/api_config.dart';
import '../../screens/order/orders_page.dart';

class CheckoutPage extends StatefulWidget {
  final int sellerId;
  final String sellerName;
  final List<dynamic> items;
  const CheckoutPage({
    super.key,
    required this.sellerId,
    required this.sellerName,
    required this.items,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _sellerInfo;
  List<dynamic> _sellerBanks = [];

  List<dynamic> _buyerAddresses = [];
  dynamic _selectedAddress;

  @override
  void initState() {
    super.initState();
    _fetchSellerInfo();
    _fetchBuyerAddresses();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchSellerInfo() async {
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
          _sellerInfo = data['user'];
          _sellerBanks = data['user']['bank_accounts'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching seller info: $e');
    }
  }

  Future<void> _fetchBuyerAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/addresses'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _buyerAddresses = data['data'] ?? [];
          if (_buyerAddresses.isNotEmpty) {
            _selectedAddress = _buyerAddresses.firstWhere(
              (addr) => addr['is_default'] == 1 || addr['is_default'] == true,
              orElse: () => _buyerAddresses.first,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching addresses: $e');
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

  int get _subtotal {
    int total = 0;
    for (var item in widget.items) {
      final product = item['product'];
      if (product != null) total += (product['price'] as num).toInt();
    }
    return total;
  }

  Future<void> _checkout() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih alamat pengiriman terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final String fullAddress =
          '${_selectedAddress['full_address']}, ${_selectedAddress['city']}';

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/cart/checkout'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'seller_id': widget.sellerId,
          'buyer_name': _selectedAddress['recipient_name'],
          'buyer_address': fullAddress,
          'buyer_phone': _selectedAddress['phone_number'],
          'buyer_notes': _notesController.text,
        }),
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Color(0xFF2E7D32),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pesanan Berhasil!',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF74070E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Silakan transfer ke rekening penjual dan upload bukti pembayaran.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF74070E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrdersPage(),
                        ),
                      );
                    },
                    child: Text(
                      'Lihat Pesanan',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Checkout gagal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Koneksi bermasalah: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF74070E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Checkout',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF74070E),
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Seller bank info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFCC02).withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance,
                        color: Color(0xFF74070E),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rekening Penjual',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF74070E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_sellerBanks.isNotEmpty) ...[
                    ..._sellerBanks.map(
                      (bank) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _bankInfoRow('Bank', bank['bank_name'] ?? '-'),
                            _bankInfoRow(
                              'No. Rekening',
                              bank['account_number'] ?? '-',
                            ),
                            _bankInfoRow(
                              'Atas Nama',
                              bank['account_name'] ?? '-',
                            ),
                            if (_sellerBanks.last != bank)
                              const Divider(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ] else if (_sellerInfo != null &&
                      _sellerInfo!['bank_name'] != null &&
                      (_sellerInfo!['bank_name'] as String).isNotEmpty) ...[
                    _bankInfoRow('Bank', _sellerInfo!['bank_name'] ?? '-'),
                    _bankInfoRow(
                      'No. Rekening',
                      _sellerInfo!['bank_account_number'] ?? '-',
                    ),
                    _bankInfoRow(
                      'Atas Nama',
                      _sellerInfo!['bank_account_name'] ?? '-',
                    ),
                  ] else
                    Text(
                      'Penjual belum mengatur rekening bank.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Buyer Address info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alamat Pengiriman',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_buyerAddresses.isEmpty)
                    Text(
                      'Anda belum memiliki alamat pengiriman. Silakan tambahkan alamat di menu Pengaturan.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.red.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    DropdownButtonFormField<dynamic>(
                      value: _selectedAddress,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF74070E),
                          ),
                        ),
                      ),
                      items: _buyerAddresses.map((addr) {
                        return DropdownMenuItem<dynamic>(
                          value: addr,
                          child: Text(
                            '${addr['label']} - ${addr['recipient_name']} (${addr['city']})',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedAddress = val);
                      },
                    ),
                  if (_selectedAddress != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _selectedAddress['recipient_name'] ?? '',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedAddress['phone_number'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedAddress['full_address']}, ${_selectedAddress['city']}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildField(
                    'Catatan (opsional)',
                    _notesController,
                    'Catatan untuk penjual',
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Items
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Produk dari ${widget.sellerName}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.items.map((item) {
                    final product = item['product'];
                    if (product == null) return const SizedBox.shrink();
                    final List<dynamic> images =
                        product['image_paths'] is String
                        ? jsonDecode(product['image_paths'])
                        : (product['image_paths'] ?? []);
                    final imageUrl = images.isNotEmpty
                        ? '${ApiConfig.host}${images[0]}'
                        : '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      width: 56,
                                      height: 56,
                                      color: Colors.grey.shade100,
                                      child: const Icon(
                                        Icons.image,
                                        size: 20,
                                        color: Colors.black26,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 56,
                                    height: 56,
                                    color: Colors.grey.shade100,
                                    child: const Icon(
                                      Icons.image,
                                      size: 20,
                                      color: Colors.black26,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              product['title'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            _formatPrice(product['price']),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF74070E),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatPrice(_subtotal),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF74070E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Checkout button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF74070E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 2,
                ),
                onPressed: _isLoading || _buyerAddresses.isEmpty
                    ? null
                    : _checkout,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Bayar & Pesan',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _bankInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.black38),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF74070E)),
            ),
          ),
        ),
      ],
    );
  }
}
