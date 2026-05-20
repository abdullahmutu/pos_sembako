// lib/features/produk/produk_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api/api_service.dart';

// ============================================================
// MODEL
// ============================================================
class Produk {
  final String id;
  final String sku;
  final String nama;
  final String kategori;
  final String categoryId;
  final String satuan;
  final int stok;
  final String? imageUrl;
  int jumlahDitambah;

  Produk({
    required this.id,
    required this.sku,
    required this.nama,
    required this.kategori,
    required this.categoryId,
    required this.satuan,
    required this.stok,
    this.imageUrl,
    this.jumlahDitambah = 0,
  });

  factory Produk.fromJson(Map<String, dynamic> json) {
    return Produk(
      id: json['id'].toString(),
      sku: json['sku'] ?? '',
      nama: json['name'] ?? json['nama'] ?? '',
      kategori: json['category']?['name'] ?? json['kategori'] ?? '',
      categoryId: json['category']?['id']?.toString() ??
          json['category_id']?.toString() ?? '',
      satuan: json['unit'] ?? json['satuan'] ?? '',
      stok: json['stock'] ?? json['stok'] ?? 0,
      imageUrl: json['image_url'] ?? json['image'],
    );
  }
}

// ============================================================
// SCREEN
// ============================================================
class ProdukScreen extends StatefulWidget {
  const ProdukScreen({super.key});

  @override
  State<ProdukScreen> createState() => _ProdukScreenState();
}

class _ProdukScreenState extends State<ProdukScreen> {
  static const Color hijauUtama = Color(0xFF059669);
  static const Color hijauMuda = Color(0xFFD1FAE5);
  static const Color merahMuda = Color(0xFFFCE4EC);
  static const Color merahTeks = Color(0xFFD32F2F);
  static const Color abukuMuda = Color(0xFFF3F4F6);
  static const Color abuGaris = Color(0xFFE5E7EB);

  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  List<Produk> _semuaProduk = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProduk();
  }

  // ── API: GET /api/v1/products ──
  Future<void> _fetchProduk() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await ApiService.get('products');
      List data = [];
      if (response is List) {
        data = response;
      } else if (response is Map) {
        data = response['data'] ?? response['products'] ?? [];
      }
      setState(() {
        _semuaProduk = data.map((e) => Produk.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ── API: Update stok ──
  Future<void> _simpanPerubahan() async {
    final ditambah = _semuaProduk.where((p) => p.jumlahDitambah > 0).toList();
    if (ditambah.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada produk yang ditambahkan.')),
      );
      return;
    }

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Simpan',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${ditambah.length} produk akan ditambahkan stoknya:'),
            const SizedBox(height: 10),
            ...ditambah.map((p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text(p.nama,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13))),
                      Text('+${p.jumlahDitambah}',
                          style: const TextStyle(
                              color: hijauUtama, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: hijauUtama,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;
    setState(() => _isSaving = true);

    try {
      for (final p in ditambah) {
        await ApiService.put('products/${p.id}', {
          'sku': p.sku,
          'category_id': p.categoryId,
          'stock': p.stok + p.jumlahDitambah,
        });
      }
      setState(() {
        for (var p in _semuaProduk) p.jumlahDitambah = 0;
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Stok berhasil diperbarui!'),
              backgroundColor: hijauUtama),
        );
        _fetchProduk();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: merahTeks,
        ));
      }
    }
  }

  void _ubahJumlah(Produk produk, int delta) {
    setState(() {
      final baru = produk.jumlahDitambah + delta;
      if (baru >= 0) produk.jumlahDitambah = baru;
    });
  }

  // ── Buka form tambah produk baru ──
  void _bukaFormTambahProduk() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormTambahProduk(
        onSimpan: (data) async {
          await ApiService.post('products', data);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Produk berhasil ditambahkan!'),
                  backgroundColor: hijauUtama),
            );
            _fetchProduk();
          }
        },
      ),
    );
  }

  List<Produk> get _produkTerfilter {
    if (_query.isEmpty) return _semuaProduk;
    return _semuaProduk.where((p) {
      return p.nama.toLowerCase().contains(_query.toLowerCase()) ||
          p.kategori.toLowerCase().contains(_query.toLowerCase());
    }).toList();
  }

  int get _totalSKU => _semuaProduk.length;
  int get _lowStockCount => _semuaProduk.where((p) => p.stok <= 5).length;
  int get _totalDitambah =>
      _semuaProduk.fold(0, (sum, p) => sum + p.jumlahDitambah);

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // ── FAB dihapus, tombol Produk Baru sudah di header ──
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: hijauUtama))
                : _errorMessage != null
                    ? _buildError()
                    : _buildKonten(),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchProduk,
              style: ElevatedButton.styleFrom(backgroundColor: hijauUtama),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Coba Lagi',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKonten() {
    return RefreshIndicator(
      color: hijauUtama,
      onRefresh: _fetchProduk,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildJudul(),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 12),
            _buildKartuStatistik(),
            const SizedBox(height: 20),
            _buildDaftarProduk(),
            const SizedBox(height: 20), // ← dikurangi, tidak perlu ruang FAB
          ],
        ),
      ),
    );
  }

  // ── Judul + Tombol Produk Baru sejajar ──
  Widget _buildJudul() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('INVENTORY MANAGEMENT',
                style: TextStyle(
                    color: hijauUtama,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2)),
            SizedBox(height: 4),
            Text('Tambah Produk',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _bukaFormTambahProduk,
          style: ElevatedButton.styleFrom(
            backgroundColor: hijauUtama,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          icon: const Icon(Icons.add, color: Colors.white, size: 18),
          label: const Text('Produk Baru',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: abukuMuda,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Cari Produk...',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: hijauUtama,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildKartuStatistik() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: hijauUtama,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    color: Colors.white70, size: 20),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL SKU',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8)),
                    Text('$_totalSKU',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: merahMuda,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: merahTeks, size: 20),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LOW STOCK',
                        style: TextStyle(
                            color: merahTeks,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8)),
                    Text('$_lowStockCount Items',
                        style: const TextStyle(
                            color: merahTeks,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDaftarProduk() {
    final list = _produkTerfilter;
    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Produk tidak ditemukan.',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: abuGaris),
      itemBuilder: (_, i) => _buildItemProduk(list[i]),
    );
  }

  Widget _buildItemProduk(Produk produk) {
    final bool lowStock = produk.stok <= 5;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 70,
              height: 70,
              color: abukuMuda,
              child: produk.imageUrl != null
                  ? Image.network(produk.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                          size: 30))
                  : const Icon(Icons.image_not_supported_outlined,
                      color: Colors.grey, size: 30),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(produk.nama,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87)),
                const SizedBox(height: 2),
                Text('${produk.kategori} • ${produk.satuan}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: lowStock ? merahMuda : hijauMuda,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Stok: ${produk.stok}',
                      style: TextStyle(
                          color: lowStock ? merahTeks : hijauUtama,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          _buildKontrolJumlah(produk),
        ],
      ),
    );
  }

  Widget _buildKontrolJumlah(Produk produk) {
    return Row(
      children: [
        _tombolBulat(
          icon: Icons.remove,
          warna: Colors.grey.shade200,
          warnaIcon: Colors.black54,
          onTap: () => _ubahJumlah(produk, -1),
        ),
        SizedBox(
          width: 36,
          child: Text('${produk.jumlahDitambah}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        _tombolBulat(
          icon: Icons.add,
          warna: hijauUtama,
          warnaIcon: Colors.white,
          onTap: () => _ubahJumlah(produk, 1),
        ),
      ],
    );
  }

  Widget _tombolBulat({
    required IconData icon,
    required Color warna,
    required Color warnaIcon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
        child: Icon(icon, color: warnaIcon, size: 18),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF065F46),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('TOTAL DITAMBAH',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          letterSpacing: 0.8)),
                  Text('$_totalDitambah Produk',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ],
              ),
            ),
            _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : ElevatedButton.icon(
                    onPressed: _simpanPerubahan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hijauUtama,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_circle_outline,
                        color: Colors.white, size: 20),
                    label: const Text('Simpan Perubahan',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// ============================================================
// FORM TAMBAH PRODUK BARU — Bottom Sheet
// ============================================================
class _FormTambahProduk extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic> data) onSimpan;

  const _FormTambahProduk({required this.onSimpan});

  @override
  State<_FormTambahProduk> createState() => _FormTambahProdukState();
}

class _FormTambahProdukState extends State<_FormTambahProduk> {
  static const Color hijauUtama = Color(0xFF059669);
  static const Color abukuMuda = Color(0xFFF3F4F6);

  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _hargaCtrl = TextEditingController();
  final _hargaBeliCtrl = TextEditingController();
  final _stokCtrl = TextEditingController();
  final _kategoriCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();

  String? _selectedSatuan;

  static const List<String> _listSatuan = [
    'pcs', 'kg', 'gram', 'liter', 'ml', 'botol', 'dus', 'karton', 'lusin', 'meter',
  ];

  // Kategori dari API: nama → id
  List<String> _listKategori = [];
  Map<String, String> _kategoriIdMap = {}; // nama → id
  String? _selectedKategoriId;
  bool _loadingKategori = false;

  // SKU auto-generate
  String _sku = '';

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _sku = '';
    _namaCtrl.addListener(_updateSku);
    _kategoriCtrl.addListener(_updateSku);
    _fetchKategori();
  }

  // Ambil singkatan dari teks (maks 3 huruf pertama tiap kata, maks 3 huruf)
  String _singkat(String teks) {
    if (teks.trim().isEmpty) return '';
    final kata = teks.trim().split(RegExp(r'\s+'));
    if (kata.length == 1) {
      return kata[0].substring(0, kata[0].length.clamp(0, 3)).toUpperCase();
    }
    // Ambil huruf pertama setiap kata, maks 3 kata
    return kata
        .take(3)
        .map((k) => k.isNotEmpty ? k[0].toUpperCase() : '')
        .join();
  }

  void _updateSku() {
    final singkatKategori = _singkat(_kategoriCtrl.text);
    final singkatNama = _singkat(_namaCtrl.text);

    if (singkatKategori.isEmpty && singkatNama.isEmpty) {
      setState(() => _sku = '');
      return;
    }

    final rand = Random();
    final angka = rand.nextInt(90000) + 10000;
    final parts = [
      if (singkatKategori.isNotEmpty) singkatKategori,
      if (singkatNama.isNotEmpty) singkatNama,
      '$angka',
    ];
    // Hanya update angka random sekali saja agar tidak berubah terus saat ketik
    // Simpan prefix stabil, update hanya jika prefix berubah
    final newPrefix = parts.take(parts.length - 1).join('-');
    final oldPrefix = _sku.contains('-')
        ? _sku.substring(0, _sku.lastIndexOf('-'))
        : '';
    if (newPrefix != oldPrefix || _sku.isEmpty) {
      setState(() => _sku = '$newPrefix-$angka');
    }
  }

  String _generateSku() {
    final singkatKategori = _singkat(_kategoriCtrl.text);
    final singkatNama = _singkat(_namaCtrl.text);
    final rand = Random();
    final angka = rand.nextInt(90000) + 10000;
    final parts = [
      if (singkatKategori.isNotEmpty) singkatKategori,
      if (singkatNama.isNotEmpty) singkatNama,
      '$angka',
    ];
    return parts.join('-');
  }

  Future<void> _fetchKategori() async {
    setState(() => _loadingKategori = true);
    try {
      final response = await ApiService.get('categories');
      List data = [];
      if (response is List) {
        data = response;
      } else if (response is Map) {
        data = response['data'] ?? response['categories'] ?? [];
      }
      final map = <String, String>{};
      for (final e in data) {
        final nama = (e['name'] ?? e['nama'] ?? '').toString();
        final id = e['id']?.toString() ?? '';
        if (nama.isNotEmpty && id.isNotEmpty) map[nama] = id;
      }
      setState(() {
        _kategoriIdMap = map;
        _listKategori = map.keys.toList();
        _loadingKategori = false;
      });
    } catch (_) {
      setState(() => _loadingKategori = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKategoriId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSimpan({
        'sku': _sku,
        'name': _namaCtrl.text.trim(),
        'selling_price': double.tryParse(_hargaCtrl.text.trim()) ?? 0,
        'purchase_price': double.tryParse(_hargaBeliCtrl.text.trim()) ?? 0,
        'stock': int.tryParse(_stokCtrl.text.trim()) ?? 0,
        'unit': _selectedSatuan ?? '',
        'category_id': _selectedKategoriId,
        'description': _deskripsiCtrl.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  void dispose() {
    _namaCtrl.removeListener(_updateSku);
    _kategoriCtrl.removeListener(_updateSku);
    _namaCtrl.dispose();
    _hargaCtrl.dispose();
    _hargaBeliCtrl.dispose();
    _stokCtrl.dispose();
    _kategoriCtrl.dispose();
    _deskripsiCtrl.dispose();
    super.dispose();
  }

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
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_box_outlined,
                        color: hijauUtama, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Produk Baru',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      Text('Isi data produk yang akan ditambahkan',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildLabel('Nama Produk *'),
              const SizedBox(height: 6),
              _buildField(
                controller: _namaCtrl,
                hint: 'contoh: Beras Premium 5kg',
                icon: Icons.label_outline,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nama produk wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // ── SKU auto-generate (read only) ──
              _buildLabel('SKU'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: _sku.isEmpty
                      ? const Color(0xFFF3F4F6)
                      : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.qr_code_2_outlined,
                        color: _sku.isEmpty ? Colors.grey : hijauUtama,
                        size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _sku.isEmpty
                            ? 'Isi nama & kategori untuk generate SKU'
                            : _sku,
                        style: TextStyle(
                          color: _sku.isEmpty ? Colors.grey : hijauUtama,
                          fontWeight: _sku.isEmpty
                              ? FontWeight.normal
                              : FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: _sku.isEmpty ? 0 : 1,
                        ),
                      ),
                    ),
                    if (_sku.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() => _sku = _generateSku()),
                        child: const Icon(Icons.refresh_rounded,
                            color: hijauUtama, size: 18),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Harga Jual *'),
                        const SizedBox(height: 6),
                        _buildField(
                          controller: _hargaCtrl,
                          hint: '0',
                          icon: Icons.sell_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Wajib diisi' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Harga Beli *'),
                        const SizedBox(height: 6),
                        _buildField(
                          controller: _hargaBeliCtrl,
                          hint: '0',
                          icon: Icons.shopping_bag_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Wajib diisi' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Stok Awal *'),
                  const SizedBox(height: 6),
                  _buildField(
                    controller: _stokCtrl,
                    hint: '0',
                    icon: Icons.inventory_2_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // ── Satuan: Dropdown ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Satuan'),
                        const SizedBox(height: 6),
                        _buildDropdown(
                          value: _selectedSatuan,
                          hint: 'Pilih satuan',
                          icon: Icons.straighten,
                          items: _listSatuan,
                          onChanged: (v) => setState(() => _selectedSatuan = v),
                          validator: (v) =>
                              v == null ? 'Pilih satuan' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ── Kategori: Input + Autocomplete dari API ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Kategori'),
                        const SizedBox(height: 6),
                        _buildKategoriAutocomplete(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildLabel('Deskripsi'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _deskripsiCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Keterangan tambahan produk (opsional)...',
                  hintStyle:
                      const TextStyle(color: Colors.grey, fontSize: 13),
                  filled: true,
                  fillColor: abukuMuda,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Batal',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hijauUtama,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_circle_outline,
                              color: Colors.white, size: 20),
                      label: Text(
                          _isSaving ? 'Menyimpan...' : 'Simpan Produk',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Kategori: input bebas + saran dari API ──
  Widget _buildKategoriAutocomplete() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue val) {
        if (val.text.isEmpty) return _listKategori;
        return _listKategori.where(
          (k) => k.toLowerCase().contains(val.text.toLowerCase()),
        );
      },
      onSelected: (String selected) {
        _kategoriCtrl.text = selected;
        setState(() => _selectedKategoriId = _kategoriIdMap[selected]);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        // Sinkron controller eksternal ke internal Autocomplete
        controller.text = _kategoriCtrl.text;
        controller.addListener(() => _kategoriCtrl.text = controller.text);
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
          decoration: InputDecoration(
            hintText: _loadingKategori ? 'Memuat...' : 'Ketik atau pilih',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            prefixIcon: const Icon(Icons.category_outlined,
                color: Colors.grey, size: 18),
            suffixIcon: _loadingKategori
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: hijauUtama),
                    ),
                  )
                : null,
            filled: true,
            fillColor: abukuMuda,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: hijauUtama, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final opt = options.elementAt(i);
                  return InkWell(
                    onTap: () => onSelected(opt),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.label_outline,
                              size: 16, color: hijauUtama),
                          const SizedBox(width: 10),
                          Text(opt,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black87)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      validator: validator,
      onChanged: onChanged,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.grey, size: 18),
        filled: true,
        fillColor: abukuMuda,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: hijauUtama, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(fontSize: 13)),
              ))
          .toList(),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87));
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.grey, size: 18),
        filled: true,
        fillColor: abukuMuda,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: hijauUtama, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }
}