// lib/features/buku_utang/buku_utang_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/api/api_service.dart';
import 'package:mobile/widgets/tambah_utang_form.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/features/hutang/detail_piutang_screen.dart';

// ============================================================
// MODEL
// ============================================================
class Piutang {
  final String id;
  final String nama;
  final String? imageUrl;
  final double jumlah;
  final DateTime terakhirTransaksi;
  final String status;
  final int? hariOverdue;

  Piutang({
    required this.id,
    required this.nama,
    this.imageUrl,
    required this.jumlah,
    required this.terakhirTransaksi,
    required this.status,
    this.hariOverdue,
  });

  factory Piutang.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return Piutang(
      id: json['id'].toString(),
      nama: customer?['name'] ??
          customer?['nama'] ??
          json['nama'] ??
          json['name'] ??
          '',
      imageUrl:
          customer?['image_url'] ?? customer?['photo'] ?? json['image_url'],
      jumlah: parseDouble(json['remaining'] ??
          json['remaining_amount'] ??
          json['total_amount'] ??
          json['jumlah'] ??
          json['amount'] ??
          0),
      terakhirTransaksi: DateTime.tryParse(json['created_at'] ??
              json['last_transaction'] ??
              json['terakhir_transaksi'] ??
              '') ??
          DateTime.now(),
      status: json['status'] ?? 'pending',
      hariOverdue: json['overdue_days'] ?? json['hari_overdue'],
    );
  }
}

// ============================================================
// SCREEN
// ============================================================
class UtangScreen extends StatefulWidget {
  const UtangScreen({super.key});

  @override
  State<UtangScreen> createState() => _UtangScreenState();
}

class _UtangScreenState extends State<UtangScreen> {
  static const Color hijauUtama = Color(0xFF1A7A4A);
  static const Color hijauMuda = Color(0xFFE8F5EE);
  static const Color merahOverdue = Color(0xFFD32F2F);
  static const Color abukuMuda = Color(0xFFF5F5F5);

  final _formatRupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  String? _errorMessage;
  List<Piutang> _daftarPiutang = [];
  double _totalPiutang = 0;
  int _overdueCount = 0;
  int _totalDebitur = 0; // ← ganti dari _pendingCount
  double _persentaseNaik = 0;
  String _sortBy = 'nama';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    debugPrint('TOKEN: $token');
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await ApiService.get('payments/receivables');
      final List raw = response is List ? response : (response['data'] ?? []);
      final list = raw.map((e) => Piutang.fromJson(e)).toList();

      if (!mounted) return;
      setState(() {
        _daftarPiutang = list;
        _totalPiutang = response is Map
            ? (response['total'] ?? list.fold(0.0, (s, p) => s + p.jumlah))
                .toDouble()
            : list.fold(0.0, (s, p) => s + p.jumlah);
        _overdueCount = response is Map
            ? (response['overdue_count'] ??
                list.where((p) => p.status == 'overdue').length)
            : list.where((p) => p.status == 'overdue').length;
        _totalDebitur = list.length; // ← total orang
        _persentaseNaik =
            response is Map ? (response['persentase_naik'] ?? 0).toDouble() : 0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<Piutang> get _sorted {
    final list = [..._daftarPiutang];
    switch (_sortBy) {
      case 'jumlah':
        list.sort((a, b) => b.jumlah.compareTo(a.jumlah));
        break;
      case 'status':
        list.sort((a, b) => a.status.compareTo(b.status));
        break;
      default:
        list.sort((a, b) => a.nama.compareTo(b.nama));
    }
    return list;
  }

  String _formatTanggal(DateTime dt) =>
      DateFormat('dd MMM', 'id_ID').format(dt);

  String _inisial(String nama) {
    final kata = nama.trim().split(' ');
    if (kata.length >= 2) return '${kata[0][0]}${kata[1][0]}'.toUpperCase();
    return nama.substring(0, nama.length.clamp(0, 2)).toUpperCase();
  }

  // ── Buka Form Tambah Hutang ──
  void _bukaFormTambahUtang() {
    showTambahUtangSheet(
      context,
      onSimpan: (data) async {
        await ApiService.post('sales-transactions', data);
        await _fetchData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Utang berhasil disimpan!'),
              backgroundColor: hijauUtama,
            ),
          );
        }
      },
    );
  }

  void _bukaDetailPiutang(Piutang p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPiutangScreen(
          receivableId: int.parse(p.id),
          namaCustomer: p.nama,
        ),
      ),
    ).then((_) => _fetchData());
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: abukuMuda,
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: _bukaFormTambahUtang,
        backgroundColor: hijauUtama,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: hijauUtama))
          : _errorMessage != null
              ? _buildError()
              : RefreshIndicator(
                  color: hijauUtama,
                  onRefresh: _fetchData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildKartuTotal(),
                        const SizedBox(height: 16),
                        _buildKartuStatistik(),
                        const SizedBox(height: 24),
                        _buildHeaderDaftar(),
                        const SizedBox(height: 12),
                        _buildDaftarPiutang(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black87),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
      title: const Text(
        'Buku Utang',
        style: TextStyle(
            color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
      ),
      actions: [
        IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {}),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CircleAvatar(
            backgroundColor: hijauMuda,
            radius: 18,
            child: const Icon(Icons.person, color: hijauUtama, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildKartuTotal() {
    // Total dihitung langsung dari daftar hutang yang tampil
    final totalDaftarHutang = _daftarPiutang.fold(0.0, (s, p) => s + p.jumlah);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: hijauUtama, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TOTAL PIUTANG AKTIF',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(_formatRupiah.format(_totalPiutang > 0 ? _totalPiutang : totalDaftarHutang),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.people_outline, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            if (_persentaseNaik > 0)
              Row(children: [
                const Icon(Icons.trending_up, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(
                  '+${_persentaseNaik.toStringAsFixed(1)}% bulan ini',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ]),
            Text(
              '${_daftarPiutang.length} debitur aktif',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildKartuStatistik() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(
          child: _kartuStat(
            label: 'OVERDUE',
            nilai: '${_overdueCount.toString().padLeft(2, '0')} Orang',
            icon: Icons.error_outline,
            iconColor: merahOverdue,
            iconBg: merahOverdue.withOpacity(0.1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _kartuStat(
            label: 'TOTAL DEBITUR', // ← label baru
            nilai: '${_totalDebitur.toString().padLeft(2, '0')} Orang',
            icon: Icons.people_outline, // ← ikon baru
            iconColor: hijauUtama,
            iconBg: hijauMuda,
          ),
        ),
      ]),
    );
  }

  Widget _kartuStat({
    required String label,
    required String nilai,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 10),
        Text(label,
            style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Text(nilai,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
      ]),
    );
  }

  Widget _buildHeaderDaftar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Daftar Hutang',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          GestureDetector(
            onTap: _tampilkanSortMenu,
            child: const Row(children: [
              Icon(Icons.filter_list, color: hijauUtama, size: 18),
              SizedBox(width: 4),
              Text('Urutkan',
                  style: TextStyle(
                      color: hijauUtama,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildDaftarPiutang() {
    final list = _sorted;
    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Belum ada data piutang.',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 72, color: Color(0xFFEEEEEE)),
          itemBuilder: (_, i) => _buildItemPiutang(list[i]),
        ),
      ),
    );
  }

  Widget _buildItemPiutang(Piutang p) {
    final isOverdue = p.status == 'overdue';
    return InkWell(
      onTap: () => _bukaDetailPiutang(p),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: p.imageUrl != null
                ? Image.network(p.imageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildAvatar(p))
                : _buildAvatar(p),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nama,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87)),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: isOverdue ? merahOverdue : hijauUtama,
                          shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(
                    isOverdue ? 'OVERDUE ${p.hariOverdue} HARI' : 'PENDING',
                    style: TextStyle(
                        color: isOverdue ? merahOverdue : hijauUtama,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5),
                  ),
                ]),
              ],
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_formatRupiah.format(p.jumlah),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87)),
            const SizedBox(height: 4),
            Text('Terakhir: ${_formatTanggal(p.terakhirTransaksi)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildAvatar(Piutang p) {
    return Container(
      width: 48,
      height: 48,
      color: hijauMuda,
      child: Center(
        child: Text(_inisial(p.nama),
            style: const TextStyle(
                color: hijauUtama, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off_rounded, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text(_errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchData,
            style: ElevatedButton.styleFrom(backgroundColor: hijauUtama),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label:
                const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
          ),
        ]),
      ),
    );
  }

  void _tampilkanSortMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Urutkan berdasarkan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            _sortTile('Nama (A-Z)', 'nama'),
            _sortTile('Jumlah Terbesar', 'jumlah'),
            _sortTile('Status (Overdue dulu)', 'status'),
          ],
        ),
      ),
    );
  }

  Widget _sortTile(String label, String value) {
    final selected = _sortBy == value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: selected ? hijauUtama : Colors.grey),
      title: Text(label,
          style: TextStyle(
              color: selected ? hijauUtama : Colors.black87,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
    );
  }
}
