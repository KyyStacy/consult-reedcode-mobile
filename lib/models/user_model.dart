class User {
  final int id;
  final String name;
  final String email;
  final String? photo;
  final List<String> roles;
  final bool isOnline;
  final String? phoneNumber;
  // Detail psikolog
  final String? bio;
  final int? harga;

  User({
    this.id = 0,
    this.name = '',
    this.email = '',
    this.photo,
    this.roles = const [],
    this.isOnline = false,
    this.phoneNumber,
    this.bio,
    this.harga,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _parseInt(json['id']),
      name: _parseString(json['name']),
      email: _parseString(json['email']),
      photo: json['photo']?.toString(),
      roles: _parseRoles(json['roles']),
      isOnline: json['is_online'] == true,
      phoneNumber: json['phone_number']?.toString(),
      bio: json['detail_psikolog']?['bio']?.toString(),
      harga: _parseInt(json['detail_psikolog']?['harga']),
    );
  }

  static List<String> _parseRoles(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((role) => role['name'].toString()).toList();
    }
    return [];
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photo': photo,
      'roles': roles,
      'is_online': isOnline,
      'phone_number': phoneNumber,
      'detail_psikolog': {
        'bio': bio,
        'harga': harga,
      }
    };
  }

  bool get isPsychologist => roles.contains('psikolog');
  bool get isPatient => roles.contains('user');
  bool get isAdmin => roles.contains('admin');
}
