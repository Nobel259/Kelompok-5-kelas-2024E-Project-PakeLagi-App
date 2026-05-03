import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'landing_page.dart';
import 'search_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pake Lagi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      home: const LandingPage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['WANITA', 'PRIA', 'ANAK'];
  int _selectedBottomNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Content
          Column(
            children: [
              // Top Section with Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF972B31),
                      const Color(0xFFEB8C8C).withOpacity(0.07),
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                // Search Bar & Cart
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFDEDEDE),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              Icon(
                                Icons.search,
                                color: const Color(
                                  0xFF972B31,
                                ).withOpacity(0.80),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  readOnly: true,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) => const SearchPage(),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          return FadeTransition(opacity: animation, child: child);
                                        },
                                      ),
                                    );
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Apa yang Anda cari?',
                                    hintStyle: GoogleFonts.inter(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                      color: const Color(
                                        0xFF972B31,
                                      ).withOpacity(0.80),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                    color: const Color(
                                      0xFF972B31,
                                    ).withOpacity(0.80),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.shopping_basket_outlined,
                        color: Color(0xFF74070E),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.chat_outlined,
                        color: Color(0xFF74070E),
                        size: 28,
                      ),
                    ],
                  ),
                ),

                // Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_tabs.length, (index) {
                      final isSelected = _selectedTabIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTabIndex = index;
                          });
                        },
                        child: Column(
                          children: [
                            Text(
                              _tabs[index],
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF74070E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 1,
                              width: 50,
                              color: isSelected
                                  ? const Color(0xFF74070E)
                                  : Colors.transparent,
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // Categories (White background)
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 80, top: 8),
                    children: [
                      _buildCategoryRow('Bottoms'),
                      _buildCategoryRow('Tops'),
                      _buildCategoryRow('Dresses'),
                      _buildCategoryRow('Footwear'),
                      _buildCategoryRow('Outerwear'),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Navigation
          Positioned(
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
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF74070E),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Color(0xFF74070E),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 176,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: 20,
            itemBuilder: (context, index) {
              return Container(
                width: 128,
                height: 176,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF74070E).withOpacity(0.50),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: const Center(
                    child: Icon(Icons.image, color: Colors.grey, size: 40),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBottomNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedBottomNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBottomNavIndex = index;
        });
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
                fontWeight: FontWeight.w500,
                color: const Color(0xFF74070E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
