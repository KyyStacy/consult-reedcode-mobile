class Transaction {
  final String idTransaksi;
  final int idPasien;
  final int idPsikolog;
  final int harga;
  final String status;
  final String? snapToken;
  final String psikologName;
  final String? psikologPhoto;
  final DateTime? psikologLastSeen;
  final DateTime createdAt;

  Transaction({
    required this.idTransaksi,
    required this.idPasien,
    required this.idPsikolog,
    required this.harga,
    required this.status,
    this.snapToken,
    required this.psikologName,
    this.psikologPhoto,
    this.psikologLastSeen,
    required this.createdAt,
  });

  bool get psikologIsOnline {
    if (psikologLastSeen == null) return false;
    final difference = DateTime.now().difference(psikologLastSeen!);
    return difference.inMinutes <= 1;
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      idTransaksi: json['id_transaksi'],
      idPasien: json['id_pasien'],
      idPsikolog: json['id_psikolog'],
      harga: json['harga'],
      status: json['status'],
      snapToken: json['snap_token'],
      psikologName: json['psikolog']['name'] ?? '',
      psikologPhoto: json['psikolog']['photo'],
      psikologLastSeen: json['psikolog']['last_seen'] != null
          ? DateTime.parse(json['psikolog']['last_seen'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_transaksi': idTransaksi,
      'id_pasien': idPasien,
      'id_psikolog': idPsikolog,
      'harga': harga,
      'status': status,
      'snap_token': snapToken,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
