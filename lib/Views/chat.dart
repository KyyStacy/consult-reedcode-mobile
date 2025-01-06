import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/auth_service.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class ChatPage extends StatefulWidget {
  final int toUserId;
  final String toUserName;
  final String? toUserPhoto;
  final bool showBackButton;

  const ChatPage({
    super.key,
    required this.toUserId,
    required this.toUserName,
    this.toUserPhoto,
    this.showBackButton = true,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _logger = Logger();

  List<Message> _messages = [];
  User? _currentUser;
  bool _isLoading = true;
  String? _error;
  bool _canSendMessage = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
    _startAutoRefresh();
  }

  Future<void> _initialize() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }

      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Sesi telah berakhir, silakan login kembali';
          });
        }
        return;
      }

      await Future.wait([
        _loadMessages(),
        _checkTransactionStatus(),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      _logger.e('Error initializing chat', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Terjadi kesalahan saat memuat chat';
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-initialize ketika widget di-rebuild
    _initialize();
  }

  Future<void> _checkTransactionStatus() async {
    try {
      final result = await _authService.checkCanSendMessage(widget.toUserId);
      if (mounted) {
        setState(() {
          _canSendMessage = result['can_send'] ?? false;
          _statusMessage = result['message'];
        });
      }
    } catch (e, stackTrace) {
      _logger.e('Error checking transaction status',
          error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _loadMessages() async {
    if (_currentUser == null) return;

    try {
      final result = await _authService.getMessages(
        _currentUser!.id,
        widget.toUserId,
      );

      if (mounted) {
        setState(() {
          if (result['success'] == true && result['messages'] != null) {
            _messages = List<Message>.from(result['messages']);
            _error = null;
          } else {
            _error = result['message'] ?? 'Gagal memuat pesan';
          }
        });
      }

      // Scroll ke pesan terakhir
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e, stackTrace) {
      _logger.e('Error loading messages', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _error = 'Terjadi kesalahan saat memuat pesan';
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    // Pastikan _currentUser tersedia
    if (_currentUser == null) {
      try {
        final user = await _authService.getCurrentUser();
        if (user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Sesi telah berakhir, silakan login kembali')),
            );
          }
          return;
        }
        _currentUser = user;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Terjadi kesalahan saat memuat data user')),
          );
        }
        return;
      }
    }

    final message = _messageController.text;
    _messageController.clear();

    try {
      final result = await _authService.sendMessage(
        _currentUser!.id,
        widget.toUserId,
        message,
      );

      if (result['success'] == true && result['message_data'] != null) {
        final messageData = result['message_data'] as Map<String, dynamic>;
        final newMessage = Message.fromJson(messageData);

        if (mounted) {
          setState(() {
            _messages.add(newMessage);
          });
          _scrollToBottom();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result['message'] ?? 'Gagal mengirim pesan')),
          );
          _messageController.text = message;
        }
      }
    } catch (e, stackTrace) {
      _logger.e('Error sending message', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Terjadi kesalahan saat mengirim pesan')),
        );
        _messageController.text = message;
      }
    }
  }

  Timer? _refreshTimer;

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadMessages();
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0097A7)),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.toUserPhoto != null
                  ? NetworkImage(
                      'http://10.0.2.2:8000/storage/photos/${widget.toUserPhoto}')
                  : const AssetImage('assets/images/default-photo.png')
                      as ImageProvider,
            ),
            const SizedBox(width: 8),
            Text(
              widget.toUserName,
              style: const TextStyle(
                color: Color(0xFF0097A7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    return Column(
      children: [
        if (!_canSendMessage)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.orange[100],
            child: Text(
              _statusMessage ?? 'Tidak dapat mengirim pesan',
              style: const TextStyle(color: Colors.deepOrange),
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final isMe = message.fromUserId == _currentUser?.id;

              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.cyan[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(message.message),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Ketik pesan...',
                    border: OutlineInputBorder(),
                  ),
                  enabled: _canSendMessage,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _canSendMessage ? _sendMessage : null,
                color: Colors.cyan,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
