class Delivery {
  final String id;
  final String clientName;
  final String phone;
  final double totalPrice;
  final String status;
  final String cityName;
  final String productTypeName;
  final String? address;
  final String? reason;
  final String? employerId;
  final String? assignedDriverId;
  final String? cityId;
  final String? productTypeId;

  Delivery({
    required this.id,
    required this.clientName,
    required this.phone,
    required this.totalPrice,
    required this.status,
    required this.cityName,
    required this.productTypeName,
    this.address,
    this.reason,
    this.employerId,
    this.assignedDriverId,
    this.cityId,
    this.productTypeId,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] ?? '',
      clientName: json['client_name'] ?? 'Unknown',
      phone: json['phone'] ?? '',
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      status: json['status'] ?? 'Pending',
      cityName: json['cities'] != null ? json['cities']['name'] : 'Unknown City',
      productTypeName: json['product_types'] != null ? json['product_types']['name'] : 'Unknown Product',
      address: json['address'],
      reason: json['reason'],
      employerId: json['employer_id'],
      assignedDriverId: json['assigned_driver_id'],
      cityId: json['city_id'],
      productTypeId: json['product_type_id'],
    );
  }
}
