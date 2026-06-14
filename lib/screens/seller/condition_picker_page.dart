import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConditionPickerPage extends StatelessWidget {
  const ConditionPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> conditions = [
      {
        'title': 'Baru dengan Tag',
        'desc':
            'Barang baru dengan label harga masih menempel. Tidak ada cacat sama sekali.',
      },
      {
        'title': 'Baru tanpa Tag',
        'desc':
            'Barang baru tetapi label harga sudah dilepas. Tidak pernah dipakai dan tidak ada cacat.',
      },
      {
        'title': 'Sangat Baik',
        'desc':
            'Barang bekas yang jarang dipakai. Terlihat seperti baru, tidak ada tanda-tanda keausan atau cacat yang terlihat.',
      },
      {
        'title': 'Baik',
        'desc':
            'Barang bekas yang sudah dipakai beberapa kali tetapi masih dalam kondisi layak. Mungkin ada sedikit keausan halus.',
      },
      {
        'title': 'Cukup',
        'desc':
            'Barang bekas yang sering dipakai dan memiliki tanda-tanda keausan yang terlihat jelas, namun masih berfungsi dengan baik.',
      },
    ];

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
                        'Pilih Kondisi',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Conditions List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: conditions.length,
                    itemBuilder: (context, index) {
                      final item = conditions[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          title: Text(
                            item['title']!,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF74070E),
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              item['desc']!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.black38,
                          ),
                          onTap: () {
                            Navigator.pop(context, item['title']);
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
