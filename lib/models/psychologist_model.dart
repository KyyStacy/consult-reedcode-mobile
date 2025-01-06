class Psychologist {
  final int id;
  final String name;
  final String? photo;
  final bool isOnline;
  final String? bio;
  final int harga;
  String? transactionStatus;

  Psychologist({
    required this.id,
    required this.name,
    this.photo,
    required this.isOnline,
    this.bio,
    required this.harga,
    this.transactionStatus,
  });

  factory Psychologist.fromJson(Map<String, dynamic> json) {
    return Psychologist(
      id: json['id'],
      name: json['name'],
      photo: json['photo'],
      isOnline: json['last_seen'] != null
          ? DateTime.now()
                  .difference(DateTime.parse(json['last_seen']))
                  .inMinutes <=
              1
          : false,
      bio: json['detail_psikolog']?['bio'],
      harga: json['detail_psikolog']?['harga'] ?? 0,
      transactionStatus: json['transaction_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photo': photo,
      'is_online': isOnline,
      'detail_psikolog': {
        'bio': bio,
        'harga': harga,
      },
      'transaction_status': transactionStatus,
    };
  }
}

class DetailPsikolog {
  final String bio;
  final int harga;
  final String spesialis;
  final String pengalaman;
  final String alumni;

  DetailPsikolog({
    required this.bio,
    required this.harga,
    required this.spesialis,
    required this.pengalaman,
    required this.alumni,
  });

  factory DetailPsikolog.fromJson(Map<String, dynamic> json) {
    return DetailPsikolog(
      bio: json['bio'] ?? '',
      harga: json['harga'] ?? 0,
      spesialis: json['spesialis'] ?? '',
      pengalaman: json['pengalaman'] ?? '',
      alumni: json['alumni'] ?? '',
    );
  }
}
