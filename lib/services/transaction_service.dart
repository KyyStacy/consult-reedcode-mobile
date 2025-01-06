import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final String baseUrl = 'http://your-server-ip/api';
  final _logger = Logger();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> createTransaction(int psikologId) async {
    try {
      String? token = await _getToken();
      _logger.d('Token for transaction: $token');

      if (token == null || token.isEmpty) {
        _logger.e('Token tidak ditemukan atau kosong');
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.',
        };
      }

      _logger.d('Creating transaction for psikolog ID: $psikologId');

      final response = await http.post(
        Uri.parse('$baseUrl/transaction/create'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'psikolog_id': psikologId,
        }),
      );

      _logger.d('Transaction response status: ${response.statusCode}');
      _logger.d('Transaction response body: ${response.body}');

      if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        return {
          'success': false,
          'message': 'Sesi anda telah berakhir. Silakan login kembali.',
        };
      }

      // Cek apakah response body adalah HTML
      if (response.body.trim().startsWith('<!DOCTYPE html>')) {
        _logger.e('Server mengembalikan HTML alih-alih JSON');
        return {
          'success': false,
          'message': 'Terjadi kesalahan pada server. Silakan coba lagi nanti.',
        };
      }

      try {
        final data = jsonDecode(response.body);
        if (response.statusCode == 200 || response.statusCode == 201) {
          // Jika ada data di dalam response
          if (data['data'] != null) {
            return {
              'success': true,
              'data': {
                'snap_token': data['data']['snap_token'],
                'redirect_url': data['data']['redirect_url'],
                'transaction_status': data['data']['transaction_status'],
              }
            };
          }
          // Jika data langsung di root response
          return {
            'success': true,
            'data': {
              'snap_token': data['snap_token'],
              'redirect_url': data['redirect_url'],
              'transaction_status': data['transaction_status'],
            }
          };
        }

        return {
          'success': false,
          'message': data['message'] ?? 'Terjadi kesalahan pada server',
        };
      } catch (e) {
        _logger.e('Error parsing response', error: e);
        return {
          'success': false,
          'message': 'Terjadi kesalahan saat memproses response server',
        };
      }
    } catch (e) {
      _logger.e('Error creating transaction', error: e);
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  Future<List<Transaction>> getTransactions() async {
    try {
      String? token = await _getToken();
      _logger.d('Token for getting transactions: $token');

      if (token == null || token.isEmpty) {
        _logger.e('Token tidak ditemukan atau kosong');
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/transactions'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _logger.d('Get transactions response status: ${response.statusCode}');
      _logger.d('Get transactions response body: ${response.body}');

      if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        throw Exception('Sesi anda telah berakhir. Silakan login kembali.');
      }

      if (response.body.trim().startsWith('<!DOCTYPE html>')) {
        throw Exception(
            'Terjadi kesalahan pada server. Silakan coba lagi nanti.');
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final List<dynamic> transactions = data['data'];
        return transactions.map((json) => Transaction.fromJson(json)).toList();
      }

      throw Exception(data['message'] ?? 'Gagal memuat transaksi');
    } catch (e) {
      _logger.e('Error getting transactions', error: e);
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<bool> updateTransactionStatus(
      String idTransaksi, String status) async {
    try {
      String? token = await _getToken();
      _logger.d('Token for updating transaction: $token');

      if (token == null || token.isEmpty) {
        _logger.e('Token tidak ditemukan atau kosong');
        return false;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/transaction/$idTransaksi/status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': status,
        }),
      );

      _logger.d('Update transaction response status: ${response.statusCode}');
      _logger.d('Update transaction response body: ${response.body}');

      if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        return false;
      }

      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Error updating transaction status', error: e);
      return false;
    }
  }
}
