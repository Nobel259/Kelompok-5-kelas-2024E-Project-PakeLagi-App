import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../core/api_config.dart';
import '../../screens/review/write_review_page.dart';

class OrderDetailPage extends StatefulWidget {
  final dynamic order;
  final bool isSeller;
  const OrderDetailPage({
    super.key,
    required this.order,
    required this.isSeller,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late Map<String, dynamic> _order;
  bool _isLoading = false;
  bool _hasReviewed = false;
  final _shippingController = TextEditingController();
  final _shippingCourierController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.order);
    _shippingController.text = _order['shipping_code'] ?? '';
    _shippingCourierController.text = _order['shipping_courier'] ?? '';
    _checkIfReviewed();
  }

  Future<void> _checkIfReviewed() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _hasReviewed = prefs.getBool('reviewed_order_${_order['id']}') ?? false;
      });
    }
  }

  @override
  void dispose() {
    _shippingController.dispose();
    _shippingCourierController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _refreshOrder() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/orders/${_order['id']}'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _order = Map<String, dynamic>.from(data['data']);
          _shippingController.text = _order['shipping_code'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error refreshing order: $e');
    }
  }

  Future<void> _uploadPayment() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/orders/${_order['id']}/payment'),
      );
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.files.add(
        await http.MultipartFile.fromPath('payment_proof', picked.path),
      );
      final response = await request.send();
      if (response.statusCode == 200) {
        await _refreshOrder();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bukti pembayaran berhasil diunggah'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengunggah bukti pembayaran'),
              backgroundColor: Colors.red,
            ),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmPayment() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/orders/${_order['id']}/confirm'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        await _refreshOrder();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran dikonfirmasi'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateShipping() async {
    if (_shippingController.text.isEmpty ||
        _shippingCourierController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan layanan ekspedisi dan kode resi'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/orders/${_order['id']}/shipping'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'shipping_code': _shippingController.text,
          'shipping_courier': _shippingCourierController.text,
        }),
      );
      if (response.statusCode == 200) {
        await _refreshOrder();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kode resi berhasil diperbarui'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Konfirmasi',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF74070E),
          ),
        ),
        content: Text(
          'Apakah Anda sudah menerima pesanan ini?',
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF74070E),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Ya, Sudah Diterima',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/orders/${_order['id']}/complete'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        await _refreshOrder();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pesanan selesai!'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Batalkan Pesanan',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin membatalkan pesanan ini?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Tidak',
              style: GoogleFonts.inter(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Ya, Batalkan',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/orders/${_order['id']}/cancel'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        await _refreshOrder();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pesanan dibatalkan'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal membatalkan pesanan'),
              backgroundColor: Colors.red,
            ),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending_payment':
        return 'Menunggu Pembayaran';
      case 'payment_uploaded':
        return 'Bukti Diunggah';
      case 'payment_confirmed':
        return 'Dikonfirmasi';
      case 'shipped':
        return 'Dikirim';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending_payment':
        return Colors.orange;
      case 'payment_uploaded':
        return Colors.blue;
      case 'payment_confirmed':
        return Colors.teal;
      case 'shipped':
        return Colors.indigo;
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  int _statusIndex(String status) {
    const statuses = [
      'pending_payment',
      'payment_uploaded',
      'payment_confirmed',
      'shipped',
      'completed',
    ];
    final idx = statuses.indexOf(status);
    return idx >= 0 ? idx : 0;
  }

  void _showStepDetails(int step, int currentStep) {
    if (step > currentStep) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proses ini belum selesai'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    String title = '';
    Widget content = const SizedBox();

    switch (step) {
      case 0:
        title = 'Menunggu Pembayaran';
        content = Text(
          'Pesanan telah dibuat dan menunggu pembayaran dari pembeli.',
          style: GoogleFonts.inter(),
        );
        break;
      case 1:
        title = 'Bukti Diunggah';
        if (_order['payment_proof'] != null &&
            (_order['payment_proof'] as String).isNotEmpty) {
          content = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bukti pembayaran telah diunggah:',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  '${ApiConfig.host}${_order['payment_proof']}',
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => Container(
                    height: 120,
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.black26),
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          content = Text(
            'Bukti pembayaran belum tersedia.',
            style: GoogleFonts.inter(),
          );
        }
        break;
      case 2:
        title = 'Pembayaran Dikonfirmasi';
        content = Text(
          'Pembayaran telah dikonfirmasi oleh penjual.',
          style: GoogleFonts.inter(),
        );
        break;
      case 3:
        title = 'Dikirim';
        if (_order['shipping_code'] != null &&
            (_order['shipping_code'] as String).isNotEmpty) {
          content = Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_order['shipping_courier'] != null &&
                    (_order['shipping_courier'] as String).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Layanan: ${_order['shipping_courier']}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                Text(
                  'Resi: ${_order['shipping_code']}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          );
        } else {
          content = Text(
            'Informasi pengiriman belum tersedia.',
            style: GoogleFonts.inter(),
          );
        }
        break;
      case 4:
        title = 'Selesai';
        content = Text(
          'Pesanan telah selesai dan diterima.',
          style: GoogleFonts.inter(),
        );
        break;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF74070E),
          ),
        ),
        content: content,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Tutup',
              style: GoogleFonts.inter(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = _order['product'];
    final status = _order['status'] ?? 'pending_payment';
    final currentStep = _statusIndex(status);

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
          'Detail Pesanan',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF74070E),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF74070E)),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Status stepper
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
                        'Status Pesanan',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusLabel(status),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _statusColor(status),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStepper(currentStep),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Product info
                if (product != null)
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
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _productImage(product, 64, 64),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['title'] ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatPrice(_order['price']),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
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
                const SizedBox(height: 12),

                // Buyer info
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
                        'Informasi Penerima',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        Icons.person_outline,
                        'Nama',
                        _order['buyer_name'] ?? '-',
                      ),
                      _infoRow(
                        Icons.location_on_outlined,
                        'Alamat',
                        _order['buyer_address'] ?? '-',
                      ),
                      _infoRow(
                        Icons.phone_outlined,
                        'No. HP',
                        _order['buyer_phone'] ?? '-',
                      ),
                      if (_order['buyer_notes'] != null &&
                          (_order['buyer_notes'] as String).isNotEmpty)
                        _infoRow(
                          Icons.notes_outlined,
                          'Catatan',
                          _order['buyer_notes'],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Payment proof section
                if (_order['payment_proof'] != null &&
                    (_order['payment_proof'] as String).isNotEmpty)
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
                          'Bukti Pembayaran',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            '${ApiConfig.host}${_order['payment_proof']}',
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => Container(
                              height: 120,
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.black26,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Shipping code display (visible to both buyer and seller)
                if (_order['shipping_code'] != null &&
                    (_order['shipping_code'] as String).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
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
                            'Informasi Pengiriman',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_order['shipping_courier'] != null &&
                                    (_order['shipping_courier'] as String)
                                        .isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      'Layanan: ${_order['shipping_courier']}',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                Text(
                                  'Resi: ${_order['shipping_code']}',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Actions
                ..._buildActions(status),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  List<Widget> _buildActions(String status) {
    final actions = <Widget>[];

    // Cancel order (both buyer & seller if pending_payment)
    if (status == 'pending_payment') {
      actions.add(
        _actionButton(
          'Batalkan Pesanan',
          Icons.cancel_outlined,
          Colors.red,
          _cancelOrder,
        ),
      );
      actions.add(const SizedBox(height: 12));
    }

    // Buyer: upload payment
    if (!widget.isSeller && status == 'pending_payment') {
      actions.add(
        _actionButton(
          'Upload Bukti Transfer',
          Icons.upload_file,
          const Color(0xFF74070E),
          _uploadPayment,
        ),
      );
    }

    // Seller: confirm payment
    if (widget.isSeller && status == 'payment_uploaded') {
      actions.add(
        _actionButton(
          'Konfirmasi Pembayaran',
          Icons.check_circle_outline,
          const Color(0xFF2E7D32),
          _confirmPayment,
        ),
      );
    }

    // Seller: input shipping
    if (widget.isSeller &&
        (status == 'payment_confirmed' || status == 'shipped')) {
      actions.add(
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
                'Informasi Pengiriman',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _shippingCourierController,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Layanan Ekspedisi (JNE/JNT/dll)',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.black38,
                  ),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _shippingController,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Masukkan kode resi',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.black38,
                  ),
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _updateShipping,
                  icon: const Icon(Icons.local_shipping_outlined, size: 20),
                  label: Text(
                    'Kirim Pesanan',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Buyer: complete order
    if (!widget.isSeller && status == 'shipped') {
      actions.add(
        _actionButton(
          'Pesanan Diterima',
          Icons.done_all,
          const Color(0xFF2E7D32),
          _completeOrder,
        ),
      );
    }

    // Buyer: give review
    if (!widget.isSeller && status == 'completed') {
      if (_hasReviewed) {
        actions.add(
          _actionButton(
            'Ulasan Sudah Diberikan',
            Icons.check_circle,
            Colors.grey,
            () {},
          ),
        );
      } else {
        actions.add(
          _actionButton(
            'Beri Ulasan',
            Icons.star_rate_rounded,
            Colors.amber.shade700,
            () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WriteReviewPage(
                    orderId: widget.order['id'],
                    product: widget.order['product'],
                  ),
                ),
              );
              if (result == true) {
                _checkIfReviewed();
                _refreshOrder();
              }
            },
          ),
        );
      }
    }

    return actions;
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildStepper(int currentStep) {
    const steps = [
      'Menunggu\nPembayaran',
      'Bukti\nDiunggah',
      'Pembayaran\nDikonfirmasi',
      'Dikirim',
      'Selesai',
    ];
    return Row(
      children: List.generate(steps.length, (i) {
        final isCompleted = i <= currentStep;
        final isLast = i == steps.length - 1;
        return Expanded(
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _showStepDetails(i, currentStep),
                child: Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFF74070E)
                            : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              )
                            : Text(
                                '${i + 1}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 52,
                      child: Text(
                        steps[i],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          color: isCompleted
                              ? const Color(0xFF74070E)
                              : Colors.black38,
                          fontWeight: isCompleted
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    color: i < currentStep
                        ? const Color(0xFF74070E)
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.black45),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.black45),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
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
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  Widget _productImage(dynamic product, double w, double h) {
    final List<dynamic> images = product['image_paths'] is String
        ? jsonDecode(product['image_paths'])
        : (product['image_paths'] ?? []);
    final imageUrl = images.isNotEmpty ? '${ApiConfig.host}${images[0]}' : '';
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(
          width: w,
          height: h,
          color: Colors.grey.shade100,
          child: const Icon(Icons.image, size: 20, color: Colors.black26),
        ),
      );
    }
    return Container(
      width: w,
      height: h,
      color: Colors.grey.shade100,
      child: const Icon(Icons.image, size: 20, color: Colors.black26),
    );
  }
}
