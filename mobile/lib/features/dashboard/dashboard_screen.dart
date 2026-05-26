// lib/features/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_service.dart';
import '../../utils/format_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoading = true;
  double totalPenjualan = 0;
  double totalUtang = 0;
  int pendingTransaksi = 0;
  List<Map<String, dynamic>> _transaksiHarian = [];
  bool _isLoadingTransaksi = false;

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final response = await ApiService.get('dashboard/kasir');
      if (!mounted) return;
      setState(() {
        totalPenjualan   = _toDouble(response['todays_sales']);
        totalUtang       = _toDouble(response['debt_sales']);
        pendingTransaksi = (response['pending_transactions'] as num?)?.toInt() ?? 0;
        isLoading        = false;
      });
      _loadTransaksiHarian();
    } catch (e) {
      debugPrint('Dashboard error: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadTransaksiHarian() async {
    setState(() => _isLoadingTransaksi = true);
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final response = await ApiService.get(
        'sales-transactions?date_from=$today&date_to=$today',
      );
      final List raw = response is List ? response : (response['data'] ?? []);
      if (!mounted) return;
      setState(() {
        _transaksiHarian = raw.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoadingTransaksi = false;
      });
    } catch (e) {
      debugPrint('Transaksi error: $e');
      if (!mounted) return;
      setState(() => _isLoadingTransaksi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Total Penjualan Card ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Penjualan Hari Ini',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  formatRupiah(totalPenjualan),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TOTAL UTANG',
                              style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 10,
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text(
                            formatRupiah(totalUtang),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TRANSAKSI PENDING',
                              style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 10,
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text(
                            '$pendingTransaksi',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Ringkasan Statistik ──
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Penjualan Hari Ini',
                  value: formatRupiah(totalPenjualan),
                  icon: Icons.trending_up,
                  color: const Color(0xFF059669),
                  bgColor: const Color(0xFFD1FAE5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Total Piutang',
                  value: formatRupiah(totalUtang),
                  icon: Icons.account_balance_wallet_outlined,
                  color: const Color(0xFFDB2777),
                  bgColor: const Color(0xFFFCE7F3),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Pending transaksi ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.pending_actions_outlined,
                      color: Color(0xFFD97706), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Transaksi Pending',
                          style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280))),
                      Text(
                        '$pendingTransaksi Transaksi',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Tabel Transaksi Harian ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transaksi Hari Ini',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_transaksiHarian.length} Transaksi',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _isLoadingTransaksi
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _transaksiHarian.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'Belum ada transaksi hari ini',
                              style: TextStyle(color: Color(0xFF9CA3AF)),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              // Header tabel
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF059669),
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text('No. Struk',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text('Metode',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text('Total',
                                          textAlign: TextAlign.end,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ),

                              // Baris transaksi
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _transaksiHarian.length,
                                separatorBuilder: (_, __) => const Divider(
                                    height: 1, color: Color(0xFFE5E7EB)),
                                itemBuilder: (_, i) {
                                  final trx = _transaksiHarian[i];
                                  final invoice =
                                      trx['invoice_number'] ?? '-';
                                  final total = _toDouble(trx['total']);
                                  final paymentType =
                                      trx['payment_type'] ?? '-';
                                  final jam = trx['created_at'] != null
                                      ? DateFormat('HH:mm').format(
                                          DateTime.parse(trx['created_at'])
                                              .toLocal())
                                      : '-';

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        // No struk + jam
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                invoice,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF111827),
                                                ),
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                jam,
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        Color(0xFF9CA3AF)),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Metode pembayaran
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: paymentType == 'cash'
                                                  ? const Color(0xFFD1FAE5)
                                                  : const Color(0xFFFCE7F3),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              paymentType == 'cash'
                                                  ? 'Tunai'
                                                  : 'Utang',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: paymentType == 'cash'
                                                    ? const Color(0xFF059669)
                                                    : const Color(0xFFDB2777),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Total
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            formatRupiah(total),
                                            textAlign: TextAlign.end,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }
}