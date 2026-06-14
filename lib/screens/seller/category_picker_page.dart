import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../screens/seller/brand_picker_page.dart';
import '../../screens/seller/condition_picker_page.dart';
import '../../screens/seller/subcategory_picker_page.dart';

class CategoryPickerPage extends StatelessWidget {
  const CategoryPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = ['Brand', 'Kondisi', 'Wanita', 'Pria', 'Anak'];

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
                        'Pilih Kategori',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Category List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          title: Text(
                            cat,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.black38,
                          ),
                          onTap: () async {
                            if (cat == 'Brand') {
                              final selectedBrand =
                                  await Navigator.push<String>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const BrandPickerPage(),
                                    ),
                                  );
                              if (selectedBrand != null && context.mounted) {
                                Navigator.pop(context, 'Brand: $selectedBrand');
                              }
                            } else if (cat == 'Kondisi') {
                              final selectedCondition =
                                  await Navigator.push<String>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ConditionPickerPage(),
                                    ),
                                  );
                              if (selectedCondition != null &&
                                  context.mounted) {
                                Navigator.pop(
                                  context,
                                  'Kondisi: $selectedCondition',
                                );
                              }
                            } else {
                              final subcatResult = await Navigator.push<String>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SubcategoryPickerPage(gender: cat),
                                ),
                              );
                              if (subcatResult != null && context.mounted) {
                                Navigator.pop(context, subcatResult);
                              }
                            }
                          },
                        ),
                      );
                    },
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
