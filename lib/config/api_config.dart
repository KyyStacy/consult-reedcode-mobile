import 'dart:io';
import 'package:flutter/foundation.dart';

/// Konfigurasi API untuk aplikasi mobile
/// 
/// Menggunakan environment variable jika tersedia, atau fallback ke default
/// Otomatis mendeteksi platform dan menggunakan URL yang sesuai:
/// - Android Emulator: 10.0.2.2 (localhost dari emulator)
/// - iOS Simulator: localhost
/// - Web: localhost
/// - Physical Device: gunakan IP address host machine
class ApiConfig {
  // Base URL untuk API Laravel
  // Default: http://localhost:8000 (untuk development)
  // Production: sesuaikan dengan URL backend Anda
  static const String defaultBaseUrl = 'http://localhost:8000';
  
  // URL untuk Android Emulator (10.0.2.2 adalah alias untuk localhost host machine)
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8000';

  // Base URL yang digunakan (bisa di-override dari environment variable)
  // 
  // Cara penggunaan:
  // 1. Development: Otomatis mendeteksi platform
  // 2. Production dengan environment variable:
  //    flutter run --dart-define=API_BASE_URL=http://your-server.com
  // 3. Production dengan hardcode: Uncomment baris return di bawah
  static String get baseUrl {
    // Cek environment variable terlebih dahulu
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // Deteksi platform dan gunakan URL yang sesuai
    if (kIsWeb) {
      // Web: gunakan localhost
      return defaultBaseUrl;
    } else if (Platform.isAndroid) {
      // Android Emulator: gunakan 10.0.2.2 (localhost dari emulator)
      // 
      // CATATAN PENTING:
      // - Untuk Android Emulator: 10.0.2.2 otomatis mengarah ke localhost host machine
      // - Untuk Physical Device: Anda perlu menggunakan IP address host machine
      //   Contoh: return 'http://192.168.1.100:8000';
      //   Untuk mendapatkan IP: ipconfig (Windows) atau ifconfig (Mac/Linux)
      return androidEmulatorBaseUrl;
    } else if (Platform.isIOS) {
      // iOS Simulator: gunakan localhost
      // 
      // CATATAN PENTING:
      // - Untuk iOS Simulator: localhost bekerja dengan baik
      // - Untuk Physical Device: Anda perlu menggunakan IP address host machine
      //   Contoh: return 'http://192.168.1.100:8000';
      //   Untuk mendapatkan IP: ipconfig (Windows) atau ifconfig (Mac/Linux)
      return defaultBaseUrl;
    } else {
      // Desktop (Windows, macOS, Linux): gunakan localhost
      return defaultBaseUrl;
    }

    // Production URL (uncomment jika sudah deploy dan tidak menggunakan environment variable)
    // return 'http://your-server-ip';
  }

  // API endpoint base
  static String get apiBaseUrl => '$baseUrl/api';

  // WebSocket URL untuk real-time chat
  // Default menggunakan port 6001 (Laravel Echo Server)
  static String get wsBaseUrl {
    // Extract host dari baseUrl
    final uri = Uri.parse(baseUrl);
    final host = uri.host;

    // Untuk WebSocket, gunakan ws:// atau wss://
    final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    // Port WebSocket biasanya berbeda (6001 untuk Laravel Echo Server)
    // Gunakan host yang sama dengan baseUrl untuk konsistensi
    return '$wsScheme://$host:6001';
  }

  // WebSocket endpoint untuk chat
  static String get wsChatUrl => '$wsBaseUrl/app/chat';

  // Merchant base URL untuk Midtrans (jika diperlukan)
  static String get merchantBaseUrl => baseUrl;

  // Storage URL untuk mengakses file yang di-upload
  static String get storageUrl => '$baseUrl/storage';

  // Helper untuk mendapatkan URL foto
  static String getPhotoUrl(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) {
      return '';
    }
    // Jika sudah full URL, return as is
    if (photoPath.startsWith('http://') || photoPath.startsWith('https://')) {
      return photoPath;
    }
    // Jika relative path, tambahkan storage URL
    return '$storageUrl/$photoPath';
  }
}
