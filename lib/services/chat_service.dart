import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:web_socket_channel/io.dart';
import '../models/message_model.dart';
import 'auth_service.dart';

class ChatService {
  final String baseUrl = 'http://your-server-ip/api';
  final String wsUrl = 'ws://your-server-ip:6001/app/chat';
  final _logger = Logger();
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getMessages(int fromUserId, int toUserId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/messages/$fromUserId/$toUserId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      _logger.d('Get messages response status: ${response.statusCode}');
      _logger.d('Get messages response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<Message> messages = [];

        if (data['messages'] != null && data['messages'] is List) {
          for (var item in data['messages']) {
            if (item is Map<String, dynamic>) {
              final message = Message.fromJson(item);
              if (message.isValid) {
                messages.add(message);
              }
            }
          }
        }

        return {
          'success': true,
          'messages': messages,
        };
      }

      return {
        'success': false,
        'message': 'Gagal mengambil pesan',
      };
    } catch (e, stackTrace) {
      _logger.e('Error getting messages', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat mengambil pesan',
      };
    }
  }

  Future<Map<String, dynamic>> sendMessage(
      int fromUserId, int toUserId, String message) async {
    try {
      final token = await _authService.getToken();
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['message_data'] is Map<String, dynamic>) {
          final newMessage = Message.fromJson(data['message_data']);
          if (newMessage.isValid) {
            return {
              'success': true,
              'message': 'Pesan terkirim',
              'message_data': newMessage,
            };
          }
        }
      }

      return {
        'success': false,
        'message': 'Gagal mengirim pesan',
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
    } catch (e, stackTrace) {
      _logger.e('Error connecting to WebSocket',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  void handleWebSocketMessage(
    dynamic message,
    int currentUserId,
    int otherUserId,
    Function(Message) onNewMessage,
  ) {
    try {
      final data = jsonDecode(message);
      if (data['event'] == 'chat.message') {
        final messageData = data['data'];
        final newMessage = Message.fromJson(messageData);

        // Periksa apakah pesan valid dan relevan untuk percakapan ini
        if (newMessage.isValid &&
            ((newMessage.fromUserId == currentUserId &&
                    newMessage.toUserId == otherUserId) ||
                (newMessage.fromUserId == otherUserId &&
                    newMessage.toUserId == currentUserId))) {
          onNewMessage(newMessage);
        }
      }
    } catch (e, stackTrace) {
      _logger.e('Error handling WebSocket message',
          error: e, stackTrace: stackTrace);
    }
  }

  void sendWebSocketMessage(
    IOWebSocketChannel channel,
    Message message,
  ) {
    try {
      if (message.isValid) {
        final data = {
          'event': 'chat.message',
          'data': message.toJson(),
        };
        channel.sink.add(jsonEncode(data));
      }
    } catch (e, stackTrace) {
      _logger.e('Error sending WebSocket message',
          error: e, stackTrace: stackTrace);
    }
  }
}
