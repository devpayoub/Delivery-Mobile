class Employer {
  final String id;
  final String name;
  final String phone;
  final String idNumber;
  final String? idPic;
  final DateTime createdAt;

  Employer({
    required this.id,
    required this.name,
    required this.phone,
    required this.idNumber,
    this.idPic,
    required this.createdAt,
  });

  factory Employer.fromJson(Map<String, dynamic> json) {
    return Employer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      idNumber: json['id_number'] ?? '',
      idPic: json['id_pic'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'id_number': idNumber,
      'id_pic': idPic,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Employer copyWith({
    String? id,
    String? name,
    String? phone,
    String? idNumber,
    String? idPic,
    DateTime? createdAt,
  }) {
    return Employer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      idNumber: idNumber ?? this.idNumber,
      idPic: idPic ?? this.idPic,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}