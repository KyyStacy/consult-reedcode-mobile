import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../config/api_config.dart';

class MidtransConfig {
  final String clientKey;
  final String snapUrl;
  final bool isProduction;

  MidtransConfig({
    required this.clientKey,
    required this.snapUrl,
    required this.isProduction,
  });

  factory MidtransConfig.fromJson(Map<String, dynamic> json) {
    return MidtransConfig(
      clientKey: json['client_key'],
      snapUrl: json['snap_url'],
      isProduction: json['is_production'],
    );
  }
}

class MidtransConfigService {
  static final Logger _logger = Logger();
  static MidtransConfig? _config;

  static Future<MidtransConfig> getConfig() async {
    if (_config != null) return _config!;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/transaction/midtrans-config'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _config = MidtransConfig.fromJson(data['data']);
        return _config!;
      } else {
        throw Exception('Gagal mengambil konfigurasi Midtrans');
      }
    } catch (e) {
      _logger.e('Error getting Midtrans config', error: e);
      throw Exception('Terjadi kesalahan saat mengambil konfigurasi Midtrans');
    }
  }
}
