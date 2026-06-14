import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api_config.dart';
import '../../screens/profile/notification_page.dart';
import '../../screens/profile/profile_page.dart';
import '../../screens/seller/cropper_page.dart';
import '../../main.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final int _selectedBottomNavIndex = 3;

  String _username = '';
  String _name = '';
  String _bio = 'Tidak Ada Bio';
  bool _isSaving = false;
  File? _profileImage;
  String _profilePictureUrl = '';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('full_name') ?? 'Pengguna';
      String cachedUsername = prefs.getString('username') ?? '';
      if (cachedUsername.isEmpty) {
        String email = prefs.getString('email') ?? '';
        if (email.contains('@')) {
          cachedUsername = email.split('@')[0];
        }
      }
      _username = cachedUsername;
      _bio = prefs.getString('bio') ?? 'Tidak Ada Bio';
      _profilePictureUrl = prefs.getString('profile_picture_url') ?? '';
    });
  }

  Future<void> _saveToServer(String field, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({field: value}),
      );
      if (response.statusCode == 200) {
        // Update SharedPreferences juga
        if (field == 'full_name') await prefs.setString('full_name', value);
        if (field == 'bio') await prefs.setString('bio', value);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    }
  }

  void _editField(String title, String currentValue, Function(String) onSave) {
    TextEditingController controller = TextEditingController(
      text: currentValue,
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Edit $title',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF74070E)),
              ),
              hintText: 'Masukkan $title baru',
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
                onSave(controller.text);
                Navigator.pop(context);
                // Simpan perubahan ke server
                if (title == 'Username') _saveUsernameToServer(controller.text);
                if (title == 'Nama')
                  _saveToServer('full_name', controller.text);
                if (title == 'Bio') _saveToServer('bio', controller.text);
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

  Future<void> _saveUsernameToServer(String newUsername) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'username': newUsername}),
      );

      final resData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Update local SharedPreferences
        await prefs.setString('username', newUsername);
        setState(() {
          _username = newUsername;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username berhasil diperbarui!')),
        );
      } else {
        final errorMsg = resData['message'] ?? 'Gagal menyimpan username';
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMsg)));
        // Revert UI to old value
        _loadUserData();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      // Revert UI
      _loadUserData();
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _editPhoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text('Ambil Foto', style: GoogleFonts.inter()),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text('Pilih dari Galeri', style: GoogleFonts.inter()),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File? croppedFile = await Navigator.push<File>(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CropperPage(imageFile: File(pickedFile.path), isCircular: true),
          ),
        );

        if (croppedFile != null) {
          setState(() {
            _profileImage = croppedFile;
          });
          _uploadProfilePhoto(croppedFile);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil gambar: $e')));
    }
  }

  Future<void> _uploadProfilePhoto(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/profile'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.files.add(
        await http.MultipartFile.fromPath('profile_picture', imageFile.path),
      );

      var response = await request.send();
      if (response.statusCode == 200) {
        final resBody = await http.Response.fromStream(response);
        final data = jsonDecode(resBody.body);
        final newPicUrl = data['user']['profile_picture_url'] ?? '';
        await prefs.setString('profile_picture_url', newPicUrl);

        setState(() {
          _profilePictureUrl = newPicUrl;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengunggah foto profil')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error upload: $e')));
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
                            'Edit Profil',
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
                const SizedBox(height: 16),

                // Avatar with Edit Button
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[300],
                        ),
                        child: ClipOval(
                          child: _profileImage != null
                              ? Image.file(
                                  _profileImage!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : _profilePictureUrl.isNotEmpty
                              ? Image.network(
                                  '${ApiConfig.host}/uploads/profiles/$_profilePictureUrl',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.white,
                                      ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: -10,
                        child: GestureDetector(
                          onTap: _editPhoto,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              'Edit',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Form Fields
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBEBEB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildProfileItem('Username', _username, () {
                        _editField(
                          'Username',
                          _username,
                          (newVal) => setState(() => _username = newVal),
                        );
                      }),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey.shade300,
                      ),
                      _buildProfileItem('Nama', _name, () {
                        _editField(
                          'Nama',
                          _name,
                          (newVal) => setState(() => _name = newVal),
                        );
                      }),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey.shade300,
                      ),
                      _buildProfileItem('Bio', _bio, () {
                        _editField(
                          'Bio',
                          _bio,
                          (newVal) => setState(() => _bio = newVal),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Nav
          _buildBottomNav(),

          if (_isSaving)
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

  Widget _buildProfileItem(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black54, size: 20),
          ],
        ),
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
