import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/api_config.dart';
import '../../screens/profile/map_picker_page.dart';

class AddAddressPage extends StatefulWidget {
  final Map<String, dynamic>? existingAddress;
  const AddAddressPage({super.key, this.existingAddress});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalController;
  late final TextEditingController _addressController;

  String _selectedLabel = 'Rumah';
  final TextEditingController _customLabelController = TextEditingController();
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final addr = widget.existingAddress;
    _nameController = TextEditingController(text: addr?['name'] ?? '');
    _phoneController = TextEditingController(text: addr?['phone'] ?? '');
    _cityController = TextEditingController(text: addr?['city'] ?? '');
    _postalController = TextEditingController(text: addr?['postal_code'] ?? '');
    _addressController = TextEditingController(text: addr?['address'] ?? '');
    _isDefault = addr?['isPrimary'] ?? false;

    final label = addr?['title'] ?? 'Rumah';
    if (label == 'Rumah' || label == 'Kantor') {
      _selectedLabel = label;
    } else {
      _selectedLabel = 'Lainnya';
      _customLabelController.text = label;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _postalController.dispose();
    _addressController.dispose();
    _customLabelController.dispose();
    super.dispose();
  }

  Future<void> _selectAddressFromMap() async {
    final selectedAddress = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MapPickerPage(initialAddress: _addressController.text),
      ),
    );
    if (selectedAddress != null) {
      setState(() {
        _addressController.text = selectedAddress;

        // Parse city from address string if possible
        final parts = selectedAddress.split(',');
        if (parts.length > 2) {
          // Grab a likely city keyword
          for (var part in parts.reversed) {
            final clean = part.trim();
            if (clean.toLowerCase().contains('jakarta') ||
                clean.toLowerCase().contains('surabaya') ||
                clean.toLowerCase().contains('bandung') ||
                clean.toLowerCase().contains('medan') ||
                clean.toLowerCase().contains('semarang') ||
                clean.toLowerCase().contains('yogyakarta')) {
              _cityController.text = clean;
              break;
            }
          }
        }
      });
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    String label = _selectedLabel;
    if (_selectedLabel == 'Lainnya') {
      label = _customLabelController.text.trim().isNotEmpty
          ? _customLabelController.text.trim()
          : 'Lainnya';
    }

    // Combine postal code with address or city
    String fullAddress = _addressController.text.trim();
    if (_postalController.text.trim().isNotEmpty) {
      fullAddress += " (Kode POS: ${_postalController.text.trim()})";
    }

    final payload = {
      'label': label,
      'recipient_name': _nameController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'full_address': fullAddress,
      'city': _cityController.text.trim(),
      'is_default': _isDefault,
    };

    if (widget.existingAddress?['id'] != null) {
      payload['id'] = widget.existingAddress!['id'];
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/addresses'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      final resData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingAddress == null
                  ? 'Alamat berhasil ditambahkan!'
                  : 'Alamat berhasil diperbarui!',
            ),
          ),
        );
        Navigator.pop(context, resData['data']);
      } else {
        final errorMsg = resData['message'] ?? 'Gagal menyimpan alamat';
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top Red Gradient
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
                // Custom AppBar Header
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
                            widget.existingAddress == null
                                ? 'Tambahkan Alamat'
                                : 'Edit Alamat',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balance spacing
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Interactive Map Container at the top (styled like pilih alamat.png)
                          GestureDetector(
                            onTap: _selectAddressFromMap,
                            child: Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFECECEC),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: Color(0xFF74070E),
                                        size: 60,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Pilih Lokasi dari Peta',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    left: 12,
                                    right: 12,
                                    child: Text(
                                      _addressController.text.isNotEmpty
                                          ? _addressController.text
                                          : 'Pastikan alamat yang Anda masukkan benar untuk memudahkan pengiriman.',
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Nama Field
                          _buildLabel('Nama'),
                          _buildTextField(
                            controller: _nameController,
                            hintText: 'Contoh: Uchinaga Aeri',
                            validator: (v) => v == null || v.isEmpty
                                ? 'Nama harus diisi'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Nomor Telepon Field
                          _buildLabel('Nomor Telepon'),
                          _buildTextField(
                            controller: _phoneController,
                            hintText: '08xxxxxxxxxx',
                            keyboardType: TextInputType.phone,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Nomor telepon harus diisi'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Kota/Kecamatan & Kode POS (Side by side)
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Kota/Kecamatan'),
                                    _buildTextField(
                                      controller: _cityController,
                                      hintText: 'Surabaya',
                                      validator: (v) => v == null || v.isEmpty
                                          ? 'Kota/Kecamatan harus diisi'
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Kode POS'),
                                    _buildTextField(
                                      controller: _postalController,
                                      hintText: '12345',
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Alamat Lengkap Field
                          _buildLabel('Alamat Lengkap'),
                          _buildTextField(
                            controller: _addressController,
                            hintText:
                                'Nama jalan, nomor rumah, RT/RW, patokan gedung...',
                            maxLines: 3,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Alamat lengkap harus diisi'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Label Alamat Selector (Rumah, Kantor, Lainnya)
                          _buildLabel('Label Alamat'),
                          Row(
                            children: ['Rumah', 'Kantor', 'Lainnya'].map((lbl) {
                              final isSelected = _selectedLabel == lbl;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedLabel = lbl),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF74070E)
                                        : const Color(0xFFECECEC),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    lbl,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (_selectedLabel == 'Lainnya') ...[
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _customLabelController,
                              hintText: 'Masukkan nama label custom...',
                            ),
                          ],
                          const SizedBox(height: 20),

                          // Jadikan Alamat Utama Switch
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Jadikan Alamat Utama',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Switch(
                                value: _isDefault,
                                activeColor: const Color(0xFF74070E),
                                onChanged: (val) {
                                  setState(() {
                                    _isDefault = val;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Simpan Alamat Button
                          Center(
                            child: SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveAddress,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF74070E),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : Text(
                                        'Simpan Alamat',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      cursorColor: const Color(0xFF74070E),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(color: Colors.black38, fontSize: 13),
        fillColor: const Color(0xFFECECEC),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
