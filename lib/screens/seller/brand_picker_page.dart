import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrandPickerPage extends StatefulWidget {
  const BrandPickerPage({super.key});

  @override
  State<BrandPickerPage> createState() => _BrandPickerPageState();
}

class _BrandPickerPageState extends State<BrandPickerPage> {
  final List<String> _brands = [
    "Adidas",
    "Asics",
    "Bershka",
    "Burberry",
    "Calvin Klein",
    "Carhartt",
    "Champion",
    "Coach",
    "Colorbox",
    "Columbia",
    "Converse",
    "Dickies",
    "Disney",
    "Dr. Martens",
    "Ellesse",
    "Fila",
    "Fred Perry",
    "GAP",
    "Giordano",
    "GU",
    "Guess",
    "H&M",
    "Kappa",
    "Lacoste",
    "Levi's",
    "Louis Vuitton",
    "Made In USA",
    "MLB",
    "New Balance",
    "New Era",
    "Nike",
    "Oakley",
    "Onitsuka Tiger",
    "Polo Ralph Lauren",
    "Pull & Bear",
    "Puma",
    "Salomon",
    "Stussy",
    "Supreme",
    "The North Face",
    "Timberland",
    "Tommy Hilfiger",
    "Umbro",
    "Uniqlo",
    "Vans",
    "Zara",
  ];

  List<String> _filteredBrands = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredBrands = List.from(_brands);
    _filteredBrands.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  void _filterBrands(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredBrands = List.from(_brands);
      } else {
        _filteredBrands = _brands
            .where((brand) => brand.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      _filteredBrands.sort(
        (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
      );
    });
  }

  Map<String, List<String>> _groupBrands(List<String> brandsList) {
    final Map<String, List<String>> grouped = {};
    for (var brand in brandsList) {
      final String firstLetter = brand[0].toUpperCase();
      if (!grouped.containsKey(firstLetter)) {
        grouped[firstLetter] = [];
      }
      grouped[firstLetter]!.add(brand);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupBrands(_filteredBrands);
    final sortedKeys = grouped.keys.toList()..sort();

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
                // Custom Header with back arrow and Title aligned & Lewati on right
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
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
                            'Pilih Brand',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, 'Tanpa Brand');
                        },
                        child: Text(
                          'Lewati',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF74070E),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      onChanged: _filterBrands,
                      cursorColor: const Color(0xFF74070E),
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        icon: const Icon(Icons.search, color: Colors.black54),
                        hintText: 'Cari brand...',
                        hintStyle: GoogleFonts.inter(color: Colors.black38),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Alphabetical Brands List
                Expanded(
                  child: _filteredBrands.isEmpty
                      ? Center(
                          child: Text(
                            'Brand tidak ditemukan.',
                            style: GoogleFonts.inter(color: Colors.black54),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: sortedKeys.length,
                          itemBuilder: (context, index) {
                            final letter = sortedKeys[index];
                            final brandsInLetter = grouped[letter]!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Letter header
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Text(
                                    letter,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: const Color(0xFF74070E),
                                    ),
                                  ),
                                ),
                                const Divider(height: 1, thickness: 1),
                                // Brands in this letter
                                ...brandsInLetter.map((brand) {
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      brand,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context, brand);
                                    },
                                  );
                                }),
                                const SizedBox(height: 16),
                              ],
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
