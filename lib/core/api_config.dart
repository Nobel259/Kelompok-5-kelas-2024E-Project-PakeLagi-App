import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api'; // Chrome/Web
    } else if (Platform.isAndroid) {
      // Menggunakan IP Laptop Anda agar HP fisik bisa mengakses server XAMPP/Laravel
      return 'http://192.168.0.183:8000/api';
    } else {
      return 'http://localhost:8000/api'; // Windows/Lainnya
    }
  }

  static String get host {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'http://192.168.0.183:8000';
    } else {
      return 'http://localhost:8000';
    }
  }
}
