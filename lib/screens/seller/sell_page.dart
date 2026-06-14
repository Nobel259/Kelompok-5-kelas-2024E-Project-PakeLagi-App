import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../../core/api_config.dart';
import '../../screens/seller/category_picker_page.dart';
import '../../screens/profile/add_address_page.dart';
import '../../screens/seller/cropper_page.dart';

class SellPage extends StatefulWidget {
  const SellPage({super.key});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final List<XFile> _selectedImages = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  List<String> _selectedCategories = [];
  Map<String, dynamic>? _selectedAddress;
  List<Map<String, dynamic>> _addresses = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();

    // Load cached first
    final cached = prefs.getString('cached_addresses');
    if (cached != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cached);
        setState(() {
          _addresses = decoded
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          _setDefaultAddress();
        });
      } catch (e) {
        debugPrint('Error decoding cached addresses: $e');
      }
    }

    // Then sync from server
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      return;
    }

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
            _setDefaultAddress();
          });
          await prefs.setString('cached_addresses', jsonEncode(loaded));
        }
      }
    } catch (e) {
      debugPrint('Error syncing addresses: $e');
    }
  }

  void _setDefaultAddress() {
    if (_addresses.isNotEmpty) {
      // Find primary
      final primary = _addresses.firstWhere(
        (addr) => addr['isPrimary'] == true,
        orElse: () => _addresses.first,
      );
      _selectedAddress = primary;
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1080,
      );
      if (image != null) {
        final File? croppedFile = await Navigator.push<File>(
          context,
          MaterialPageRoute(
            builder: (context) => CropperPage(imageFile: File(image.path)),
          ),
        );
        if (croppedFile != null) {
          setState(() {
            _selectedImages.add(XFile(croppedFile.path));
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _selectCategory() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const CategoryPickerPage()),
    );
    if (result != null) {
      setState(() {
        if (result.startsWith('Brand:')) {
          _selectedCategories.removeWhere((c) => c.startsWith('Brand:'));
          _selectedCategories.add(result);
        } else if (result.startsWith('Kondisi:')) {
          _selectedCategories.removeWhere((c) => c.startsWith('Kondisi:'));
          _selectedCategories.add(result);
        } else if (result == 'Wanita' || result == 'Pria' || result == 'Anak') {
          _selectedCategories.removeWhere(
            (c) => c == 'Wanita' || c == 'Pria' || c == 'Anak',
          );
          _selectedCategories.add(result);
        } else {
          if (!_selectedCategories.contains(result)) {
            _selectedCategories.add(result);
          }
        }
      });
    }
  }

  void _showAddressSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih Alamat Pengiriman',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_addresses.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Text(
                          'Belum ada alamat tersimpan.',
                          style: GoogleFonts.inter(color: Colors.black54),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _addresses.length,
                        itemBuilder: (context, index) {
                          final addr = _addresses[index];
                          final isSel =
                              _selectedAddress?['id'] == addr['id'] ||
                              (_selectedAddress == null && index == 0);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFF74070E).withOpacity(0.05)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSel
                                    ? const Color(0xFF74070E)
                                    : Colors.grey.shade200,
                                width: isSel ? 1.5 : 1,
                              ),
                            ),
                            child: ListTile(
                              title: Text(
                                "${addr['title']} - ${addr['name']}",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                addr['address'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              trailing: isSel
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF74070E),
                                    )
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedAddress = addr;
                                });
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add, color: Color(0xFF74070E)),
                      label: Text(
                        'Tambah Alamat Baru',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF74070E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF74070E)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        final newAddr = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddAddressPage(),
                          ),
                        );
                        if (newAddr != null) {
                          await _loadAddresses();
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPriceInputDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Atur Harga',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            cursorColor: const Color(0xFF74070E),
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            decoration: const InputDecoration(
              prefixText: 'Rp ',
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF74070E)),
              ),
            ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF74070E),
              ),
              onPressed: () {
                setState(() {});
                Navigator.pop(context);
              },
              child: Text(
                'Simpan',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadProduct() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan tambahkan minimal satu foto produk'),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kategori produk')),
      );
      return;
    }
    if (_priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan atur harga produk')),
      );
      return;
    }
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih alamat pengiriman')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        throw Exception(
          'Token otentikasi tidak ditemukan. Silakan login kembali.',
        );
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/products');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['title'] = _titleController.text.trim();
      request.fields['description'] = _descriptionController.text.trim();
      request.fields['price'] = _priceController.text
          .replaceAll('.', '')
          .trim();
      request.fields['categories'] = jsonEncode(_selectedCategories);
      request.fields['address_id'] = _selectedAddress!['id'].toString();

      for (int i = 0; i < _selectedImages.length; i++) {
        final file = File(_selectedImages[i].path);
        request.files.add(
          await http.MultipartFile.fromPath('images[]', file.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        if (!mounted) return;
        setState(() => _isUploading = false);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF74070E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Berhasil!',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Produk Anda telah berhasil dipasarkan.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF74070E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        // Reset form
                        setState(() {
                          _selectedImages.clear();
                          _titleController.clear();
                          _descriptionController.clear();
                          _priceController.clear();
                          _selectedCategories.clear();
                        });
                      },
                      child: Text(
                        'Selesai',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal mengunggah produk.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Stack(
        children: [
          // Top Red Gradient Background
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
                    const Color(0xFFF6F6F6).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Custom Header Title
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      'Jual',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFF74070E),
                    backgroundColor: Colors.white,
                    onRefresh: _loadAddresses,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 100,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Photo Selection Box Container
                            Container(
                              height: 130,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                itemCount: _selectedImages.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == _selectedImages.length) {
                                    // Add button at the end
                                    return GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        width: 90,
                                        margin: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECEECE),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFF74070E,
                                            ).withOpacity(0.3),
                                            style: BorderStyle.solid,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.add,
                                              color: Color(0xFF74070E),
                                              size: 20,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Tambah Foto',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF74070E),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  final img = _selectedImages[index];
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 90,
                                        margin: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          image: DecorationImage(
                                            image: FileImage(File(img.path)),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 16,
                                        child: GestureDetector(
                                          onTap: () => _removeImage(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 2. Judul & Deskripsi Input Card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Judul/Nama Barang',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  TextFormField(
                                    controller: _titleController,
                                    cursorColor: const Color(0xFF74070E),
                                    decoration: InputDecoration(
                                      hintText: 'cth. Zara Top',
                                      hintStyle: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.black38,
                                      ),
                                      focusedBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0xFF74070E),
                                        ),
                                      ),
                                    ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Judul barang harus diisi'
                                        : null,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Deskripsi',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  TextFormField(
                                    controller: _descriptionController,
                                    maxLines: 3,
                                    cursorColor: const Color(0xFF74070E),
                                    decoration: InputDecoration(
                                      hintText:
                                          'cth. Jarang dipakai, size S, ada noda dibagian bawah belakang, bahan katun',
                                      hintStyle: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.black38,
                                      ),
                                      focusedBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0xFF74070E),
                                        ),
                                      ),
                                    ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Deskripsi barang harus diisi'
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 3. Category Selector
                            GestureDetector(
                              onTap: _selectCategory,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Kategori',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          _selectedCategories.isEmpty
                                              ? 'Atur'
                                              : 'Edit',
                                          style: GoogleFonts.inter(
                                            color: Colors.black38,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 14,
                                          color: Colors.black38,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Display selected categories list below the card
                            if (_selectedCategories.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _selectedCategories.map((cat) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF74070E,
                                        ).withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF74070E,
                                          ).withOpacity(0.2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            cat,
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFF74070E),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedCategories.remove(cat);
                                              });
                                            },
                                            child: const Icon(
                                              Icons.close,
                                              size: 14,
                                              color: Color(0xFF74070E),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),

                            // 4. Price Selector
                            GestureDetector(
                              onTap: _showPriceInputDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Harga',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          _priceController.text
                                                  .trim()
                                                  .isNotEmpty
                                              ? "Rp ${_priceController.text.trim()}"
                                              : 'Atur',
                                          style: GoogleFonts.inter(
                                            color:
                                                _priceController.text
                                                    .trim()
                                                    .isNotEmpty
                                                ? Colors.black87
                                                : Colors.black38,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 14,
                                          color: Colors.black38,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 5. Address Selector
                            GestureDetector(
                              onTap: _showAddressSelector,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Pilih Alamat',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          if (_selectedAddress != null) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              "${_selectedAddress!['title']} - ${_selectedAddress!['name']}",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          _selectedAddress != null
                                              ? 'Ganti'
                                              : 'Atur',
                                          style: GoogleFonts.inter(
                                            color: _selectedAddress != null
                                                ? Colors.black87
                                                : Colors.black38,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 14,
                                          color: Colors.black38,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // 6. Upload Button
                            Center(
                              child: SizedBox(
                                width: 250,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _isUploading
                                      ? null
                                      : _uploadProduct,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF74070E),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isUploading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : Text(
                                          'Upload',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    final buffer = StringBuffer();
    for (int i = 0; i < cleanText.length; i++) {
      if (i > 0 && (cleanText.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(cleanText[i]);
    }

    final String formattedText = buffer.toString();
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
