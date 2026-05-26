// lib/models/printer_model.dart

class PrinterDevice {
  final String id;
  final String name;
  final String? address;
  final bool isConnected;

  PrinterDevice({
    required this.id,
    required this.name,
    this.address,
    this.isConnected = false,
  });

  factory PrinterDevice.fromJson(Map<String, dynamic> json) {
    return PrinterDevice(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'],
      isConnected: json['isConnected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'isConnected': isConnected,
    };
  }

  @override
  String toString() => name;
}