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
      address: json['address'],
      phone: json['phone'],
      logo: _resolveLogo(json['logo']),
    );
  }

  /// Resolve logo ke full URL.
  /// API bisa mengembalikan:
  /// - null / kosong         → null
  /// - full URL (http/https) → langsung dipakai
  /// - path relatif          → disambung dengan base URL storage
  static String? _resolveLogo(dynamic raw) {
    if (raw == null) return null;
    final path = raw.toString().trim();
    if (path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    // Sesuaikan base URL dengan server kamu
    // Ganti IP/domain sesuai kebutuhan
    const baseUrl = 'http://192.168.1.5:8000/storage/';
    return '$baseUrl$path';
  }
}