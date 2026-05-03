import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Global search history variable to persist state in memory
List<String> _globalSearchHistory = [
  'Koleksi jeans',
  'Baju lebaran',
  'Celana barrel',
  'Hoodie',
  'Cardigan',
];

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  void _addSearchQuery(String query) {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _globalSearchHistory.remove(query);
      _globalSearchHistory.insert(0, query);
      if (_globalSearchHistory.length > 10) {
        _globalSearchHistory.removeLast();
      }
    });
    _searchController.clear();
  }

  void _removeSearchItem(String item) {
    setState(() {
      _globalSearchHistory.remove(item);
    });
  }

  void _clearAllHistory() {
    setState(() {
      _globalSearchHistory.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF972B31).withOpacity(0.05),
                    Colors.white,
                  ],
                ),
              ),
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 12.0,
                bottom: 12.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                            color: const Color(0xFF972B31).withOpacity(0.80),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Apa yang Anda cari?',
                                hintStyle: GoogleFonts.inter(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  color: const Color(0xFF972B31).withOpacity(0.80),
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
                                color: const Color(0xFF972B31),
                              ),
                              onSubmitted: _addSearchQuery,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Batal',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF74070E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // History Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Riwayat pencarian',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        GestureDetector(
                          onTap: _clearAllHistory,
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.black87,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFE0E0E0)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _globalSearchHistory.length,
                        itemBuilder: (context, index) {
                          final item = _globalSearchHistory[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black87,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _removeSearchItem(item),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.black54,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
