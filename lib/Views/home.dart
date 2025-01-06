import 'dart:async';
import 'package:flutter/material.dart';
import 'chat_preview.dart';
import 'riwayat.dart';
import 'profile.dart';
import 'list_psikolog.dart';
import 'quiz_test.dart';
import 'read_article.dart';
import 'chat.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late PageController _pageController;
  int _currentPage = 0;
  final List<String> images = [
    'assets/images/slide1.jpg',
    'assets/images/slide2.jpg',
    'assets/images/slide3.jpg',
  ];

  User? _user;
  List<Transaction> _transactions = [];
  final _authService = AuthService();
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: images.length * 1000);
    _currentPage = _pageController.initialPage % images.length;
    _loadUserData();
    _loadTransactions();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_isRefreshing) {
        _silentRefresh();
      }
    });
  }

  Future<void> _silentRefresh() async {
    _isRefreshing = true;
    try {
      final result = await _authService.getTransactionHistory();
      if (mounted && result['success']) {
        setState(() {
          _transactions = (result['transactions'] as List<Transaction>)
              .where((t) => t.status == 'Dibayar')
              .toList();
        });
      }
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isRefreshing = true;
    });
    try {
      final result = await _authService.getTransactionHistory();
      if (mounted && result['success']) {
        setState(() {
          _transactions = (result['transactions'] as List<Transaction>)
              .where((t) => t.status == 'Dibayar')
              .toList();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mind Mender',
            style: TextStyle(
                color: Color(0xFF0097A7), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 20),
              _buildImageSlider(),
              const SizedBox(height: 20),
              _buildFeatureButtons(context),
              const SizedBox(height: 20),
              _buildConsultationCard(),
              const SizedBox(height: 20),
              if (_transactions.isNotEmpty) _buildOngoingConsultationSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Pesan'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: 0,
        selectedItemColor: Colors.cyan,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).pushReplacement(PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) =>
                  const ChatPreviewPage(),
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

  Widget _buildWelcomeSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selamat Datang,',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            Text(_user?.name ?? 'Loading...',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        CircleAvatar(
          radius: 30,
          backgroundImage: _user?.photo != null
              ? NetworkImage(
                  'http://10.0.2.2:8000/storage/photos/${_user!.photo}')
              : const AssetImage('assets/images/default-photo.png')
                  as ImageProvider,
        ),
      ],
    );
  }

  Widget _buildImageSlider() {
    return Stack(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page % images.length;
              });
            },
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  images[index % images.length],
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
        Positioned.fill(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavigationArrow(Icons.arrow_back_ios, () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }),
              _buildNavigationArrow(Icons.arrow_forward_ios, () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }),
            ],
          ),
        ),
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationArrow(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildFeatureButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildFeatureButton(context, Icons.psychology, 'List Psikolog', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ListPsikologPage()),
          );
        }),
        _buildFeatureButton(context, Icons.quiz, 'Tes Kuis', () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const MentalHealthQuizPage()),
          );
        }),
        _buildFeatureButton(context, Icons.article, 'Baca Artikel', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ArticleListPage()),
          );
        }),
      ],
    );
  }

  Widget _buildFeatureButton(BuildContext context, IconData icon, String label,
      VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.cyan[100],
            child: Icon(icon, color: Colors.cyan[700]),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildConsultationCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.cyan, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Image.asset('assets/images/psikolog.jpg',
                    width: 80, height: 80),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Konsultasi Online',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Konsultasi dengan psikolog terpercaya',
                          style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ListPsikologPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Mulai Konsultasi',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOngoingConsultationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lanjutkan Konsultasi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: _transactions.map((transaction) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.cyan[300]!, width: 2),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundImage: transaction.psikologPhoto != null
                      ? NetworkImage(
                          'http://10.0.2.2:8000/storage/photos/${transaction.psikologPhoto}')
                      : const AssetImage('assets/images/default-photo.png')
                          as ImageProvider,
                ),
                title: Text(
                  transaction.psikologName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: transaction.psikologIsOnline
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                    Text(
                      transaction.psikologIsOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: transaction.psikologIsOnline
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          toUserId: transaction.idPsikolog,
                          toUserName: transaction.psikologName,
                          toUserPhoto: transaction.psikologPhoto,
                          showBackButton: true,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Chat',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
