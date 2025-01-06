import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import '../services/auth_service.dart';
import '../services/transaction_service.dart';
import '../services/midtrans_config_service.dart' as config_service;
import '../models/psychologist_model.dart';
import 'chat.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'payment_webview.dart';
import 'dart:async';

class ListPsikologPage extends StatefulWidget {
  const ListPsikologPage({super.key});

  @override
  State<ListPsikologPage> createState() => _ListPsikologPageState();
}

class _ListPsikologPageState extends State<ListPsikologPage> {
  final AuthService _authService = AuthService();
  final TransactionService _transactionService = TransactionService();
  final Logger _logger = Logger();
  List<Psychologist> _psychologists = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  MidtransSDK? _midtrans;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadPsychologists();
    _initMidtrans();
    _startAutoRefresh();

    // Tambahkan callback untuk hasil pembayaran
    _midtrans?.setTransactionFinishedCallback((result) {
      _logger.d('Pembayaran selesai dengan status: $result');
      if (mounted) {
        _silentRefresh();
      }
    });
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
      final result = await _authService.getPsychologists();
      final transactions = await _transactionService.getTransactions();

      if (mounted) {
        setState(() {
          if (result['success']) {
            _psychologists = result['psychologists'];
            // Update status transaksi untuk setiap psikolog
            for (var psikolog in _psychologists) {
              final transaction = transactions
                  .where((t) =>
                      t.idPsikolog == psikolog.id &&
                      (t.status == 'Belum dibayar' || t.status == 'Dibayar'))
                  .firstOrNull;

              if (transaction != null) {
                psikolog.transactionStatus = transaction.status;
              }
            }

            // Urutkan psikolog berdasarkan status online dan abjad
            _psychologists.sort((a, b) {
              // Pertama, urutkan berdasarkan status online
              if (a.isOnline != b.isOnline) {
                return b.isOnline ? 1 : -1; // Yang online di atas
              }
              // Jika status online sama, urutkan berdasarkan nama (abjad)
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });
          }
        });
      }
    } catch (e) {
      _logger.e('Error refreshing psychologists', error: e);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _initMidtrans() async {
    if (!mounted) return;

    // Simpan referensi theme di awal
    final primaryColor = Theme.of(context).primaryColor;
    final primaryColorDark = Theme.of(context).primaryColorDark;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    try {
      _logger.d('Inisialisasi Midtrans SDK...');

      // Ambil konfigurasi dari backend
      final config = await config_service.MidtransConfigService.getConfig();
      _logger.d('Konfigurasi Midtrans berhasil diambil: ${config.clientKey}');

      if (!mounted) return;

      _midtrans = await MidtransSDK.init(
        config: MidtransConfig(
          clientKey: config.clientKey,
          merchantBaseUrl: "http://your-server-ip",
          colorTheme: ColorTheme(
            colorPrimary: primaryColor,
            colorPrimaryDark: primaryColorDark,
            colorSecondary: secondaryColor,
          ),
          enableLog: true,
        ),
      );
      _logger.d('Midtrans SDK berhasil diinisialisasi');

      _midtrans?.setUIKitCustomSetting(
        skipCustomerDetailsPages: true,
        showPaymentStatus: true,
      );

      _midtrans?.setTransactionFinishedCallback((result) {
        _logger.d('Pembayaran selesai dengan status: $result');
        // Update status transaksi seperti di web
        String status = 'Pending';
        if (result.transactionStatus == TransactionResultStatus.capture ||
            result.transactionStatus == TransactionResultStatus.settlement) {
          status = 'Dibayar';
        } else if (result.transactionStatus ==
            TransactionResultStatus.pending) {
          status = 'Belum dibayar';
        } else {
          status = 'Gagal';
        }
        if (result.orderId != null) {
          _transactionService.updateTransactionStatus(result.orderId!, status);
        }
        if (mounted) {
          _silentRefresh();
        }
      });

      _logger.d('Midtrans SDK setup selesai');
    } catch (e) {
      _logger.e('Error saat inisialisasi Midtrans SDK', error: e);
    }
  }

  Future<void> _loadPsychologists() async {
    try {
      final result = await _authService.getPsychologists();
      final transactions = await _transactionService.getTransactions();

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result['success']) {
            _psychologists = result['psychologists'];
            // Update status transaksi untuk setiap psikolog
            for (var psikolog in _psychologists) {
              final transaction = transactions
                  .where((t) =>
                      t.idPsikolog == psikolog.id &&
                      (t.status == 'Belum dibayar' || t.status == 'Dibayar'))
                  .firstOrNull;

              if (transaction != null) {
                psikolog.transactionStatus = transaction.status;
              }
            }

            // Urutkan psikolog berdasarkan status online dan abjad
            _psychologists.sort((a, b) {
              // Pertama, urutkan berdasarkan status online
              if (a.isOnline != b.isOnline) {
                return b.isOnline ? 1 : -1; // Yang online di atas
              }
              // Jika status online sama, urutkan berdasarkan nama (abjad)
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });
          }
        });
      }
    } catch (e) {
      _logger.e('Error loading psychologists', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePayment(Psychologist psychologist) async {
    try {
      final result =
          await _transactionService.createTransaction(psychologist.id);
      _logger.d('Payment result: $result');

      if (!mounted) return;

      if (result['success'] || result['status']) {
        final data = result['data'] ?? result;
        final String? snapToken = data['snap_token'];
        final String? redirectUrl = data['redirect_url'];
        final String? transactionStatus = data['transaction_status'];

        if (transactionStatus == 'Dibayar' || redirectUrl != null) {
          // Jika sudah ada transaksi yang dibayar, langsung ke chat
          Get.to(() => ChatPage(
                toUserId: psychologist.id,
                toUserName: psychologist.name,
                toUserPhoto: psychologist.photo,
                showBackButton: true,
              ));
        } else if (snapToken != null) {
          // Jika perlu pembayaran, tampilkan WebView Midtrans
          _logger.d('Menampilkan halaman pembayaran dengan token: $snapToken');

          final paymentResult = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentWebView(snapToken: snapToken),
            ),
          );

          _logger.d('Payment result: $paymentResult');

          if (paymentResult == 'Dibayar') {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pembayaran berhasil'),
                  backgroundColor: Colors.green,
                ),
              );
              _silentRefresh();
            }
          } else if (paymentResult == 'Belum dibayar') {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pembayaran dalam proses'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } else if (paymentResult == 'Dibatalkan') {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pembayaran dibatalkan'),
                  backgroundColor: Colors.grey,
                ),
              );
            }
          } else if (paymentResult == 'cancel') {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pembayaran dibatalkan'),
                  backgroundColor: Colors.grey,
                ),
              );
            }
          }
        } else {
          _logger.e('Tidak ada snap_token atau redirect_url dalam response');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Data pembayaran tidak lengkap'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Terjadi kesalahan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      _logger.e('Error handling payment', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat memproses pembayaran'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Daftar Psikolog', style: TextStyle(color: Colors.cyan)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.cyan),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _psychologists.length,
              itemBuilder: (context, index) {
                final psikolog = _psychologists[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.cyan[300]!, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Foto Psikolog
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: psikolog.photo != null
                              ? Image.network(
                                  'http://your-server-ip/storage/photos/${psikolog.photo}',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/default-photo.png',
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Image.asset(
                                  'assets/images/default-photo.png',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        const SizedBox(width: 16),
                        // Informasi Psikolog
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                psikolog.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.cyan,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                psikolog.bio ?? 'Tidak ada deskripsi',
                                style: TextStyle(color: Colors.grey[600]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: psikolog.isOnline
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    psikolog.isOnline ? 'Online' : 'Offline',
                                    style: TextStyle(
                                      color: psikolog.isOnline
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Rp ${psikolog.harga.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Tombol Aksi
                                  if (psikolog.isOnline)
                                    Flexible(
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _handlePayment(psikolog),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.cyan,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            psikolog.transactionStatus ==
                                                    'Belum dibayar'
                                                ? 'Lanjutkan Pembayaran'
                                                : psikolog.transactionStatus ==
                                                        'Dibayar'
                                                    ? 'Chat Sekarang'
                                                    : 'Pilih Psikolog',
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _midtrans?.removeTransactionFinishedCallback();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
