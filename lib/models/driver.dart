class Driver {
  final String id;
  final String name;
  final String phone;
  final String idNumber;
  final String? idPic;
  final String licenseNumber;
  final String? licensePic;
  final String? cityId;
  final DateTime createdAt;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.idNumber,
    this.idPic,
    required this.licenseNumber,
    this.licensePic,
    this.cityId,
    required this.createdAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      idNumber: json['id_number'] ?? '',
      idPic: json['id_pic'],
      licenseNumber: json['license_number'] ?? '',
      licensePic: json['license_pic'],
      cityId: json['city_id'],
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
      'license_number': licenseNumber,
      'license_pic': licensePic,
      'city_id': cityId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Driver copyWith({
    String? id,
    String? name,
    String? phone,
    String? idNumber,
    String? idPic,
    String? licenseNumber,
    String? licensePic,
    String? cityId,
    DateTime? createdAt,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      idNumber: idNumber ?? this.idNumber,
      idPic: idPic ?? this.idPic,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licensePic: licensePic ?? this.licensePic,
      cityId: cityId ?? this.cityId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class City {
  final String id;
  final String name;
  final DateTime createdAt;

  City({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}