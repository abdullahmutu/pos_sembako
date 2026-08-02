import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/api/api_service.dart';

// ============================================================
// MODEL
// ============================================================
class DetailPiutang {
  final int id;
  final int customerId;
  final String namaCustomer;
  final double amount;
  final double paid;
  final double remaining;
  final String status;
  final String? dueDate;
  final String? notes;
  final String createdAt;
  final String invoiceNumber;
  final double subtotal;
  final List<ItemTransaksi> items;
  final List<RiwayatBayar> riwayat;

  DetailPiutang({
    required this.id,
    required this.customerId,
    required this.namaCustomer,
    required this.amount,
    required this.paid,
    required this.remaining,
    required this.status,
    this.dueDate,
    this.notes,
    required this.createdAt,
    required this.invoiceNumber,
    required this.subtotal,
    required this.items,
    required this.riwayat,
  });

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory DetailPiutang.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final trx = json['sales_transaction'] as Map<String, dynamic>?;
    final rawItems = trx?['sale_items'] as List? ?? [];
    final rawRiwayat = json['payment_histories'] as List? ?? [];

    return DetailPiutang(
      id: json['id'],
      customerId: json['customer_id'],
      namaCustomer: customer?['name'] ?? '',
      amount: _parseDouble(json['amount']),
      paid: _parseDouble(json['paid']),
      remaining: _parseDouble(json['remaining']),
      status: json['status'] ?? 'unpaid',
      dueDate: json['due_date'],
      notes: json['notes'],
      createdAt: json['created_at'] ?? '',
      invoiceNumber: trx?['invoice_number'] ?? '-',
      subtotal: _parseDouble(trx?['total']),
      items: rawItems.map((e) => ItemTransaksi.fromJson(e)).toList(),
      riwayat: rawRiwayat.map((e) => RiwayatBayar.fromJson(e)).toList(),
    );
  }

  double get persentaseLunas =>
      amount > 0 ? (paid / amount * 100).clamp(0, 100) : 0;

  /// Tanggal pembayaran terakhir (yang paling baru), null jika belum pernah bayar.
  String? get tanggalBayarTerakhir {
    if (riwayat.isEmpty) return null;
    final sorted = List<RiwayatBayar>.from(riwayat)
      ..sort((a, b) {
        final da = DateTime.tryParse(a.paidAt) ?? DateTime(0);
        final db = DateTime.tryParse(b.paidAt) ?? DateTime(0);
        return db.compareTo(da); // descending: terbaru dulu
      });
    return sorted.first.paidAt;
  }
}

class ItemTransaksi {
  final String namaProduk;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  ItemTransaksi({
    required this.namaProduk,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory ItemTransaksi.fromJson(Map<String, dynamic> json) {
    final produk = json['product'] as Map<String, dynamic>?;
    return ItemTransaksi(
      namaProduk: produk?['name'] ?? '-',
      quantity: json['quantity'] ?? 0,
      unitPrice: _parseDouble(json['unit_price']),
      subtotal: _parseDouble(json['subtotal']),
    );
  }
}

class RiwayatBayar {
  final int id;
  final double amount;
  final String paymentMethod;
  final String? reference;
  final String? notes;
  final String paidAt;

  RiwayatBayar({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    this.reference,
    this.notes,
    required this.paidAt,
  });

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory RiwayatBayar.fromJson(Map<String, dynamic> json) {
    return RiwayatBayar(
      id: json['id'],
      amount: _parseDouble(json['amount']),
      paymentMethod: json['payment_method'] ?? 'cash',
      reference: json['reference'],
      notes: json['notes'],
      paidAt: json['paid_at'] ?? json['created_at'] ?? '',
    );
  }
}

// ============================================================
// SCREEN DETAIL PIUTANG
// ============================================================
class DetailPiutangScreen extends StatefulWidget {
  final int receivableId;
  final String namaCustomer;

  const DetailPiutangScreen({
    super.key,
    required this.receivableId,
    required this.namaCustomer,
  });

  @override
  State<DetailPiutangScreen> createState() => _DetailPiutangScreenState();
}

class _DetailPiutangScreenState extends State<DetailPiutangScreen> {
  static const Color hijauUtama = Color(0xFF1A7A4A);
  static const Color hijauMuda = Color(0xFFE8F5EE);
  static const Color merah = Color(0xFFD32F2F);
  static const Color merahMuda = Color(0xFFFFEBEE);
  static const Color kuning = Color(0xFFF57C00);
  static const Color kuningMuda = Color(0xFFFFF3E0);
  static const Color abukuMuda = Color(0xFFF5F5F5);

  final _formatRupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  String? _error;
  DetailPiutang? _data;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Ambil detail receivable spesifik berdasarkan ID
      final res = await ApiService.get(
        'payments/receivables?customer_receivable_id=${widget.receivableId}',
      );

      // Coba ambil dari list dengan filter id
      final List raw = res is List ? res : (res['data'] ?? []);
      final Map<String, dynamic>? item = raw
          .cast<Map<String, dynamic>>()
          .where((e) => e['id'] == widget.receivableId)
          .firstOrNull;

      if (item == null) {
        // Fallback: ambil semua dan filter
        final res2 = await ApiService.get('payments/receivables');
        final List raw2 = res2 is List ? res2 : (res2['data'] ?? []);
        final found = raw2
            .cast<Map<String, dynamic>>()
            .where((e) => e['id'] == widget.receivableId)
            .firstOrNull;
        if (found == null) throw Exception('Data tidak ditemukan');
        setState(() {
          _data = DetailPiutang.fromJson(found);
          _isLoading = false;
        });
      } else {
        setState(() {
          _data = DetailPiutang.fromJson(item);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _labelStatus(String status) {
    switch (status) {
      case 'paid':
        return 'LUNAS';
      case 'partial':
        return 'CICILAN';
      case 'overdue':
        return 'OVERDUE';
      default:
        return 'BELUM BAYAR';
    }
  }

  Color _warnaStatus(String status) {
    switch (status) {
      case 'paid':
        return hijauUtama;
      case 'partial':
        return kuning;
      case 'overdue':
        return merah;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _warnaBgStatus(String status) {
    switch (status) {
      case 'paid':
        return hijauMuda;
      case 'partial':
        return kuningMuda;
      case 'overdue':
        return merahMuda;
      default:
        return abukuMuda;
    }
  }

  String _labelMetode(String method) {
    switch (method) {
      case 'cash':
        return 'Tunai';
      case 'qris':
        return 'QRIS';
      case 'bank_transfer':
        return 'Transfer Bank';
      case 'check':
        return 'Cek';
      default:
        return 'Lainnya';
    }
  }

  IconData _ikonMetode(String method) {
    switch (method) {
      case 'cash':
        return Icons.payments_outlined;
      case 'qris':
        return Icons.qr_code_2_outlined;
      case 'bank_transfer':
        return Icons.account_balance_outlined;
      case 'check':
        return Icons.receipt_outlined;
      default:
        return Icons.more_horiz;
    }
  }

  String _formatTanggal(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (_) {
      return raw;
    }
  }

  // ── Selisih hari relatif terhadap hari ini (untuk jatuh tempo) ──
  int? _selisihHariJatuhTempo(String dueDate) {
    try {
      final due = DateTime.parse(dueDate).toLocal();
      final now = DateTime.now();
      final dueDay = DateTime(due.year, due.month, due.day);
      final today = DateTime(now.year, now.month, now.day);
      return dueDay.difference(today).inDays;
    } catch (_) {
      return null;
    }
  }

  String _labelSelisihHari(int selisih) {
    if (selisih < 0) return 'Terlambat ${selisih.abs()} hari';
    if (selisih == 0) return 'Jatuh tempo hari ini';
    return '$selisih hari lagi';
  }

  Color _warnaSelisihHari(int selisih) {
    if (selisih < 0) return merah;
    if (selisih <= 3) return kuning;
    return hijauUtama;
  }

  // ── Selisih hari lalu (untuk tanggal pembayaran terakhir) ──
  String _selisihHariLalu(String tanggal) {
    try {
      final dt = DateTime.parse(tanggal).toLocal();
      final now = DateTime.now();
      final dtDay = DateTime(dt.year, dt.month, dt.day);
      final today = DateTime(now.year, now.month, now.day);
      final diff = today.difference(dtDay).inDays;
      if (diff <= 0) return 'Hari ini';
      if (diff == 1) return 'Kemarin';
      return '$diff hari lalu';
    } catch (_) {
      return '';
    }
  }

  // ── Buka form bayar ──
  void _bukaBayar() {
    if (_data == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FormBayarSheet(
        receivableId: _data!.id,
        namaCustomer: _data!.namaCustomer,
        sisaHutang: _data!.remaining,
        onBerhasil: () {
          _fetchDetail();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran berhasil dicatat!'),
              backgroundColor: hijauUtama,
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: abukuMuda,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Detail Utang',
                style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text(widget.namaCustomer,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _fetchDetail,
          ),
        ],
      ),
      floatingActionButton: _data != null && _data!.status != 'paid'
          ? FloatingActionButton.extended(
              onPressed: _bukaBayar,
              backgroundColor: hijauUtama,
              icon: const Icon(Icons.payment, color: Colors.white),
              label: const Text('Bayar',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: hijauUtama))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: hijauUtama,
                  onRefresh: _fetchDetail,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildKartuRingkasan(),
                        const SizedBox(height: 16),
                        _buildProgressBayar(),
                        const SizedBox(height: 16),
                        _buildInfoTanggal(),
                        const SizedBox(height: 16),
                        _buildItemTransaksi(),
                        const SizedBox(height: 16),
                        _buildRiwayatPembayaran(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
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
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchDetail,
            style: ElevatedButton.styleFrom(backgroundColor: hijauUtama),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label:
                const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
          ),
        ]),
      ),
    );
  }

  // ── Kartu ringkasan utang ──
  Widget _buildKartuRingkasan() {
    final d = _data!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hijauUtama,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    d.namaCustomer.isNotEmpty
                        ? d.namaCustomer[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.namaCustomer,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Text(d.invoiceNumber,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ]),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _warnaBgStatus(d.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _labelStatus(d.status),
                  style: TextStyle(
                      color: _warnaStatus(d.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('SISA TAGIHAN',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(_formatRupiah.format(d.remaining),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _statKartu(
                label: 'Total Utang',
                nilai: _formatRupiah.format(d.amount),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statKartu(
                label: 'Sudah Dibayar',
                nilai: _formatRupiah.format(d.paid),
              ),
            ),
          ]),
          if (d.dueDate != null) ...[
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                'Jatuh tempo: ${_formatTanggal(d.dueDate!)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _statKartu({required String label, required String nilai}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(nilai,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ]),
    );
  }

  // ── Progress pembayaran ──
  Widget _buildProgressBayar() {
    final d = _data!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Progress Pembayaran',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87)),
            Text(
              '${d.persentaseLunas.toStringAsFixed(0)}%',
              style: const TextStyle(
                  color: hijauUtama, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: d.persentaseLunas / 100,
              minHeight: 10,
              backgroundColor: abukuMuda,
              valueColor: const AlwaysStoppedAnimation<Color>(hijauUtama),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dibayar: ${_formatRupiah.format(d.paid)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text('Sisa: ${_formatRupiah.format(d.remaining)}',
                  style: const TextStyle(
                      color: merah, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Info terakhir bayar & jatuh tempo ──
  Widget _buildInfoTanggal() {
    final d = _data!;
    final selisih =
        d.dueDate != null ? _selisihHariJatuhTempo(d.dueDate!) : null;
    final tampilkanCountdown =
        d.dueDate != null && d.status != 'paid' && selisih != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _infoTanggalItem(
              icon: Icons.history,
              label: 'Terakhir Dibayar',
              nilai: d.tanggalBayarTerakhir != null
                  ? _formatTanggal(d.tanggalBayarTerakhir!)
                  : 'Belum ada',
              subNilai: d.tanggalBayarTerakhir != null
                  ? _selisihHariLalu(d.tanggalBayarTerakhir!)
                  : null,
              warnaSub: hijauUtama,
            ),
          ),
          Container(
            width: 1,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: const Color(0xFFEEEEEE),
          ),
          Expanded(
            child: _infoTanggalItem(
              icon: Icons.event_outlined,
              label: 'Jatuh Tempo',
              nilai:
                  d.dueDate != null ? _formatTanggal(d.dueDate!) : 'Tidak ada',
              subNilai: tampilkanCountdown ? _labelSelisihHari(selisih) : null,
              warnaSub: tampilkanCountdown
                  ? _warnaSelisihHari(selisih)
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTanggalItem({
    required IconData icon,
    required String label,
    required String nilai,
    String? subNilai,
    required Color warnaSub,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        Text(nilai,
            style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
        if (subNilai != null) ...[
          const SizedBox(height: 2),
          Text(subNilai,
              style: TextStyle(
                  color: warnaSub, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }

  // ── Item transaksi ──
  Widget _buildItemTransaksi() {
    final d = _data!;
    if (d.items.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text('Rincian Produk',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87)),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          ...d.items.asMap().entries.map((entry) {
            final i = entry.value;
            final isLast = entry.key == d.items.length - 1;
            return Column(children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: hijauMuda,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: hijauUtama, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(i.namaProduk,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.black87)),
                          Text(
                            '${i.quantity} x ${_formatRupiah.format(i.unitPrice)}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ]),
                  ),
                  Text(
                    _formatRupiah.format(i.subtotal),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87),
                  ),
                ]),
              ),
              if (!isLast)
                const Divider(height: 1, indent: 68, color: Color(0xFFEEEEEE)),
            ]);
          }),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87)),
                Text(_formatRupiah.format(d.subtotal),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: hijauUtama)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Riwayat pembayaran ──
  Widget _buildRiwayatPembayaran() {
    final d = _data!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text('Riwayat Pembayaran',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87)),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          if (d.riwayat.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Belum ada riwayat pembayaran.',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            )
          else
            ...d.riwayat.asMap().entries.map((entry) {
              final r = entry.value;
              final isLast = entry.key == d.riwayat.length - 1;
              return Column(children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: hijauMuda,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_ikonMetode(r.paymentMethod),
                          color: hijauUtama, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_labelMetode(r.paymentMethod),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.black87)),
                            Text(_formatTanggal(r.paidAt),
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            if (r.reference != null)
                              Text('Ref: ${r.reference}',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 11)),
                          ]),
                    ),
                    Text(
                      _formatRupiah.format(r.amount),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: hijauUtama),
                    ),
                  ]),
                ),
                if (!isLast)
                  const Divider(
                      height: 1, indent: 68, color: Color(0xFFEEEEEE)),
              ]);
            }),
        ],
      ),
    );
  }
}

// ============================================================
// BOTTOM SHEET FORM PEMBAYARAN
// ============================================================
class FormBayarSheet extends StatefulWidget {
  final int receivableId;
  final String namaCustomer;
  final double sisaHutang;
  final VoidCallback onBerhasil;

  const FormBayarSheet({
    super.key,
    required this.receivableId,
    required this.namaCustomer,
    required this.sisaHutang,
    required this.onBerhasil,
  });

  @override
  State<FormBayarSheet> createState() => _FormBayarSheetState();
}

class _FormBayarSheetState extends State<FormBayarSheet> {
  static const Color hijauUtama = Color(0xFF1A7A4A);
  static const Color hijauMuda = Color(0xFFE8F5EE);
  static const Color abukuMuda = Color(0xFFF5F5F5);
  static const Color merah = Color(0xFFD32F2F);
  static const Color merahMuda = Color(0xFFFFEBEE);

  final _formatRupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final _nominalCtrl = TextEditingController();
  final _referensiCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();

  String _metodeBayar = 'cash';
  bool _isSaving = false;
  bool _lunasSemua = false;

  File? _buktiFile;
  final ImagePicker _picker = ImagePicker();

  /// Nominal yang sedang diketik user, diparse dari _nominalCtrl.
  double get _nominalSaatIni => double.tryParse(_nominalCtrl.text.trim()) ?? 0;

  /// True jika nominal yang diketik melebihi sisa hutang.
  bool get _melebihiSisaHutang => _nominalSaatIni > widget.sisaHutang;

  @override
  void initState() {
    super.initState();
    _nominalCtrl.text =
        widget.sisaHutang.toInt().toString(); // default: lunas semua
    _lunasSemua = true;
  }

  @override
  void dispose() {
    _nominalCtrl.dispose();
    _referensiCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  void _toggleLunasSemua(bool val) {
    setState(() {
      _lunasSemua = val;
      if (val) {
        _nominalCtrl.text = widget.sisaHutang.toInt().toString();
      } else {
        _nominalCtrl.clear();
      }
    });
  }

  Future<void> _pickBukti(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() => _buktiFile = File(picked.path));
    }
  }

  void _showBuktiPickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: hijauUtama),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickBukti(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: hijauUtama),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickBukti(ImageSource.camera);
              },
            ),
            if (_buktiFile != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: merah),
                title: const Text('Hapus Bukti', style: TextStyle(color: merah)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _buktiFile = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _simpan() async {
    final nominalStr = _nominalCtrl.text.trim();
    if (nominalStr.isEmpty) {
      _snack('Nominal pembayaran wajib diisi!');
      return;
    }
    final nominal = double.tryParse(nominalStr);
    if (nominal == null || nominal <= 0) {
      _snack('Nominal tidak valid!');
      return;
    }
    if (nominal > widget.sisaHutang) {
      _snack(
          'Nominal melebihi sisa hutang! Maksimal ${_formatRupiah.format(widget.sisaHutang)}');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final fields = <String, String>{
        'customer_receivable_id': widget.receivableId.toString(),
        'amount': nominal.toString(),
        'payment_method': _metodeBayar,
        if (_referensiCtrl.text.trim().isNotEmpty)
          'reference': _referensiCtrl.text.trim(),
        if (_catatanCtrl.text.trim().isNotEmpty)
          'notes': _catatanCtrl.text.trim(),
      };

      // Pakai postMultipart supaya bukti pembayaran (kalau diisi) ikut
      // terkirim. Kalau _buktiFile null, postMultipart tetap jalan normal
      // sebagai request biasa tanpa file -- jadi aman dipakai selalu,
      // tidak perlu percabangan post() vs postMultipart().
      //
      // fileFieldName WAJIB 'proof_of_payment', harus persis sama dengan
      // nama field yang divalidasi di PaymentController::recordPayment
      // ($request->hasFile('proof_of_payment')).
      await ApiService.postMultipart(
        'payments/record',
        fields,
        _buktiFile,
        fileFieldName: 'proof_of_payment',
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onBerhasil();
      }
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Catat Pembayaran',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  Text(widget.namaCustomer,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, color: Colors.black54),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Info sisa hutang
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hijauMuda,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sisa Hutang',
                      style: TextStyle(color: hijauUtama, fontSize: 13)),
                  Text(
                    _formatRupiah.format(widget.sisaHutang),
                    style: const TextStyle(
                        color: hijauUtama,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Toggle lunas semua
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Bayar Lunas Semua',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
                Switch(
                  value: _lunasSemua,
                  onChanged: _toggleLunasSemua,
                  activeColor: hijauUtama,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Nominal
            _label('NOMINAL PEMBAYARAN'),
            const SizedBox(height: 8),
            TextField(
              controller: _nominalCtrl,
              keyboardType: TextInputType.number,
              enabled: !_lunasSemua,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: const TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.w600),
                hintText: '0',
                filled: true,
                fillColor: _lunasSemua
                    ? Colors.grey.shade100
                    : (_melebihiSisaHutang ? merahMuda : abukuMuda),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: _melebihiSisaHutang && !_lunasSemua
                      ? const BorderSide(color: merah, width: 1.2)
                      : BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _melebihiSisaHutang && !_lunasSemua
                        ? merah
                        : hijauUtama,
                    width: 1.5,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            if (!_lunasSemua && _melebihiSisaHutang) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: merah, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Nominal melebihi sisa hutang! Maksimal ${_formatRupiah.format(widget.sisaHutang)}',
                      style: const TextStyle(
                          color: merah,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // Metode pembayaran
            _label('METODE PEMBAYARAN'),
            const SizedBox(height: 10),
            Row(children: [
              _chipMetode('cash', 'Tunai', Icons.payments_outlined),
              const SizedBox(width: 8),
              _chipMetode('qris', 'QRIS', Icons.qr_code_2_outlined),
              const SizedBox(width: 8),
              _chipMetode(
                  'bank_transfer', 'Transfer', Icons.account_balance_outlined),
            ]),

            const SizedBox(height: 20),

            // Bukti pembayaran (opsional)
            _label('BUKTI PEMBAYARAN (Opsional)'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showBuktiPickerDialog,
              child: Container(
                height: 130,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: abukuMuda,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _buktiFile == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              color: Colors.grey, size: 36),
                          SizedBox(height: 8),
                          Text('Tap untuk upload bukti pembayaran',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_buktiFile!, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () => setState(() => _buktiFile = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Referensi (opsional)
            _label('REFERENSI (Opsional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _referensiCtrl,
              decoration: InputDecoration(
                hintText: 'No. referensi / bukti transfer...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                filled: true,
                fillColor: abukuMuda,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: hijauUtama, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),

            const SizedBox(height: 16),

            // Catatan (opsional)
            _label('CATATAN (Opsional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _catatanCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Tambahkan catatan...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                filled: true,
                fillColor: abukuMuda,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: hijauUtama, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),

            const SizedBox(height: 24),

            // Tombol aksi
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    backgroundColor: abukuMuda,
                  ),
                  child: const Text('Batal',
                      style: TextStyle(
                          color: Colors.black54, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed:
                      (_isSaving || _melebihiSisaHutang) ? null : _simpan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hijauUtama,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Simpan Pembayaran',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: hijauUtama,
          letterSpacing: 1.0));

  Widget _chipMetode(String value, String label, IconData icon) {
    final selected = _metodeBayar == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _metodeBayar = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? hijauUtama : abukuMuda,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? hijauUtama : Colors.grey.shade300,
            ),
          ),
          child: Column(children: [
            Icon(icon, color: selected ? Colors.white : Colors.grey, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}