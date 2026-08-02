String formatRupiah(double value) {
  return 'Rp ${value.toInt().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  )}';
}

DateTime parseDateOnly(String raw) {
  final datePart = raw.split('T').first;
  final parts = datePart.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}