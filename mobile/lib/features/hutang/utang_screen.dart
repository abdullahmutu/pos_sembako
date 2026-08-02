// lib/features/buku_utang/buku_utang_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/api/api_service.dart';
import 'package:mobile/widgets/tambah_utang_form.dart';
import 'package:mobile/features/hutang/detail_piutang_screen.dart';

// ============================================================
// MODEL
// ============================================================
class Piutang {
  final String id;
  final String nama;
  final String? imageUrl;
  final double jumlah; // menyimpan sisa (remaining)
  final double totalAmount; // ⚠️ FIX: jumlah utang awal (sebelum dicicil)
  final DateTime terakhirTransaksi;
  final DateTime? jatuhTempo;
  final String status; // status waktu: overdue / lunas / pending
  final String statusBayar; // ⚠️ FIX: status pembayaran: lunas / sebagian / belum_lunas
  final int? hariOverdue;

  Piutang({
    required this.id,
    required this.nama,
    this.imageUrl,
    required this.jumlah,
    required this.totalAmount,
    required this.terakhirTransaksi,
    this.jatuhTempo,
    required this.status,
    required this.statusBayar,
    this.hariOverdue,
  });

  factory Piutang.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    // Ambil nilai remaining dari beberapa kemungkinan key
    final remaining = parseDouble(json['remaining'] ??
        json['remaining_amount'] ??
        json['total_amount'] ??
        json['jumlah'] ??
        json['amount'] ??
        0);

    // ⚠️ FIX: Ambil jumlah UTANG AWAL (sebelum dicicil) secara terpisah dari
    // remaining, supaya bisa membedakan "Belum Lunas" (belum dicicil sama
    // sekali, remaining == amount) dengan "Sebagian" (sudah dicicil
    // sebagian, 0 < remaining < amount). Sebelumnya field ini tidak
    // dipisahkan dari remaining, jadi status "Sebagian" tidak bisa dideteksi.
    final totalAmount = parseDouble(
        json['amount'] ?? json['total_amount'] ?? json['jumlah_awal'] ?? remaining);

    // Ambil tanggal jatuh tempo dari beberapa kemungkinan key
    final DateTime? jatuhTempo = DateTime.tryParse((json['due_date'] ??
        json['jatuh_tempo'] ??
        json['tanggal_jatuh_tempo'] ??
        json['tempo'] ??
        '')
    .toString())
    ?.toLocal();

    // Ambil overdue days langsung dari backend jika ada
    final dynamic overdueRaw = json['overdue_days'] ?? json['hari_overdue'] ?? json['overdue'];
    int? overdueDays;
    if (overdueRaw != null) {
      if (overdueRaw is int) {
        overdueDays = overdueRaw;
      } else {
        overdueDays = int.tryParse(overdueRaw.toString());
      }
    }

    // Piutang dianggap terlambat jika tanggal jatuh tempo adalah HARI INI
    // atau sudah lewat, dan belum lunas. Jatuh tempo hari ini pun langsung
    // dihitung terlambat (bukan cuma yang sudah lewat).
    final now = DateTime.now();
    bool isOverdueByTempo = false;
    if (jatuhTempo != null && remaining > 0) {
      final today = DateTime(now.year, now.month, now.day);
      final tempo = DateTime(jatuhTempo.year, jatuhTempo.month, jatuhTempo.day);
      if (!today.isBefore(tempo)) {
        // today >= tempo -> jatuh tempo hari ini atau sudah lewat
        isOverdueByTempo = true;
        final selisih = today.difference(tempo).inDays; // 0 = jatuh tempo hari ini
        if (overdueDays == null || overdueDays <= 0) {
          overdueDays = selisih;
        }
      }
    }

    // Ambil status dari response; jika backend belum update tapi remaining == 0,
    // anggap sudah 'lunas' agar UI konsisten.
    String statusRaw = (json['status'] ?? 'pending').toString().toLowerCase();
    if (remaining <= 0) {
      statusRaw = 'lunas';
    } else if (isOverdueByTempo || (overdueDays != null && overdueDays > 0)) {
      // jatuh tempo hari ini/sudah lewat, atau backend eksplisit kirim overdue_days
      statusRaw = 'overdue';
    }

    // ⚠️ FIX: status pembayaran independen dari status keterlambatan di
    // atas. Piutang yang terlambat pun tetap punya status pembayaran
    // (belum_lunas atau sebagian), jadi ini dihitung terpisah supaya kedua
    // filter (waktu vs pembayaran) tidak saling menimpa.
    String statusBayar;
    if (remaining <= 0) {
      statusBayar = 'lunas';
    } else if (totalAmount > 0 && remaining < totalAmount) {
      statusBayar = 'sebagian';
    } else {
      statusBayar = 'belum_lunas';
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
      jumlah: remaining,
      totalAmount: totalAmount,
      terakhirTransaksi: (DateTime.tryParse(json['created_at'] ??
            json['last_transaction'] ??
            json['terakhir_transaksi'] ??
            json['updated_at'] ??
            '') ??
        DateTime.now())
        .toLocal(),
      jatuhTempo: jatuhTempo,
      status: statusRaw,
      statusBayar: statusBayar,
      hariOverdue: overdueDays,
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
  static const Color amberSebagian = Color(0xFFFFA000);
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
  int _totalDebitur = 0;
  double _persentaseNaik = 0;
  String _sortBy = 'nama';

  // ⚠️ FIX: state filter status pembayaran. Nilai yang mungkin:
  // 'semua', 'belum_lunas', 'sebagian', 'lunas'.
  String _filterStatusBayar = 'semua';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await ApiService.get('payments/receivables');
      final List raw = response is List ? response : (response['data'] ?? []);
      final list = raw.cast<Map<String, dynamic>>().map((e) => Piutang.fromJson(e)).toList();

      if (!mounted) return;
      setState(() {
        _daftarPiutang = list;
        // jumlah menyimpan sisa (remaining)
        _totalPiutang = list.fold(0.0, (s, p) => s + p.jumlah);
        _overdueCount = list.where((p) => p.status == 'overdue').length;
        _totalDebitur = list.length;
        _persentaseNaik = response is Map ? (response['persentase_naik'] ?? 0).toDouble() : 0;
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
    // ⚠️ FIX: filter berdasarkan status pembayaran diterapkan dulu sebelum
    // sorting, supaya chip "Belum Lunas"/"Sebagian"/"Lunas" benar-benar
    // menyaring daftar yang tampil, bukan cuma mengubah urutan.
    var list = _daftarPiutang.where((p) {
      if (_filterStatusBayar == 'semua') return true;
      return p.statusBayar == _filterStatusBayar;
    }).toList();

    switch (_sortBy) {
      case 'jumlah':
        list.sort((a, b) => b.jumlah.compareTo(a.jumlah));
        break;
      case 'status':
        // Terlambat (overdue) tampil paling atas
        list.sort((a, b) {
          int urutan(String s) {
            if (s == 'overdue') return 0;
            if (s == 'pending') return 1;
            return 2; // lunas
          }
          return urutan(a.status).compareTo(urutan(b.status));
        });
        break;
      default:
        list.sort((a, b) => a.nama.compareTo(b.nama));
    }
    return list;
  }

  String _formatTanggal(DateTime dt) => DateFormat('dd MMM', 'id_ID').format(dt);

  String _inisial(String nama) {
    final kata = nama.trim().split(' ');
    if (kata.isEmpty || nama.trim().isEmpty) return '?';
    if (kata.length >= 2) return '${kata[0][0]}${kata[1][0]}'.toUpperCase();
    return nama.substring(0, nama.length.clamp(0, 2)).toUpperCase();
  }

  // ⚠️ FIX: helper label & warna untuk chip filter status pembayaran.
  String _labelFilter(String value) {
    switch (value) {
      case 'belum_lunas':
        return 'Belum Lunas';
      case 'sebagian':
        return 'Sebagian';
      case 'lunas':
        return 'Lunas';
      default:
        return 'Semua';
    }
  }

  void _pilihFilterStatusBayar(String value) {
    setState(() => _filterStatusBayar = value);
  }

  // ── Buka Form Tambah Hutang ──
  void _bukaFormTambahUtang() {
    showTambahUtangSheet(
      context,
      onSimpan: (data) async {
        try {
          await ApiService.post('sales-transactions', data);
          // beri sedikit jeda agar backend memproses
          await Future.delayed(const Duration(seconds: 1));
          await _fetchData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Utang berhasil disimpan!'),
                backgroundColor: hijauUtama,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
            );
          }
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
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
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
                        // ⚠️ FIX: chip filter status pembayaran, ditaruh di
                        // atas daftar supaya user bisa langsung menyaring
                        // Belum Lunas / Sebagian / Lunas.
                        _buildFilterStatusBayar(),
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
      automaticallyImplyLeading: false,
      title: Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'Cari hutang...',
            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 11),
          ),
        ),
      ),
    );
  }

  Widget _buildKartuTotal() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: hijauUtama, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TOTAL PIUTANG AKTIF',
              style: TextStyle(
                  color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(
            _formatRupiah.format(_totalPiutang),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.people_outline, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                '${_daftarPiutang.length} debitur aktif',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              if (_persentaseNaik > 0) ...[
                const SizedBox(width: 12),
                const Icon(Icons.trending_up, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(
                  '+${_persentaseNaik.toStringAsFixed(1)}% bulan ini',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ],
          ),
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
            label: 'TERLAMBAT',
            nilai: '${_overdueCount.toString().padLeft(2, '0')} Orang',
            icon: Icons.error_outline,
            iconColor: merahOverdue,
            iconBg: merahOverdue.withValues(alpha: 0.1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _kartuStat(
            label: 'TOTAL DEBITUR',
            nilai: '${_totalDebitur.toString().padLeft(2, '0')} Orang',
            icon: Icons.people_outline,
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 10),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Text(nilai, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
      ]),
    );
  }

  Widget _buildHeaderDaftar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Daftar Hutang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          GestureDetector(
            onTap: _tampilkanSortMenu,
            child: const Row(children: [
              Icon(Icons.filter_list, color: hijauUtama, size: 18),
              SizedBox(width: 4),
              Text('Urutkan', style: TextStyle(color: hijauUtama, fontWeight: FontWeight.w600, fontSize: 14)),
            ]),
          ),
        ],
      ),
    );
  }

  // ⚠️ FIX: widget baru — baris chip filter status pembayaran.
  // Ditampilkan sebagai pill horizontal, konsisten dengan gaya filter
  // kategori di halaman Transaksi.
  Widget _buildFilterStatusBayar() {
    const options = ['semua', 'belum_lunas', 'sebagian', 'lunas'];

    Color warnaChip(String value, bool selected) {
      if (!selected) return Colors.white;
      switch (value) {
        case 'lunas':
          return hijauUtama;
        case 'sebagian':
          return amberSebagian;
        case 'belum_lunas':
          return merahOverdue;
        default:
          return hijauUtama;
      }
    }

    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final value = options[i];
          final selected = value == _filterStatusBayar;
          final warna = warnaChip(value, selected);
          return GestureDetector(
            onTap: () => _pilihFilterStatusBayar(value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: warna,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? warna : const Color(0xFFE5E7EB),
                ),
              ),
              child: Text(
                _labelFilter(value),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDaftarPiutang() {
    final list = _sorted;
    if (list.isEmpty) {
      // ⚠️ FIX: pesan kosong disesuaikan supaya jelas kalau kosongnya
      // karena filter status pembayaran yang dipilih, bukan datanya
      // benar-benar tidak ada.
      final pesan = _filterStatusBayar == 'semua'
          ? 'Belum ada data piutang.'
          : 'Tidak ada piutang dengan status "${_labelFilter(_filterStatusBayar)}".';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(pesan, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, color: Color(0xFFEEEEEE)),
          itemBuilder: (_, i) => _buildItemPiutang(list[i]),
        ),
      ),
    );
  }

  Widget _buildItemPiutang(Piutang p) {
    // Warna untuk status
    final Color pendingColor = const Color(0xFFFFC107); // amber
    final Color overdueColor = merahOverdue;
    final Color lunasColor = hijauUtama;

    // Tentukan kondisi status
    final bool isOverdueStatus = p.status == 'overdue';
    final bool isLunas = p.status == 'lunas' || p.jumlah <= 0;

    Color statusColor;
    String statusLabel;

    if (isOverdueStatus) {
      statusColor = overdueColor;
      if (p.hariOverdue == null) {
        statusLabel = 'TERLAMBAT';
      } else if (p.hariOverdue == 0) {
        statusLabel = 'TERLAMBAT HARI INI';
      } else {
        statusLabel = 'TERLAMBAT ${p.hariOverdue} HARI';
      }
    } else if (isLunas) {
      statusColor = lunasColor;
      statusLabel = 'LUNAS';
    } else {
      statusColor = pendingColor;
      statusLabel = 'BELUM LUNAS';
    }

    return InkWell(
      onTap: () => _bukaDetailPiutang(p),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: p.imageUrl != null
                ? Image.network(p.imageUrl!, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildAvatar(p))
                : _buildAvatar(p),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
              const SizedBox(height: 4),
              Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                // ⚠️ FIX: badge tambahan khusus untuk menandai piutang yang
                // sudah dicicil sebagian, supaya kelihatan bedanya dengan
                // "Belum Lunas" biasa (yang belum dicicil sama sekali).
                if (p.statusBayar == 'sebagian' && !isLunas) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: amberSebagian.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'DICICIL',
                      style: TextStyle(color: amberSebagian, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                    ),
                  ),
                ],
              ]),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_formatRupiah.format(p.jumlah),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(
              p.jatuhTempo != null
                  ? 'Jatuh tempo: ${_formatTanggal(p.jatuhTempo!)}'
                  : 'Tanpa jatuh tempo',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
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
        child: Text(_inisial(p.nama), style: const TextStyle(color: hijauUtama, fontWeight: FontWeight.bold, fontSize: 16)),
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
          Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchData,
            style: ElevatedButton.styleFrom(backgroundColor: hijauUtama),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
          ),
        ]),
      ),
    );
  }

  void _tampilkanSortMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Urutkan berdasarkan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _sortTile('Nama (A-Z)', 'nama'),
          _sortTile('Jumlah Terbesar', 'jumlah'),
          _sortTile('Status (Terlambat dulu)', 'status'),
        ]),
      ),
    );
  }

  Widget _sortTile(String label, String value) {
    final selected = _sortBy == value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selected ? hijauUtama : Colors.grey),
      title: Text(label, style: TextStyle(color: selected ? hijauUtama : Colors.black87, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
    );
  }
}