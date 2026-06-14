import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/api_config.dart';
import '../../screens/product/product_detail_page.dart';
import '../../screens/seller/seller_profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  List<dynamic> _searchHistory = [];
  List<dynamic> _products = [];
  List<dynamic> _users = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  // Selected filters
  final Set<String> _selectedBrands = {};
  final Set<String> _selectedConditions = {};
  final Set<String> _selectedSizes = {};
  int? _minPrice;
  int? _maxPrice;

  final List<String> _allBrands = [
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

  final List<String> _allConditions = [
    "Baru dengan tag",
    "Baru tanpa tag",
    "Sangat baik",
    "Baik",
    "Cukup",
  ];

  final List<String> _allSizes = [
    "XS",
    "S",
    "M",
    "L",
    "XL",
    "XXL",
    "XXXL",
    "EU 35",
    "EU 36",
    "EU 37",
    "EU 38",
    "EU 39",
    "EU 40",
    "EU 41",
    "EU 42",
    "EU 43",
    "EU 44",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchHistoryOnly();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistoryOnly() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/search'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        final data = resData['data'] ?? {};
        setState(() {
          _searchHistory = data['history'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error loading search history: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _performSearch({bool recordHistory = false}) async {
    final query = _searchController.text.trim();

    if (query.isEmpty &&
        _selectedBrands.isEmpty &&
        _selectedConditions.isEmpty &&
        _selectedSizes.isEmpty &&
        _minPrice == null &&
        _maxPrice == null) {
      setState(() {
        _hasSearched = false;
        _products = [];
        _users = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final Map<String, String> queryParams = {};
      if (query.isNotEmpty) queryParams['q'] = query;
      if (_selectedBrands.isNotEmpty) {
        queryParams['brands'] = jsonEncode(_selectedBrands.toList());
      }
      if (_selectedConditions.isNotEmpty) {
        queryParams['conditions'] = jsonEncode(_selectedConditions.toList());
      }
      if (_selectedSizes.isNotEmpty) {
        queryParams['sizes'] = jsonEncode(_selectedSizes.toList());
      }
      if (_minPrice != null) {
        queryParams['min_price'] = _minPrice.toString();
      }
      if (_maxPrice != null) {
        queryParams['max_price'] = _maxPrice.toString();
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/search',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        final data = resData['data'] ?? {};
        setState(() {
          _products = data['products'] ?? [];
          _users = data['users'] ?? [];
          _searchHistory = data['history'] ?? [];
        });

        if (recordHistory && query.isNotEmpty) {
          _saveSearchHistory(query);
        }
      }
    } catch (e) {
      debugPrint('Error executing search: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSearchHistory(String keyword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/search'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'keyword': keyword}),
      );
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }

  Future<void> _deleteHistoryItem(int id) async {
    setState(() {
      _searchHistory.removeWhere((item) => item['id'] == id);
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/search/$id'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
    } catch (e) {
      debugPrint('Error deleting history item: $e');
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Rp 0';
    final str = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  // Filter Bottom Sheets
  void _showBrandPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _BrandMultiSelectSheet(
          allBrands: _allBrands,
          initialSelected: _selectedBrands,
          onApply: (selected) {
            setState(() {
              _selectedBrands.clear();
              _selectedBrands.addAll(selected);
            });
            _performSearch();
          },
        );
      },
    );
  }

  void _showHargaPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _HargaRangeSheet(
          initialMin: _minPrice,
          initialMax: _maxPrice,
          onApply: (min, max) {
            setState(() {
              _minPrice = min;
              _maxPrice = max;
            });
            _performSearch();
          },
        );
      },
    );
  }

  void _showKondisiPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _KondisiMultiSelectSheet(
          allConditions: _allConditions,
          initialSelected: _selectedConditions,
          onApply: (selected) {
            setState(() {
              _selectedConditions.clear();
              _selectedConditions.addAll(selected);
            });
            _performSearch();
          },
        );
      },
    );
  }

  void _showUkuranPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _UkuranMultiSelectSheet(
          allSizes: _allSizes,
          initialSelected: _selectedSizes,
          onApply: (selected) {
            setState(() {
              _selectedSizes.clear();
              _selectedSizes.addAll(selected);
            });
            _performSearch();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section (Search Input + Batal)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF972B31),
                    const Color(0xFFEB8C8C).withValues(alpha: 0.07),
                  ],
                ),
              ),
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 8.0,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFDEDEDE),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 14),
                              const Icon(
                                Icons.search,
                                color: Color(0xFF74070E),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    hintText: 'Cari produk atau akun...',
                                    hintStyle: GoogleFonts.inter(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                      color: Colors.grey.shade400,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 11,
                                    ),
                                  ),
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  onSubmitted: (val) {
                                    _performSearch(recordHistory: true);
                                  },
                                ),
                              ),
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    size: 18,
                                    color: Colors.black54,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _performSearch();
                                  },
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
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF74070E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Filter chips list
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilterChip(
                          label: 'Brand',
                          isSelected: _selectedBrands.isNotEmpty,
                          count: _selectedBrands.length,
                          onTap: _showBrandPicker,
                        ),
                        _buildFilterChip(
                          label: 'Harga',
                          isSelected: _minPrice != null || _maxPrice != null,
                          onTap: _showHargaPicker,
                        ),
                        _buildFilterChip(
                          label: 'Kondisi',
                          isSelected: _selectedConditions.isNotEmpty,
                          count: _selectedConditions.length,
                          onTap: _showKondisiPicker,
                        ),
                        _buildFilterChip(
                          label: 'Ukuran',
                          isSelected: _selectedSizes.isNotEmpty,
                          count: _selectedSizes.length,
                          onTap: _showUkuranPicker,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Content Section: loading / history / results
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF74070E),
                        ),
                      ),
                    )
                  : !_hasSearched
                  ? _buildHistorySection()
                  : _buildResultsSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    int count = 0,
    required VoidCallback onTap,
  }) {
    final chipLabel = isSelected && count > 0 ? '$label ($count)' : label;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF74070E) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF74070E), width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                chipLabel,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF74070E),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 14,
                color: isSelected ? Colors.white : const Color(0xFF74070E),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (_searchHistory.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    // Delete all
                    for (var item in _searchHistory) {
                      _deleteHistoryItem(item['id']);
                    }
                  },
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.black54,
                    size: 22,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),
          Expanded(
            child: _searchHistory.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada riwayat pencarian.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchHistory.length,
                    itemBuilder: (context, index) {
                      final item = _searchHistory[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                _searchController.text = item['keyword'] ?? '';
                                _performSearch(recordHistory: true);
                              },
                              child: Text(
                                item['keyword'] ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _deleteHistoryItem(item['id']),
                              child: const Icon(
                                Icons.close,
                                color: Colors.black38,
                                size: 18,
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
    );
  }

  Widget _buildResultsSection() {
    return Column(
      children: [
        // Custom elegant sliding tab bar
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF74070E),
            indicatorWeight: 3,
            labelColor: const Color(0xFF74070E),
            unselectedLabelColor: Colors.grey.shade500,
            labelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'Barang'),
              Tab(text: 'Akun'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildProductsGrid(), _buildUsersList()],
          ),
        ),
      ],
    );
  }

  Widget _buildProductsGrid() {
    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Produk tidak ditemukan.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final prod = _products[index];

        String brand = 'Tanpa Brand';
        String size = '-';
        String condition = '-';

        final List<dynamic> cats = prod['categories'] is String
            ? jsonDecode(prod['categories'])
            : (prod['categories'] ?? []);
        for (var cat in cats) {
          final s = cat.toString();
          if (s.startsWith('Brand:')) {
            brand = s.replaceAll('Brand:', '').trim();
          } else if (s.startsWith('Kondisi:')) {
            condition = s.replaceAll('Kondisi:', '').trim();
          } else if (s.contains('(') && s.contains(')')) {
            final start = s.indexOf('(');
            final end = s.indexOf(')');
            size = s.substring(start + 1, end);
          }
        }

        final List<dynamic> images = prod['image_paths'] is String
            ? jsonDecode(prod['image_paths'])
            : (prod['image_paths'] ?? []);
        final String imageUrl = images.isNotEmpty
            ? '${ApiConfig.host}${images[0]}'
            : '';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(product: prod),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDEDEDE), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image container with size indicator overlay
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(11),
                    ),
                    child: Stack(
                      children: [
                        imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade100,
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        color: Colors.black26,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    color: Colors.black26,
                                  ),
                                ),
                              ),
                        if (size.isNotEmpty)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF74070E),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                size,
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prod['title'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        brand,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$size | $condition',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatPrice(prod['price']),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF74070E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUsersList() {
    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Akun tidak ditemukan.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
      itemBuilder: (context, index) {
        final user = _users[index];
        final String fullName = user['full_name'] ?? 'Pengguna';
        final String username = user['username'] ?? '';
        final String profilePic = user['profile_picture_url'] ?? '';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 6,
            horizontal: 4,
          ),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFF9EFEF),
            backgroundImage: profilePic.isNotEmpty
                ? NetworkImage('${ApiConfig.host}/uploads/profiles/$profilePic')
                : null,
            child: profilePic.isEmpty
                ? Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : 'P',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF74070E),
                    ),
                  )
                : null,
          ),
          title: Text(
            fullName,
            style: GoogleFonts.playfairDisplay(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            username.isNotEmpty ? '@$username' : '',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Colors.black38,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SellerProfilePage(
                  sellerId: user['id'],
                  sellerName: user['username'] ?? user['full_name'],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ----------------------------------------------------
// Custom Bottom Sheet Widget Implementations
// ----------------------------------------------------

class _BrandMultiSelectSheet extends StatefulWidget {
  final List<String> allBrands;
  final Set<String> initialSelected;
  final Function(Set<String>) onApply;

  const _BrandMultiSelectSheet({
    required this.allBrands,
    required this.initialSelected,
    required this.onApply,
  });

  @override
  State<_BrandMultiSelectSheet> createState() => _BrandMultiSelectSheetState();
}

class _BrandMultiSelectSheetState extends State<_BrandMultiSelectSheet> {
  final Set<String> _localSelected = {};
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredBrands = [];

  @override
  void initState() {
    super.initState();
    _localSelected.addAll(widget.initialSelected);
    _filteredBrands = List.from(widget.allBrands);
    _filteredBrands.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterBrands(String q) {
    setState(() {
      if (q.trim().isEmpty) {
        _filteredBrands = List.from(widget.allBrands);
      } else {
        _filteredBrands = widget.allBrands
            .where((b) => b.toLowerCase().contains(q.toLowerCase()))
            .toList();
      }
      _filteredBrands.sort(
        (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      height: MediaQuery.of(context).size.height * 0.82,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // Custom Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF74070E),
                    size: 24,
                  ),
                ),
                Text(
                  'Brand',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _localSelected.clear();
                    });
                  },
                  child: Text(
                    'Reset',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF74070E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: Colors.black54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterBrands,
                      cursorColor: const Color(0xFF74070E),
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Cari brand...',
                        hintStyle: GoogleFonts.inter(
                          color: Colors.black38,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Brands Checklist List
          Expanded(
            child: _filteredBrands.isEmpty
                ? Center(
                    child: Text(
                      'Brand tidak ditemukan.',
                      style: GoogleFonts.inter(color: Colors.black38),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredBrands.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: Color(0xFFF9F9F9)),
                    itemBuilder: (context, index) {
                      final brand = _filteredBrands[index];
                      final isChecked = _localSelected.contains(brand);

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          brand,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        trailing: Checkbox(
                          activeColor: const Color(0xFF74070E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          value: isChecked,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _localSelected.add(brand);
                              } else {
                                _localSelected.remove(brand);
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),

          // Bottom CTA button
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF74070E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () {
                  widget.onApply(_localSelected);
                  Navigator.pop(context);
                },
                child: Text(
                  'Pilih',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HargaRangeSheet extends StatefulWidget {
  final int? initialMin;
  final int? initialMax;
  final Function(int?, int?) onApply;

  const _HargaRangeSheet({
    required this.initialMin,
    required this.initialMax,
    required this.onApply,
  });

  @override
  State<_HargaRangeSheet> createState() => _HargaRangeSheetState();
}

class _HargaRangeSheetState extends State<_HargaRangeSheet> {
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialMin != null) {
      _minController.text = widget.initialMin.toString();
    }
    if (widget.initialMax != null) {
      _maxController.text = widget.initialMax.toString();
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFF74070E),
                    size: 24,
                  ),
                ),
                Text(
                  'Rentang Harga',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _minController.clear();
                    _maxController.clear();
                  },
                  child: Text(
                    'Reset',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF74070E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Harga Min',
                      labelStyle: GoogleFonts.inter(
                        color: Colors.black45,
                        fontSize: 13,
                      ),
                      prefixText: 'Rp ',
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF74070E)),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _maxController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Harga Max',
                      labelStyle: GoogleFonts.inter(
                        color: Colors.black45,
                        fontSize: 13,
                      ),
                      prefixText: 'Rp ',
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF74070E)),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF74070E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () {
                  final min = int.tryParse(_minController.text.trim());
                  final max = int.tryParse(_maxController.text.trim());
                  widget.onApply(min, max);
                  Navigator.pop(context);
                },
                child: Text(
                  'Terapkan',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KondisiMultiSelectSheet extends StatefulWidget {
  final List<String> allConditions;
  final Set<String> initialSelected;
  final Function(Set<String>) onApply;

  const _KondisiMultiSelectSheet({
    required this.allConditions,
    required this.initialSelected,
    required this.onApply,
  });

  @override
  State<_KondisiMultiSelectSheet> createState() =>
      _KondisiMultiSelectSheetState();
}

class _KondisiMultiSelectSheetState extends State<_KondisiMultiSelectSheet> {
  final Set<String> _localSelected = {};

  @override
  void initState() {
    super.initState();
    _localSelected.addAll(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      height: MediaQuery.of(context).size.height * 0.55,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFF74070E),
                    size: 24,
                  ),
                ),
                Text(
                  'Kondisi',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _localSelected.clear();
                    });
                  },
                  child: Text(
                    'Reset',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF74070E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: widget.allConditions.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: Color(0xFFF9F9F9)),
              itemBuilder: (context, index) {
                final cond = widget.allConditions[index];
                final isChecked = _localSelected.contains(cond);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    cond,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  trailing: Checkbox(
                    activeColor: const Color(0xFF74070E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    value: isChecked,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _localSelected.add(cond);
                        } else {
                          _localSelected.remove(cond);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF74070E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () {
                  widget.onApply(_localSelected);
                  Navigator.pop(context);
                },
                child: Text(
                  'Pilih',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UkuranMultiSelectSheet extends StatefulWidget {
  final List<String> allSizes;
  final Set<String> initialSelected;
  final Function(Set<String>) onApply;

  const _UkuranMultiSelectSheet({
    required this.allSizes,
    required this.initialSelected,
    required this.onApply,
  });

  @override
  State<_UkuranMultiSelectSheet> createState() =>
      _UkuranMultiSelectSheetState();
}

class _UkuranMultiSelectSheetState extends State<_UkuranMultiSelectSheet> {
  final Set<String> _localSelected = {};

  @override
  void initState() {
    super.initState();
    _localSelected.addAll(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      height: MediaQuery.of(context).size.height * 0.58,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFF74070E),
                    size: 24,
                  ),
                ),
                Text(
                  'Ukuran',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _localSelected.clear();
                    });
                  },
                  child: Text(
                    'Reset',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF74070E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: widget.allSizes.map((size) {
                  final isSelected = _localSelected.contains(size);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _localSelected.remove(size);
                        } else {
                          _localSelected.add(size);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
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
                      child: Text(
                        size,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF74070E),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF74070E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () {
                  widget.onApply(_localSelected);
                  Navigator.pop(context);
                },
                child: Text(
                  'Pilih',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
