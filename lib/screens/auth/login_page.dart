import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_config.dart';
import '../../main.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoginPressed = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  Future<void> _onLogin() async {
    setState(() {
      _autovalidateMode = AutovalidateMode.onUserInteraction;
    });
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/login'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'email': _emailController.text,
            'password': _passwordController.text,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['access_token']);
          await prefs.setInt('user_id', data['user']['id']);
          await prefs.setString('full_name', data['user']['full_name'] ?? '');
          await prefs.setString('email', data['user']['email'] ?? '');
          await prefs.setString('username', data['user']['username'] ?? '');
          await prefs.setString(
            'phone_number',
            data['user']['phone_number'] ?? '',
          );
          await prefs.setString('bio', data['user']['bio'] ?? '');
          await prefs.setString(
            'profile_picture_url',
            data['user']['profile_picture_url'] ?? '',
          );

          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        } else {
          final data = jsonDecode(response.body);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Login gagal')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Koneksi bermasalah: $e')));
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              autovalidateMode: _autovalidateMode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Illustration Image
                  // Pastikan Anda menyimpan gambar dengan nama login_illustration.png di folder assets/images/
                  Center(
                    child: Image.asset(
                      'assets/images/login_illustration.jpg',
                      width: 360,
                      height: 360,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 360,
                          height: 360,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image,
                                size: 50,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Letakkan gambar di\nassets/images/login_illustration.png',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    'Login',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, // Semi Bold
                      fontSize: 48,
                      color: const Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Lakukan login untuk melanjutkan.',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w400, // Regular
                      fontSize: 14,
                      color: const Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Email Label
                  _buildLabel('Alamat email'),
                  const SizedBox(height: 8),

                  // Email Input
                  _buildInputField(
                    controller: _emailController,
                    hintText: 'Masukkan alamat email Anda',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Alamat email wajib diisi';
                      }
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(value)) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Password Label
                  _buildLabel('Kata Sandi'),
                  const SizedBox(height: 8),

                  // Password Input
                  _buildPasswordField(),
                  const SizedBox(height: 48),

                  // Login Button
                  GestureDetector(
                    onTapDown: (_) => setState(() => _isLoginPressed = true),
                    onTapUp: (_) => setState(() => _isLoginPressed = false),
                    onTapCancel: () => setState(() => _isLoginPressed = false),
                    onTap: _onLogin,
                    child: AnimatedContainer(
                      duration: const Duration(
                        milliseconds: 1000,
                      ), // Smart animate durasi 1000ms
                      curve: Curves.easeInOut,
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _isLoginPressed
                            ? const Color(0xFFAAAAAA)
                            : const Color(0xFFFFFFFF),
                        border: Border.all(color: const Color(0xFFAAAAAA)),
                        borderRadius: BorderRadius.circular(25), // Pill shape
                      ),
                      alignment: Alignment.center,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Login',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700, // Bold
                                fontSize: 16,
                                color: const Color(0xFF000000),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Belum punya akun? ',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: const Color(0xFF000000),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Daftar di sini',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: const Color(0xFF74070E),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40), // Padding bawah
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w400, // Regular
        fontSize: 14,
        color: const Color(0xFF000000),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 11,
        color: const Color(0xFF000000),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          fontSize: 11,
          color: const Color(0xFF000000).withOpacity(0.5),
        ),
        prefixIcon: Icon(icon, color: Colors.black87),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Color(0xFFAAAAAA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Color(0xFFAAAAAA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Color(0xFFAAAAAA), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      validator: (value) =>
          value == null || value.isEmpty ? 'Kata sandi wajib diisi' : null,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 11,
        color: const Color(0xFF000000),
      ),
      decoration: InputDecoration(
        hintText: 'Masukkan sandi Anda',
        hintStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          fontSize: 11,
          color: const Color(0xFF000000).withOpacity(0.5),
        ),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.black87),
        suffixIcon: GestureDetector(
          onTap: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
          child: Icon(
            _isPasswordVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Colors.black87,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Color(0xFFAAAAAA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Color(0xFFAAAAAA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Color(0xFFAAAAAA), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
      ),
    );
  }
}
