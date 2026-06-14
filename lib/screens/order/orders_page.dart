import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/api_config.dart';
import '../../screens/product/product_detail_page.dart';
import '../../screens/order/order_detail_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _soldOrders = [];
  List<dynamic> _boughtOrders = [];
  bool _isLoadingSold = true;
  bool _isLoadingBought = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSoldOrders();
    _fetchBoughtOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day}/${d.month}/${d.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _fetchSoldOrders() async {
    setState(() => _isLoadingSold = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/orders/sold'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _soldOrders = data['data'] ?? []);
      }
    } catch (e) {
      debugPrint('Error fetching sold orders: $e');
    } finally {
      setState(() => _isLoadingSold = false);
    }
  }

  Future<void> _fetchBoughtOrders() async {
    setState(() => _isLoadingBought = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/orders/bought'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _boughtOrders = data['data'] ?? []);
      }
    } catch (e) {
      debugPrint('Error fetching bought orders: $e');
    } finally {
      setState(() => _isLoadingBought = false);
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order, {required bool isSold}) {
    final product = order['product'] ?? {};
    final List<dynamic> images = product['image_paths'] is String
        ? jsonDecode(product['image_paths'])
        : (product['image_paths'] ?? []);
    final String imageUrl = images.isNotEmpty
        ? '${ApiConfig.host}${images[0]}'
        : '';
    final otherUser = isSold ? (order['buyer'] ?? {}) : (order['seller'] ?? {});
    final otherName = otherUser['username'] ?? otherUser['full_name'] ?? 'User';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OrderDetailPage(order: order, isSeller: isSold),
          ),
        ).then((_) {
          if (isSold) {
            _fetchSoldOrders();
          } else {
            _fetchBoughtOrders();
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 72,
                height: 72,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: Colors.grey.shade100,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.black26,
                            size: 28,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child: const Icon(
                          Icons.image,
                          color: Colors.black26,
                          size: 28,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['title'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatPrice(order['price'] ?? product['price']),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF74070E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        isSold ? Icons.person_outline : Icons.store_outlined,
                        size: 14,
                        color: Colors.black45,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          isSold
                              ? 'Dibeli oleh @$otherName'
                              : 'Dijual oleh @$otherName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.black45,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(order['created_at']),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            // Status badge
            _buildStatusBadge(order['status'] ?? 'pending_payment'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    String label;
    Color color;
    switch (status) {
      case 'pending_payment':
        label = 'Menunggu';
        color = Colors.orange;
        break;
      case 'payment_uploaded':
        label = 'Bukti Diunggah';
        color = Colors.blue;
        break;
      case 'payment_confirmed':
        label = 'Dikonfirmasi';
        color = Colors.teal;
        break;
      case 'shipped':
        label = 'Dikirim';
        color = Colors.indigo;
        break;
      case 'completed':
        label = 'Selesai';
        color = Colors.green.shade700;
        break;
      default:
        label = status;
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
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
            child: Icon(icon, size: 40, color: const Color(0xFF74070E)),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.black45),
          ),
        ],
      ),
    );
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
          'Pesanan',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF74070E),
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF74070E),
          unselectedLabelColor: Colors.black45,
          indicatorColor: const Color(0xFF74070E),
          indicatorWeight: 2.5,
          labelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Terjual'),
            Tab(text: 'Dibeli'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Terjual Tab
          RefreshIndicator(
            color: const Color(0xFF74070E),
            onRefresh: _fetchSoldOrders,
            child: _isLoadingSold
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF74070E)),
                  )
                : _soldOrders.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.25,
                      ),
                      _buildEmptyState(
                        'Belum ada barang terjual',
                        Icons.sell_outlined,
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _soldOrders.length,
                    itemBuilder: (context, index) =>
                        _buildOrderCard(_soldOrders[index], isSold: true),
                  ),
          ),

          // Dibeli Tab
          RefreshIndicator(
            color: const Color(0xFF74070E),
            onRefresh: _fetchBoughtOrders,
            child: _isLoadingBought
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF74070E)),
                  )
                : _boughtOrders.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.25,
                      ),
                      _buildEmptyState(
                        'Belum ada barang dibeli',
                        Icons.shopping_bag_outlined,
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _boughtOrders.length,
                    itemBuilder: (context, index) =>
                        _buildOrderCard(_boughtOrders[index], isSold: false),
                  ),
          ),
        ],
      ),
    );
  }
}
