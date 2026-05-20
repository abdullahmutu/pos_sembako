class CustomerModel {
  final int id;
  final String name;
  final String? phone;
  final String? address;

  CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.address,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'],
      name: json['name'] ?? '-',
      phone: json['phone'],
      address: json['address'],
    );
  }
}