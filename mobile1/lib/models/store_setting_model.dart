// lib/models/store_setting_model.dart

class StoreSettingModel {
  final String storeName;
  final String? address;
  final String? phone;
  final String? logo;

  StoreSettingModel({
    required this.storeName,
    this.address,
    this.phone,
    this.logo,
  });

  factory StoreSettingModel.fromJson(Map<String, dynamic> json) {
    return StoreSettingModel(
      storeName: json['store_name'] ?? 'Toko Sembako',
      address:   json['address'],
      phone:     json['phone'],
      logo:      json['logo'],
    );
  }
}