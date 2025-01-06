import 'package:intl/intl.dart';

class Message {
  final int id;
  final int fromUserId;
  final int toUserId;
  final String message;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.message,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? 0,
      fromUserId: json['from_user_id'] ?? 0,
      toUserId: json['to_user_id'] ?? 0,
      message: json['message'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedTime {
    return DateFormat('HH:mm').format(createdAt.toLocal());
  }

  String get formattedDate {
    return DateFormat('dd MMM yyyy').format(createdAt.toLocal());
  }

  bool get isValid =>
      id > 0 && fromUserId > 0 && toUserId > 0 && message.isNotEmpty;
}
