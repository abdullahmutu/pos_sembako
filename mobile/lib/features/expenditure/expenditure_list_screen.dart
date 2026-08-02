// lib/features/expenditure/expenditure_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_service.dart';
import '../../utils/format_helper.dart';
import 'expenditure_form_screen.dart';

class ExpenditureListScreen extends StatefulWidget {
  const ExpenditureListScreen({super.key});

  @override
  State<ExpenditureListScreen> createState() => _ExpenditureListScreenState();
}

class _ExpenditureListScreenState extends State<ExpenditureListScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<Map<String, dynamic>> _allExpenditures = [];
  String _search = '';

  List<Map<String, dynamic>> get _expenditures {
    if (_search.isEmpty) return _allExpenditures;
    final q = _search.toLowerCase();
    return _allExpenditures.where((e) {
      final desc = (e['description'] ?? '').toString().toLowerCase();
      final cat = (e['category'] ?? '').toString().toLowerCase();
      return desc.contains(q) || cat.contains(q);
    }).toList();
  }

  double get _totalHariIni =>
      _expenditures.fold(0.0, (sum, e) => sum + _toDouble(e['amount']));

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  @override
  void initState() {
    super.initState();
    _loadExpenditures();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Hanya ambil pengeluaran untuk hari ini, sama seperti pola
  // "Transaksi Hari Ini" di dashboard.
  // NOTE: ExpenditureController::index() hardcode paginate(20) tanpa
  // menerima per_page dari query — kalau pengeluaran hari ini bisa lebih
  // dari 20, backend perlu diubah supaya per_page dinamis.
  Future<void> _loadExpenditures() async {
    setState(() => _isLoading = true);
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final response = await ApiService.get(
        'expenditures?from=$today&to=$today',
      );

      final List raw = response is List ? response : (response['data'] ?? []);
      final parsed = raw.map((e) => Map<String, dynamic>.from(e)).toList();

      if (!mounted) return;
      setState(() {
        _allExpenditures = parsed;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Expenditure list error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _search = value.trim());
  }

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenditureFormScreen(expenditure: existing),
      ),
    );
    if (result == true) {
      _loadExpenditures();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tidak pakai AppBar di sini karena MainScreen sudah menyediakan
    // AppBar-nya sendiri (judul "Pengeluaran" diambil dari _titles di main.dart).
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFF059669),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadExpenditures,
        child: Column(
          children: [
            // ── Search bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari pengeluaran hari ini...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // ── Ringkasan hari ini ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_expenditures.length} Pengeluaran Hari Ini',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280)),
                  ),
                  Text(
                    '- ${formatRupiah(_totalHariIni)}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC2626)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── List ──
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _expenditures.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                          itemCount: _expenditures.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final exp = _expenditures[i];
                            return _ExpenditureCard(
                              expenditure: exp,
                              toDouble: _toDouble,
                              onTap: () => _openForm(existing: exp),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.wallet_outlined, size: 30, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada pengeluaran hari ini',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ExpenditureCard extends StatelessWidget {
  final Map<String, dynamic> expenditure;
  final double Function(dynamic) toDouble;
  final VoidCallback onTap;

  const _ExpenditureCard({
    required this.expenditure,
    required this.toDouble,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final description = expenditure['description'] ?? '-';
    final category = expenditure['category'];
    final amount = toDouble(expenditure['amount']);
    final dateRaw = expenditure['expense_date'];
    final dateStr = dateRaw != null
        ? DateFormat('d MMM y').format(DateTime.parse(dateRaw))
        : '-';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_downward_rounded,
                    color: Color(0xFFDC2626), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (category != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xFF6B7280)),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          dateStr,
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '- ${formatRupiah(amount)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}