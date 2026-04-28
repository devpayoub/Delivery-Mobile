class ProductType {
  final String id;
  final String name;

  ProductType({
    required this.id,
    required this.name,
  });

  factory ProductType.fromJson(Map<String, dynamic> json) {
    return ProductType(
      id: json['id'],
      name: json['name'],
    );
  }
}
