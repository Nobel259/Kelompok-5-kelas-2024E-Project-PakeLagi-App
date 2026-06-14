import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SizePickerPage extends StatefulWidget {
  final String gender;
  final String subcategory;

  const SizePickerPage({
    super.key,
    required this.gender,
    required this.subcategory,
  });

  @override
  State<SizePickerPage> createState() => _SizePickerPageState();
}

class _SizePickerPageState extends State<SizePickerPage> {
  String? _selectedSize;

  List<String> _getSizes() {
    if (widget.subcategory.toLowerCase() == 'footwear') {
      return [
        'EU 34.5',
        'EU 35',
        'EU 35.5',
        'EU 36',
        'EU 36.5',
        'EU 37',
        'EU 38',
        'EU 38.5',
        'EU 39',
        'EU 40',
        'EU 40.5',
        'EU 41',
        'EU 42',
        'EU 43',
        'EU 44',
      ];
    } else {
      return ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL', 'XXXXL', 'XXS'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _getSizes();

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Header with back arrow and Title aligned
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF74070E),
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pilih Ukuran',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Subcategory Header Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    widget.subcategory,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Size Grid/Wrap
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: sizes.map((size) {
                          final isSelected = _selectedSize == size;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedSize = size;
                              });
                            },
                            child: Container(
                              width:
                                  widget.subcategory.toLowerCase() == 'footwear'
                                  ? 76
                                  : 68,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF74070E)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF74070E),
                                  width: 1.2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  size,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                // Select Button at the bottom
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF74070E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      onPressed: _selectedSize == null
                          ? null
                          : () {
                              Navigator.pop(context, _selectedSize);
                            },
                      child: Text(
                        'Pilih',
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
        ],
      ),
    );
  }
}
