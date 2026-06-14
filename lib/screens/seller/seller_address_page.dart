import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../screens/profile/notification_page.dart';
import '../../screens/profile/profile_page.dart';
import '../../screens/profile/add_address_page.dart';
import '../../main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/api_config.dart';

class SellerAddressPage extends StatefulWidget {
  const SellerAddressPage({super.key});

  @override
  State<SellerAddressPage> createState() => _SellerAddressPageState();
}

class _SellerAddressPageState extends State<SellerAddressPage> {
  final int _selectedBottomNavIndex = 3;

  List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_addresses');
    if (cached != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cached);
        setState(() {
          _addresses = decoded
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        });
      } catch (e) {
        debugPrint('Error parsing cached addresses: $e');
      }
    }

    if (_addresses.isEmpty) {
      final fullName = prefs.getString('full_name') ?? 'Pengguna';
      final phone = prefs.getString('phone_number') ?? '+62 xxx-xxxx-xxxx';
      setState(() {
        _addresses = [
          {
            'id': null,
            'title': 'Rumah',
            'name': fullName,
            'isPrimary': true,
            'phone': phone,
            'address': '',
          },
        ];
      });
    }

    await _syncAddressesWithServer();
  }

  Future<void> _syncAddressesWithServer() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/addresses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['status'] == 'success') {
          final List<dynamic> serverData = resData['data'];
          final List<Map<String, dynamic>> loaded = serverData.map((item) {
            return {
              'id': item['id'],
              'title': item['label'],
              'name': item['recipient_name'],
              'isPrimary':
                  item['is_default'] == 1 || item['is_default'] == true,
              'phone': item['phone_number'],
              'address': item['full_address'],
            };
          }).toList();

          setState(() {
            _addresses = loaded;
          });

          await prefs.setString('cached_addresses', jsonEncode(loaded));
        }
      }
    } catch (e) {
      debugPrint('Error syncing addresses: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddressDialog({
    Map<String, dynamic>? existingAddress,
    int? index,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAddressPage(existingAddress: existingAddress),
      ),
    );
    if (result != null) {
      await _syncAddressesWithServer();
    }
  }

  Future<void> _saveAddress(
    Map<String, dynamic> addressData,
    int? index,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    setState(() {
      _isLoading = true;
    });

    try {
      final body = {
        'label': addressData['title'],
        'recipient_name': addressData['name'],
        'phone_number': addressData['phone'],
        'full_address': addressData['address'],
        'is_default': addressData['isPrimary'] ? '1' : '0',
      };
      if (addressData['id'] != null) {
        body['id'] = addressData['id'].toString();
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/addresses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['status'] == 'success') {
          await _syncAddressesWithServer();
        }
      } else {
        // Fallback save locally if network fails
        setState(() {
          if (addressData['isPrimary']) {
            for (var addr in _addresses) {
              addr['isPrimary'] = false;
            }
          }
          if (index == null) {
            _addresses.add(addressData);
          } else {
            _addresses[index] = addressData;
          }
        });
        await prefs.setString('cached_addresses', jsonEncode(_addresses));
      }
    } catch (e) {
      debugPrint('Error saving address: $e');
      // Fallback save locally if network fails
      setState(() {
        if (addressData['isPrimary']) {
          for (var addr in _addresses) {
            addr['isPrimary'] = false;
          }
        }
        if (index == null) {
          _addresses.add(addressData);
        } else {
          _addresses[index] = addressData;
        }
      });
      await prefs.setString('cached_addresses', jsonEncode(_addresses));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _deleteAddress(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Hapus Alamat',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Yakin ingin menghapus alamat ini?',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.inter(color: Colors.black54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                _confirmDeleteAddress(index);
                Navigator.pop(context);
              },
              child: Text(
                'Hapus',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteAddress(int index) async {
    final addressData = _addresses[index];
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (addressData['id'] == null) {
      setState(() {
        _addresses.removeAt(index);
      });
      await prefs.setString('cached_addresses', jsonEncode(_addresses));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/addresses/${addressData['id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await _syncAddressesWithServer();
      } else {
        // Fallback delete locally
        setState(() {
          _addresses.removeAt(index);
        });
        await prefs.setString('cached_addresses', jsonEncode(_addresses));
      }
    } catch (e) {
      debugPrint('Error deleting address: $e');
      // Fallback delete locally
      setState(() {
        _addresses.removeAt(index);
      });
      await prefs.setString('cached_addresses', jsonEncode(_addresses));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                            'Alamat',
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

                // Content
                Expanded(
                  child: _addresses.isEmpty
                      ? Center(
                          child: Text(
                            'Belum ada alamat',
                            style: GoogleFonts.inter(),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                            top: 8,
                            bottom: 100,
                          ), // add space for bottom nav and FAB
                          itemCount: _addresses.length,
                          itemBuilder: (context, index) {
                            final addr = _addresses[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildAddressCard(
                                icon:
                                    addr['title']
                                        .toString()
                                        .toLowerCase()
                                        .contains('rumah')
                                    ? Icons.home_outlined
                                    : Icons.work_outline,
                                title: addr['title'],
                                name: addr['name'],
                                isPrimary: addr['isPrimary'],
                                phone: addr['phone'],
                                address: addr['address'].toString().isEmpty
                                    ? 'Belum diatur'
                                    : addr['address'],
                                onEdit: () => _showAddressDialog(
                                  existingAddress: addr,
                                  index: index,
                                ),
                                onDelete: () => _deleteAddress(index),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Floating button (Location +)
          Positioned(
            bottom: 90,
            right: 24,
            child: GestureDetector(
              onTap: () => _showAddressDialog(),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF74070E),
                      size: 48,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Color(0xFF74070E),
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Nav
          _buildBottomNav(),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF74070E)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressCard({
    required IconData icon,
    required String title,
    required String name,
    required bool isPrimary,
    required String phone,
    required String address,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEBEB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: Colors.black87),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF74070E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Utama',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.phone, size: 18, color: Colors.black87),
              const SizedBox(width: 12),
              Text(
                phone,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Colors.black87,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  address,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF74070E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Edit Alamat',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: onDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF74070E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Hapus Alamat',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
