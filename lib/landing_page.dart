import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';
import 'register_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/images/landing_bg.jpeg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback warna jika gambar belum ada
              return Container(color: const Color(0xFF2A2A2A));
            },
          ),

          // Top Gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 153,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF972B31).withOpacity(0.8),
                    const Color(0xFF310E10).withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height:
                MediaQuery.of(context).size.height *
                0.5, // Mengambil setengah layar bawah
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF6C060C).withOpacity(0.0),
                    const Color(0xFF060001).withOpacity(1.0),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 50),

                // Title
                Text(
                  'PakeLagi',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 64,
                    fontWeight: FontWeight.w800, // ExtraBold
                    color: const Color(0xFFFFFFFF),
                  ),
                ),

                const Spacer(),

                // Daftar Akun Button
                GestureDetector(
                  // Menambahkan event tap untuk efek di mobile
                  onTapDown: (_) => setState(() => _isHovering = true),
                  onTapUp: (_) => setState(() => _isHovering = false),
                  onTapCancel: () => setState(() => _isHovering = false),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterPage(),
                      ),
                    );
                  },
                  child: MouseRegion(
                    // Hover effect untuk Web/Desktop
                    onEnter: (_) => setState(() => _isHovering = true),
                    onExit: (_) => setState(() => _isHovering = false),
                    cursor: SystemMouseCursors.click,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 261,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _isHovering
                            ? const Color(0xFFA2A2A2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(21), // pill shape
                        border: Border.all(
                          color: const Color(0xFFFFFFFF),
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Daftar akun',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700, // Bold
                          color: _isHovering
                              ? const Color(0xFF000000)
                              : const Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Login Text
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFFFFFFF),
                    ),
                    children: [
                      const TextSpan(text: 'Sudah punya akun? '),
                      TextSpan(
                        text: 'Login',
                        style: const TextStyle(decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
