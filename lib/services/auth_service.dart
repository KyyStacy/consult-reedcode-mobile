import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/io.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/message_model.dart';
import '../models/psychologist_model.dart';

class AuthService {
  final String baseUrl = 'http://your-server-ip/api';
  final String wsUrl = 'ws://your-server-ip:6001/app/chat';
  final _logger = Logger();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final user = User.fromJson(data['data']['user']);

        // Validasi role
        if (user.isAdmin || user.isPsychologist) {
          return {
            'success': false,
            'message':
                'Aplikasi mobile hanya untuk pengguna biasa. Silakan gunakan website untuk admin dan psikolog.',
          };
        }

        // Simpan token dan user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['data']['token']);
        await prefs.setString('user', jsonEncode(data['data']['user']));

        return {
          'success': true,
          'message': data['message'],
          'user': user,
        };
      } else {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Terjadi kesalahan',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  Future<bool> logout() async {
    try {
      final token = await getToken();
      _logger.d('Token for logout: $token');

      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _logger.d('Logout response status: ${response.statusCode}');
      _logger.d('Logout response body: ${response.body}');

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear(); // Hapus semua data lokal
        _logger.i('Logout successful, local data cleared');
        return true;
      }
      _logger.w('Logout failed with status code: ${response.statusCode}');
      return false;
    } catch (e) {
      _logger.e('Error during logout',
          error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      _logger.d(
          'Retrieved token from storage: ${token != null ? 'exists' : 'null'}');
      return token;
    } catch (e, stackTrace) {
      _logger.e('Error retrieving token', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      return User.fromJson(json.decode(userStr));
    }
    return null;
  }

  Future<Map<String, dynamic>> updateProfile(String name, String email) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/profile/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
        }),
      );

      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Update local user data dan token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data['data']['user']));
        await prefs.setString(
            'token', data['data']['token']); // Simpan token baru

        return {
          'success': true,
          'message': data['message'],
          'user': User.fromJson(data['data']['user']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal memperbarui profil',
        };
      }
    } catch (e) {
      _logger.e('Error updating profile',
          error: e, stackTrace: StackTrace.current);
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updatePhoto(File photo) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan',
        };
      }

      // Buat request multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/profile/update-photo'),
      );

      // Tambahkan header
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Tambahkan file foto
      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          photo.path,
        ),
      );

      // Kirim request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      _logger.d('Update photo response: ${response.body}');
      _logger.d('Update photo status code: ${response.statusCode}');

      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Update user data di local storage
        final userData = data['data']['user'];
        _logger.d('User data after photo update: $userData');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(userData));

        return {
          'success': true,
          'message': data['message'],
          'user': User.fromJson(userData),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengupdate foto profil',
        };
      }
    } catch (e) {
      _logger.e('Error during photo update',
          error: e, stackTrace: StackTrace.current);
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  Future<Map<String, dynamic>> changePassword(String currentPassword,
      String newPassword, String confirmPassword) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/profile/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );

      final Map<String, dynamic> data = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteAccount(String password) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/profile/delete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'password': password,
        }),
      );

      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear(); // Hapus semua data lokal
      }

      return {
        'success': response.statusCode == 200,
        'message': data['message'],
      };
    } catch (e) {
      _logger.e('Error deleting account',
          error: e, stackTrace: StackTrace.current);
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  Future<Map<String, dynamic>> register(String name, String email,
      String password, String passwordConfirmation) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'role': 'user',
        }),
      );

      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 201) {
        // Simpan token dan user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['data']['token']);
        await prefs.setString('user', jsonEncode(data['data']['user']));

        return {
          'success': true,
          'message': data['message'],
          'user': User.fromJson(data['data']['user']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mendaftar',
        };
      }
    } catch (e) {
      _logger.e('Error during registration',
          error: e, stackTrace: StackTrace.current);
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getTransactionHistory() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/transactions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      // Pastikan response valid
      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Response kosong',
        };
      }

      // Parse response ke JSON string terlebih dahulu
      final jsonString = response.body;
      final decodedData = jsonDecode(jsonString) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        if (decodedData['data'] == null) {
          return {
            'success': true,
            'transactions': <Transaction>[],
          };
        }

        // Konversi data ke JSON string lagi untuk memastikan format yang benar
        final List<dynamic> rawTransactions =
            decodedData['data'] as List<dynamic>;
        final List<Transaction> transactions = rawTransactions.map((item) {
          final jsonStr = jsonEncode(item);
          final Map<String, dynamic> transactionMap = jsonDecode(jsonStr);
          return Transaction.fromJson(transactionMap);
        }).toList();

        return {
          'success': true,
          'transactions': transactions,
        };
      } else {
        return {
          'success': false,
          'message': decodedData['message'] ?? 'Gagal mengambil data riwayat',
        };
      }
    } catch (e, stackTrace) {
      _logger.e('Error getting transaction history',
          error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    try {
      final token = await getToken();
      _logger.d('Token for headers: $token');

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan atau kosong');
      }

      return {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
    } catch (e, stackTrace) {
      _logger.e('Error getting headers', error: e, stackTrace: stackTrace);
      throw Exception('Gagal mendapatkan headers: $e');
    }
  }

  Future<Map<String, dynamic>> getConversations() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        return {'success': false, 'message': 'User tidak ditemukan'};
      }

      // Ambil semua pesan yang terkait dengan user saat ini
      final response = await http.get(
        Uri.parse('$baseUrl/messages/conversations/${currentUser.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      _logger.d('Get conversations response status: ${response.statusCode}');
      _logger.d('Get conversations response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          // Data conversations sudah termasuk informasi user dan status transaksi
          return {
            'success': true,
            'conversations': data['conversations'] ?? [],
          };
        }
      }

      return {
        'success': false,
        'message': 'Gagal mengambil data percakapan',
      };
    } catch (e, stackTrace) {
      _logger.e('Error getting conversations',
          error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat mengambil data percakapan',
      };
    }
  }

  Future<Map<String, dynamic>> checkCanSendMessage(int toUserId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/transactions/check-status/$toUserId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'can_send': data['can_send'] ?? false,
          'message': data['message'],
        };
      }

      return {
        'success': false,
        'can_send': false,
        'message': 'Gagal memeriksa status transaksi',
      };
    } catch (e, stackTrace) {
      _logger.e('Error checking transaction status',
          error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'can_send': false,
        'message': 'Terjadi kesalahan saat memeriksa status transaksi',
      };
    }
  }

  Future<Map<String, dynamic>> getMessages(int fromUserId, int toUserId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/messages/$fromUserId/$toUserId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> messagesList = data['messages'] ?? [];
        final messages =
            messagesList.map((msg) => Message.fromJson(msg)).toList();
        return {
          'success': true,
          'messages': messages,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Gagal mengambil pesan',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  Future<Map<String, dynamic>> sendMessage(
      int fromUserId, int toUserId, String message) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from_user_id': fromUserId,
          'to_user_id': toUserId,
          'message': message,
        }),
      );

      _logger.d('Send message response status: ${response.statusCode}');
      _logger.d('Send message response body: ${response.body}');

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'message_data': data['message_data'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Gagal mengirim pesan',
      };
    } catch (e, stackTrace) {
      _logger.e('Error sending message', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat mengirim pesan',
      };
    }
  }

  IOWebSocketChannel? connectWebSocket() {
    try {
      return IOWebSocketChannel.connect(wsUrl);
    } catch (e) {
      _logger.e('Error connecting to WebSocket',
          error: e, stackTrace: StackTrace.current);
      return null;
    }
  }

  Future<Map<String, dynamic>> getPsychologists() async {
    try {
      _logger.d('Mencoba mengambil data psikolog...');
      final headers = await _getHeaders();
      _logger.d('Headers: $headers');

      final response = await http.get(
        Uri.parse('$baseUrl/psychologists'),
        headers: headers,
      );

      _logger.d('Status code: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.d('Decoded data: $data');

        if (data['success'] == true) {
          final List<dynamic> psychologistsJson = data['psychologists'];
          _logger.d('Raw psychologists data: $psychologistsJson');

          final psychologists = psychologistsJson.map((json) {
            // Ambil status transaksi dari data transaksi yang ada
            String transactionStatus = '';
            if (json['transaction'] != null) {
              transactionStatus = json['transaction']['status'] ?? '';
            }
            return Psychologist.fromJson({
              ...json,
              'transaction_status': transactionStatus,
            });
          }).toList();

          _logger.i('Berhasil mengambil ${psychologists.length} data psikolog');
          return {
            'success': true,
            'psychologists': psychologists,
          };
        }
      }

      final errorMessage = response.statusCode != 200
          ? 'Server error: ${response.statusCode}'
          : 'Gagal mengambil data psikolog';

      _logger.w('Gagal mengambil data: $errorMessage');
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e, stackTrace) {
      _logger.e('Error getting psychologists',
          error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
}
