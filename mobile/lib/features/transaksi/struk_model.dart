class StrukModel {
  final String nomorStruk;
  final DateTime waktu;
  final List<Map<String, dynamic>> items;
  final int totalHarga;
  final String paymentType;
  final int? bayar; // hanya untuk cash

  StrukModel({
    required this.nomorStruk,
    required this.waktu,
    required this.items,
    required this.totalHarga,
    required this.paymentType,
    this.bayar,
  });

  int get kembalian => paymentType == 'cash' ? (bayar ?? 0) - totalHarga : 0;
}