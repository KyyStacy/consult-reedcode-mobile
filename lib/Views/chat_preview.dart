import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'home.dart';
import 'riwayat.dart';
import 'profile.dart';
import 'chat.dart';

class ChatPreviewPage extends StatefulWidget {
  const ChatPreviewPage({super.key});

  @override
  State<ChatPreviewPage> createState() => _ChatPreviewPageState();
}

class _ChatPreviewPageState extends State<ChatPreviewPage> {
  final AuthService _authService = AuthService();
  final _logger = Logger();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _conversations = [];
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoRefresh();
  }

  Timer? _refreshTimer;

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
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
            _error = 'Sesi telah berakhir';
          });
        }
        return;
      }

      final result = await _authService.getConversations();
      _logger.d('Conversations result: $result');

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result['success'] == true && result['conversations'] != null) {
            _conversations =
                List<Map<String, dynamic>>.from(result['conversations']);
            _error = null;
          } else {
            _error = result['message'] ?? 'Gagal memuat data percakapan';
          }
        });
      }
    } catch (e, stackTrace) {
      _logger.e('Error loading conversations',
          error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Terjadi kesalahan saat memuat data';
        });
      }
    }
  }

  Map<String, dynamic>? _getUserData(Map<String, dynamic> conversation) {
    if (_currentUser == null) return null;

    try {
      final userData = _currentUser!.isPsychologist
          ? conversation['patient']
          : conversation['psychologist'];

      if (userData is Map<String, dynamic> &&
          userData.containsKey('id') &&
          userData.containsKey('name')) {
        return userData;
      }

      _logger.w('Invalid user data format: $userData');
      return null;
    } catch (e, stackTrace) {
      _logger.e('Error getting user data', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  void _navigateToChat(Map<String, dynamic> conversation) {
    if (_currentUser == null) return;

    final userData = _getUserData(conversation);
    if (userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data pengguna tidak valid')),
      );
      return;
    }

    final otherUser = User.fromJson(userData);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          toUserId: otherUser.id,
          toUserName: otherUser.name,
          toUserPhoto: otherUser.photo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesan',
            style: TextStyle(
                color: Color(0xFF0097A7), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Pesan'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        selectedItemColor: Colors.cyan,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacement(PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) =>
                  const HomeView(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ));
          } else if (index == 2) {
            Navigator.of(context).pushReplacement(PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) =>
                  const RiwayatKonsultasiPage(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ));
          } else if (index == 3) {
            Navigator.of(context).pushReplacement(PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) =>
                  const ProfilePage(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ));
          }
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_conversations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Belum ada percakapan',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Mulai konsultasi dengan psikolog',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        if (_currentUser == null) return const SizedBox.shrink();

        final userData = _getUserData(conversation);
        if (userData == null) return const SizedBox.shrink();

        final otherUser = User.fromJson(userData);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            onTap: () => _navigateToChat(conversation),
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: otherUser.photo != null
                  ? NetworkImage(
                      'http://10.0.2.2:8000/storage/photos/${otherUser.photo}')
                  : const AssetImage('assets/images/default-photo.png')
                      as ImageProvider,
            ),
            title: Text(
              otherUser.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation['last_message'] ?? '',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (conversation['status'] == 'Selesai')
                  Text(
                    'Chat telah diakhiri. Silakan buat transaksi baru untuk melanjutkan konsultasi.',
                    style: TextStyle(
                      color: Colors.red[300],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else if (conversation['status'] == 'Dibayar')
                  Text(
                    'Chat sedang berlangsung',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            isThreeLine: conversation['status'] == 'Selesai' ||
                conversation['status'] == 'Dibayar',
          ),
        );
      },
    );
  }
}
