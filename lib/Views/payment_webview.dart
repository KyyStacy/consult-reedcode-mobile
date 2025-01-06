import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/midtrans_config_service.dart';

class PaymentWebView extends StatefulWidget {
  final String snapToken;

  const PaymentWebView({super.key, required this.snapToken});

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  final Logger _logger = Logger();
  bool _isLoading = true;
  Timer? _checkStatusTimer;
  bool _hasShownSuccessDialog = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
    // Mulai pengecekan status setiap 3 detik
    _checkStatusTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkTransactionStatus();
    });
  }

  void _navigateBack(String status) {
    if (!mounted) return;
    Navigator.pop(context, status);
  }

  Future<void> _handleCloseButton() async {
    _checkStatusTimer?.cancel();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        _navigateBack('Dibatalkan');
        return;
      }

      final response = await http.post(
        Uri.parse('http://your-server-ip/api/transaction/check-status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'snap_token': widget.snapToken,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['transaction_status'];
        _logger.d('Status saat close: $status');

        if (status == 'settlement' || status == 'capture') {
          await _updateTransactionStatus('Dibayar');
          _navigateBack('Dibayar');
        } else {
          await _updateTransactionStatus('Dibatalkan');
          _navigateBack('Dibatalkan');
        }
      } else {
        await _updateTransactionStatus('Dibatalkan');
        _navigateBack('Dibatalkan');
      }
    } catch (e) {
      _logger.e('Error checking status on close', error: e);
      await _updateTransactionStatus('Dibatalkan');
      _navigateBack('Dibatalkan');
    }
  }

  Future<void> _checkTransactionStatus() async {
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final response = await http.post(
        Uri.parse('http://your-server-ip/api/transaction/check-status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'snap_token': widget.snapToken,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['transaction_status'];
        _logger.d('Status transaksi: $status');

        if ((status == 'settlement' || status == 'capture') &&
            !_hasShownSuccessDialog) {
          _checkStatusTimer?.cancel();
          await _updateTransactionStatus('Dibayar');
          if (!mounted) return;
          await _showSuccessDialog();
        } else if (status == 'expire' ||
            status == 'cancel' ||
            status == 'deny') {
          _checkStatusTimer?.cancel();
          await _updateTransactionStatus('Dibatalkan');
          _navigateBack('Dibatalkan');
        }
      }
    } catch (e) {
      _logger.e('Error checking transaction status', error: e);
    }
  }

  Future<void> _updateTransactionStatus(String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      await http.post(
        Uri.parse('http://your-server-ip/api/transaction/update-status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'snap_token': widget.snapToken,
          'status': status,
        }),
      );
    } catch (e) {
      _logger.e('Error updating transaction status', error: e);
    }
  }

  @override
  void dispose() {
    _checkStatusTimer?.cancel();
    _controller.clearCache();
    _controller.clearLocalStorage();
    super.dispose();
  }

  void _initWebView() async {
    try {
      final config = await MidtransConfigService.getConfig();
      final snapUrl = '${config.snapUrl}${widget.snapToken}';
      _logger.d('Loading payment page: $snapUrl');

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              _logger.d('Page started loading: $url');
            },
            onPageFinished: (String url) async {
              _logger.d('Page finished loading: $url');
              if (!mounted) return;

              setState(() {
                _isLoading = false;
              });

              if ((url.contains('transaction_status=settlement') ||
                      url.contains('transaction_status=capture') ||
                      url.contains('status_code=200')) &&
                  !_hasShownSuccessDialog) {
                _logger.d('Pembayaran berhasil, menampilkan dialog sukses...');
                _checkStatusTimer?.cancel();
                setState(() {
                  _hasShownSuccessDialog = true;
                });

                await _updateTransactionStatus('Dibayar');
                if (!mounted) return;
                await _showSuccessDialog();
              }
            },
            onWebResourceError: (WebResourceError error) {
              _logger.e('Error loading payment page', error: error.description);
            },
          ),
        )
        ..loadRequest(Uri.parse(snapUrl));
    } catch (e) {
      _logger.e('Error initializing WebView', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat memuat halaman pembayaran'),
          ),
        );
        Navigator.pop(context, 'Dibatalkan');
      }
    }
  }

  Future<void> _showSuccessDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Pembayaran Berhasil'),
        content: const Text('Terima kasih! Pembayaran Anda telah berhasil.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Tutup dialog
              _navigateBack('Dibayar'); // Tutup WebView dengan status Dibayar
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pembayaran'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _handleCloseButton,
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
