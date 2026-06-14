import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class MapPickerPage extends StatefulWidget {
  final String? initialAddress;
  const MapPickerPage({super.key, this.initialAddress});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pinAnimController;
  late final MapController _mapController;

  String _searchQuery = '';
  bool _isSearching = false;
  bool _isLoading = false;
  String _currentAddress =
      'Jl. Jenderal Sudirman No. 45, Senayan, Kebayoran Baru, Jakarta Selatan, DKI Jakarta';
  String _currentDetails = 'Kebayoran Baru, Jakarta Selatan';
  double _lat = -6.2241;
  double _lng = 106.8016;

  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pinAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    final hasInitialAddress =
        widget.initialAddress != null &&
        widget.initialAddress!.isNotEmpty &&
        !widget.initialAddress!.toLowerCase().contains('belum diatur');

    if (hasInitialAddress) {
      _currentAddress = widget.initialAddress!;
      _currentDetails = 'Mencari detail alamat...';
      _geocodeInitialAddress(widget.initialAddress!);
    } else {
      _getUserLocationFromIP();
    }
  }

  Future<void> _getUserLocationFromIP() async {
    try {
      final url = Uri.parse('http://ip-api.com/json');
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final lat = data['lat'] as double;
          final lng = data['lon'] as double;
          final city = data['city'] ?? 'Lokasi Saya';
          setState(() {
            _lat = lat;
            _lng = lng;
            _currentAddress = data['city'] != null
                ? '${data['city']}, ${data['regionName'] ?? ""}, ${data['country'] ?? ""}'
                : 'Lokasi Saya';
            _currentDetails = city;
          });
          Future.delayed(const Duration(milliseconds: 300), () {
            _mapController.move(LatLng(lat, lng), 16.0);
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error getting location from IP: $e');
    }
    _reverseGeocode(_lat, _lng);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pinAnimController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // Geocode initial address text to get coordinates if it exists
  Future<void> _geocodeInitialAddress(String address) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1&addressdetails=1&countrycodes=id',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'KepakeLagi/1.0'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final item = data[0];
          final lat = double.parse(item['lat']);
          final lng = double.parse(item['lon']);
          final addressData = item['address'] ?? {};
          final details =
              addressData['city'] ??
              addressData['regency'] ??
              addressData['state'] ??
              'Detail Lokasi';

          setState(() {
            _lat = lat;
            _lng = lng;
            _currentAddress = item['display_name'];
            _currentDetails = details;
          });

          // Wait a brief frame for MapController to be fully ready
          Future.delayed(const Duration(milliseconds: 300), () {
            _mapController.move(LatLng(lat, lng), 16.0);
          });
        } else {
          _getUserLocationFromIP();
        }
      } else {
        _getUserLocationFromIP();
      }
    } catch (e) {
      debugPrint('Error geocoding initial: $e');
      _getUserLocationFromIP();
    }
  }

  // Debounced search to prevent hitting API limits
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _searchLocation(query);
    });
  }

  // Search real-world location via Nominatim API
  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _isLoading = true;
    });
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1&countrycodes=id',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'KepakeLagi/1.0'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _searchResults = data.map((item) {
            final addressData = item['address'] ?? {};
            final details =
                addressData['city'] ??
                addressData['regency'] ??
                addressData['state'] ??
                'Detail Lokasi';
            return {
              'name': item['display_name'].toString().split(',')[0],
              'details': details,
              'address': item['display_name'],
              'lat': double.parse(item['lat']),
              'lng': double.parse(item['lon']),
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching location: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Handle suggestion selection
  void _selectLocation(Map<String, dynamic> loc) {
    setState(() {
      _currentAddress = loc['address'];
      _currentDetails = loc['details'];
      _lat = loc['lat'];
      _lng = loc['lng'];
      _searchResults = [];
      _isSearching = false;
    });
    FocusScope.of(context).unfocus();
    _mapController.move(LatLng(_lat, _lng), 16.0);
    _pinAnimController
        .forward(from: 0.0)
        .then((_) => _pinAnimController.reverse());
  }

  // Reverse geocode lat/lng to real address via Nominatim API
  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'KepakeLagi/1.0'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final displayName = data['display_name'] ?? 'Alamat tidak ditemukan';
        final addressData = data['address'] ?? {};
        final details =
            addressData['city'] ??
            addressData['regency'] ??
            addressData['state'] ??
            'Detail Lokasi';

        setState(() {
          _currentAddress = displayName;
          _currentDetails = details;
        });
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // Real-World OpenStreetMap Widget
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(_lat, _lng),
              initialZoom: 15.0,
              minZoom: 3.0,
              maxZoom: 19.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _lat = position.center.latitude;
                    _lng = position.center.longitude;
                  });
                }
              },
              onMapEvent: (event) {
                if (event is MapEventMoveStart) {
                  _pinAnimController.forward();
                } else if (event is MapEventMoveEnd) {
                  _pinAnimController.reverse();
                  _reverseGeocode(_lat, _lng);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.nobel.kepakelagi',
              ),
            ],
          ),

          // Central Static Bouncing Marker Pin Overlay
          Center(
            child: AnimatedBuilder(
              animation: _pinAnimController,
              builder: (context, child) {
                final double bounce = _pinAnimController.value * -25.0;
                return Transform.translate(
                  offset: Offset(0, bounce - 20), // offset by pin tip height
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Pin Shadow
                      Opacity(
                        opacity: 1.0 - _pinAnimController.value * 0.5,
                        child: Container(
                          width: 22,
                          height: 6,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Real Premium Marker Icon
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFF74070E),
                        size: 48,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Map Overlay Buttons (Zoom In/Out + GPS)
          Positioned(
            right: 16,
            bottom: 240,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Zoom In
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(LatLng(_lat, _lng), zoom + 1);
                  },
                  child: const Icon(Icons.add, color: Color(0xFF74070E)),
                ),
                const SizedBox(height: 8),
                // Zoom Out
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(LatLng(_lat, _lng), zoom - 1);
                  },
                  child: const Icon(Icons.remove, color: Color(0xFF74070E)),
                ),
                const SizedBox(height: 12),
                // Current GPS Location Reset
                FloatingActionButton(
                  heroTag: 'gps_center',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () {
                    _getUserLocationFromIP().then((_) {
                      _pinAnimController
                          .forward(from: 0.0)
                          .then((_) => _pinAnimController.reverse());
                    });
                  },
                  child: const Icon(
                    Icons.my_location,
                    color: Color(0xFF74070E),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: _onSearchChanged,
                      controller: TextEditingController.fromValue(
                        TextEditingValue(
                          text: _searchQuery,
                          selection: TextSelection.collapsed(
                            offset: _searchQuery.length,
                          ),
                        ),
                      ),
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Cari kota, jalan, atau perumahan...',
                        hintStyle: GoogleFonts.inter(
                          color: Colors.black45,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF74070E),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.black54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _searchResults = [];
                                    _isSearching = false;
                                  });
                                },
                              )
                            : null,
                      ),
                    ),
                  ),

                  // Search Suggestions List
                  if (_isSearching)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF74070E),
                                  ),
                                ),
                              ),
                            )
                          : _searchResults.isNotEmpty
                          ? ListView.separated(
                              shrinkWrap: true,
                              itemCount: _searchResults.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(
                                    height: 1,
                                    color: Color(0xFFEEEEEE),
                                  ),
                              itemBuilder: (context, index) {
                                final loc = _searchResults[index];
                                return ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF9EAEA),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Color(0xFF74070E),
                                      size: 18,
                                    ),
                                  ),
                                  title: Text(
                                    loc['name'],
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.black,
                                    ),
                                  ),
                                  subtitle: Text(
                                    loc['details'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  onTap: () => _selectLocation(loc),
                                );
                              },
                            )
                          : Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Lokasi tidak ditemukan',
                                  style: GoogleFonts.inter(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                    ),
                ],
              ),
            ),
          ),

          // Top Back Button
          Positioned(
            top: 16 + MediaQuery.of(context).padding.top,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: Color(0xFF74070E)),
              ),
            ),
          ),

          // Bottom Confirmation Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF9EAEA),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.pin_drop,
                          color: Color(0xFF74070E),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lokasi Terpilih',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF74070E),
                              ),
                            ),
                            Text(
                              _currentDetails,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lat: ${_lat.toStringAsFixed(6)}, Lng: ${_lng.toStringAsFixed(6)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
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
                        Navigator.pop(context, _currentAddress);
                      },
                      child: Text(
                        'Konfirmasi Lokasi',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
