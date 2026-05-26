import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

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
  final int? hargaJual;   // ← BARU
  final int? hargaBeli;   // ← BARU
  final String? deskripsi; // ← BARU
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
    this.hargaJual,
    this.hargaBeli,
    this.deskripsi,
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
      stok: int.tryParse(json['stock']?.toString() ?? json['stok']?.toString() ?? '0') ?? 0,
      imageUrl: json['image_url'] ?? json['image'],
      hargaJual: json['selling_price'] != null
          ? num.tryParse(json['selling_price'].toString())?.toInt()
          : null,
      hargaBeli: json['purchase_price'] != null
          ? num.tryParse(json['purchase_price'].toString())?.toInt()
          : null,
      deskripsi: json['description'] ?? json['deskripsi'],
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
  final ScrollController _scrollController = ScrollController();
  String _query = '';
  List<Produk> _semuaProduk = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _highlightedProdukId;

  @override
  void initState() {
    super.initState();
    _fetchProduk();
  }

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
          'name': p.nama,
          'sku': p.sku,
          // 'barcode': p.sku,
          'category_id': p.categoryId,
          'unit': p.satuan,
          'stock': p.stok + p.jumlahDitambah,
          'purchase_price': p.hargaBeli ?? 0,
          'selling_price': p.hargaJual ?? 0,
          'description': p.deskripsi ?? '',
        });
      }
      setState(() {
        for (var p in _semuaProduk) {
          p.jumlahDitambah = 0;
        }
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
      if (baru >= 0) {
        produk.jumlahDitambah = baru;
      }
    });
  }

  void _highlightProduk(Produk produk) {
    setState(() {
      _query = '';
      _searchController.clear();
      _highlightedProdukId = produk.id;
    });

    final index = _semuaProduk.indexWhere((p) => p.id == produk.id);
    if (index >= 0) {
      const double headerHeight = 220;
      const double itemHeight = 99;
      final double offset = headerHeight + (index * itemHeight);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            offset,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _highlightedProdukId = null);
      }
    });
  }

  void _bukaFormTambahProduk() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormTambahProduk(
        semuaProduk: _semuaProduk,
        onSimpan: (data) async {
          final imageFile = data.remove('__image_file') as File?;
          if (imageFile != null) {
            final fields = data.map((k, v) => MapEntry(k, v.toString()));
            await ApiService.postMultipart('products', fields, imageFile);
          } else {
            await ApiService.post('products', data);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Produk berhasil ditambahkan!'),
                  backgroundColor: hijauUtama),
            );
            _fetchProduk();
          }
        },
        onProdukSudahAda: (produk) {
          Navigator.pop(context);
          _highlightProduk(produk);
        },
      ),
    );
  }

  // ── BARU: Buka form edit ──
  void _bukaFormEditProduk(Produk produk) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormEditProduk(
        produk: produk,
        onSimpan: (data) async {
          final imageFile = data.remove('__image_file') as File?;
          final hapusGambar = data.remove('remove_image') as bool? ?? false;

          if (imageFile != null) {
            // Kirim multipart jika ada gambar baru
            final fields = data.map((k, v) => MapEntry(k, v.toString()));
            await ApiService.putMultipart(
                'products/${produk.id}', fields, imageFile);
          } else {
            // Jika hapus gambar, kirim flag ke backend
            if (hapusGambar) data['image_url'] = '';
            await ApiService.put('products/${produk.id}', data);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Produk berhasil diperbarui!'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
        controller: _scrollController,
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

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
    final bool isHighlighted = _highlightedProdukId == produk.id;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFECFDF5) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted
            ? Border.all(color: hijauUtama, width: 1.5)
            : Border.all(color: Colors.transparent),
      ),
      padding: EdgeInsets.symmetric(
          vertical: 14, horizontal: isHighlighted ? 8 : 0),
      child: Row(
        children: [
          // ── Gambar produk ──
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

          // ── Info produk ──
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

          // ── Tombol Edit ── BARU
          GestureDetector(
            onTap: () => _bukaFormEditProduk(produk),
            child: Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: abukuMuda,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_outlined,
                  color: Colors.grey, size: 16),
            ),
          ),

          // ── Kontrol jumlah stok ──
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
    _scrollController.dispose();
    super.dispose();
  }
}

// ============================================================
// FORM TAMBAH PRODUK BARU — Bottom Sheet
// ============================================================
class _FormTambahProduk extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic> data) onSimpan;
  final void Function(Produk produk) onProdukSudahAda;
  final List<Produk> semuaProduk;

  const _FormTambahProduk({
    required this.onSimpan,
    required this.onProdukSudahAda,
    required this.semuaProduk,
  });

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
  final _deskripsiCtrl = TextEditingController();

  String? _selectedSatuan;
  String? _selectedCategoryId;
  List<Map<String, dynamic>> _kategoriList = [];
  bool _loadingKategori = false;
  String? _kategoriError;
  bool _isAddingCategory = false;

  String _sku = '';
  bool _isSaving = false;

  List<String> _namaProdukList = [];

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  static const List<String> _listSatuan = [
    'pcs', 'kg', 'gram', 'liter', 'ml', 'botol', 'dus', 'karton', 'lusin', 'meter',
  ];

  @override
  void initState() {
    super.initState();
    _fetchKategori();
    _initNamaProdukList();
    _namaCtrl.addListener(_onNamaChanged);
  }

  void _initNamaProdukList() {
    _namaProdukList = widget.semuaProduk
        .map((p) => p.nama)
        .where((n) => n.isNotEmpty)
        .toList();
  }

  Produk? _cariProdukByNama(String nama) {
    try {
      return widget.semuaProduk.firstWhere(
        (p) => p.nama.toLowerCase() == nama.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _showDialogProdukSudahAda(Produk produk) async {
    final hasil = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info_outline_rounded,
                  color: Color(0xFFF59E0B), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Produk Sudah Ada',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Produk "${produk.nama}" sudah ada di database.'),
          ],
        ),
        actions: [
          // Tombol Cancel/Kembali
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context, 'cancel');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.close, color: Colors.white),
            label: const Text('Cancel / Kembali',
                style: TextStyle(color: Colors.white)),
          ),
          // Tombol Tambah Stok
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context, 'add_stock');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: hijauUtama,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Tambah Stok',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (hasil == 'cancel') {
      // Kosongkan nama produk agar user bisa input ulang
      _namaCtrl.clear();
    } else if (hasil == 'add_stock') {
      widget.onProdukSudahAda(produk);
    }
  }


  void _onNamaChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateSku();
    });
  }

  String _singkat(String teks) {
    if (teks.trim().isEmpty) return '';
    final kata = teks.trim().split(RegExp(r'\s+'));
    if (kata.length == 1) {
      return kata[0].substring(0, kata[0].length.clamp(0, 3)).toUpperCase();
    }
    return kata.take(3).map((k) => k.isNotEmpty ? k[0].toUpperCase() : '').join();
  }

  void _updateSku() {
    final kategoriNama = _getSelectedCategoryName();
    final singkatKategori = _singkat(kategoriNama);
    final singkatNama = _singkat(_namaCtrl.text);

    if (singkatKategori.isEmpty && singkatNama.isEmpty) {
      if (_sku.isNotEmpty) setState(() => _sku = '');
      return;
    }

    final rand = Random();
    final angka = rand.nextInt(90000) + 10000;
    final parts = [
      if (singkatKategori.isNotEmpty) singkatKategori,
      if (singkatNama.isNotEmpty) singkatNama,
      '$angka',
    ];
    final newPrefix = parts.take(parts.length - 1).join('-');
    final oldPrefix =
        _sku.contains('-') ? _sku.substring(0, _sku.lastIndexOf('-')) : '';
    if (newPrefix != oldPrefix || _sku.isEmpty) {
      setState(() => _sku = parts.join('-'));
    }
  }

  String _generateSku() {
    final kategoriNama = _getSelectedCategoryName();
    final singkatKategori = _singkat(kategoriNama);
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

  String _getSelectedCategoryName() {
    for (var cat in _kategoriList) {
      if (cat['id'] == _selectedCategoryId) return cat['name'] as String;
    }
    return '';
  }

  Future<void> _fetchKategori() async {
    setState(() {
      _loadingKategori = true;
      _kategoriError = null;
    });
    try {
      final response = await ApiService.get('categories');
      List data = [];
      if (response is List) data = response;
      else if (response is Map) {
        data = response['data'] ?? response['categories'] ?? [];
      }
      if (data.isEmpty) {
        setState(() => _kategoriError =
            'Tidak ada kategori. Silakan buat kategori terlebih dahulu.');
      } else {
        setState(() {
          _kategoriList = data
              .map((e) => {
                    'id': e['id'].toString(),
                    'name': e['name'].toString(),
                  })
              .toList();
        });
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _kategoriError = msg.contains('403')
          ? 'Akses ditolak. Hubungi admin untuk menambah kategori.'
          : 'Gagal memuat kategori: $msg');
    } finally {
      setState(() => _loadingKategori = false);
    }
  }

  Future<void> _addCategory(String name) async {
    setState(() => _isAddingCategory = true);
    try {
      final response = await ApiService.post('categories', {'name': name});
      final newCategory = {
        'id': response['id'].toString(),
        'name': response['name'].toString(),
      };
      setState(() {
        _kategoriList.add(newCategory);
        _selectedCategoryId = newCategory['id'];
        if (_kategoriError != null) _kategoriError = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateSku();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Kategori berhasil ditambahkan'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg.contains('403')
              ? 'Akses ditolak. Hanya admin yang dapat menambah kategori.'
              : 'Gagal menambah kategori: $msg'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isAddingCategory = false);
    }
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tambah Kategori Baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'Nama kategori', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context);
                await _addCategory(name);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
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
        'category_id': _selectedCategoryId,
        'description': _deskripsiCtrl.text.trim(),
        '__image_file': _imageFile,
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
    _namaCtrl.removeListener(_onNamaChanged);
    _namaCtrl.dispose();
    _hargaCtrl.dispose();
    _hargaBeliCtrl.dispose();
    _stokCtrl.dispose();
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
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(10)),
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
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue val) {
                  if (val.text.isEmpty) return _namaProdukList;
                  return _namaProdukList.where(
                    (n) => n.toLowerCase().contains(val.text.toLowerCase()),
                  );
                },
                onSelected: (String selected) {
                  _namaCtrl.text = selected;
                  _updateSku();
                  final produkAda = _cariProdukByNama(selected);
                  if (produkAda != null) {
                    Future.delayed(const Duration(milliseconds: 200), () {
                      if (mounted) _showDialogProdukSudahAda(produkAda);
                    });
                  }
                },
                fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                  if (controller.text != _namaCtrl.text) {
                    controller.text = _namaCtrl.text;
                  }
                  controller.addListener(() {
                    if (_namaCtrl.text != controller.text) {
                      _namaCtrl.text = controller.text;
                    }
                  });
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Nama produk wajib diisi'
                        : null,
                    decoration: InputDecoration(
                      hintText: 'Pilih atau ketik nama produk',
                      hintStyle:
                          const TextStyle(color: Colors.grey, fontSize: 13),
                      prefixIcon: const Icon(Icons.label_outline,
                          color: Colors.grey, size: 18),
                      filled: true,
                      fillColor: abukuMuda,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: hijauUtama, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
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
                                    const Icon(Icons.inventory_2_outlined,
                                        size: 16, color: hijauUtama),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(opt,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black87)),
                                    ),
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
              ),
              const SizedBox(height: 16),
              _buildLabel('SKU'),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
                            ? 'Isi nama & pilih kategori untuk generate SKU'
                            : _sku,
                        style: TextStyle(
                          color: _sku.isEmpty ? Colors.grey : hijauUtama,
                          fontWeight: _sku.isEmpty
                              ? FontWeight.normal
                              : FontWeight.bold,
                          fontSize: 13,
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
              _buildLabel('Stok Awal *'),
              const SizedBox(height: 6),
              _buildField(
                controller: _stokCtrl,
                hint: '0',
                icon: Icons.inventory_2_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) =>
                    v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          onChanged: (v) =>
                              setState(() => _selectedSatuan = v),
                          validator: (v) =>
                              v == null ? 'Pilih satuan' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Kategori *'),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(child: _buildKategoriDropdown()),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isAddingCategory
                                    ? null
                                    : _showAddCategoryDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  foregroundColor: Colors.grey.shade700,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                ),
                                child: _isAddingCategory
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Icon(Icons.add, size: 24),
                              ),
                            ),
                          ],
                        ),
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
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 16),
              _buildLabel('Gambar Produk'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _showImagePickerDialog,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: abukuMuda,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _imageFile == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                color: Colors.grey, size: 40),
                            SizedBox(height: 8),
                            Text('Tap untuk pilih gambar',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_imageFile!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 120),
                        ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
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
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
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
                            fontSize: 15),
                      ),
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

  Widget _buildKategoriDropdown() {
    if (_loadingKategori) {
      return const SizedBox(
          height: 50,
          child: Center(child: CircularProgressIndicator()));
    }
    if (_kategoriError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_kategoriError!,
              style: const TextStyle(color: Colors.red, fontSize: 12)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _fetchKategori,
            style:
                ElevatedButton.styleFrom(backgroundColor: hijauUtama),
            child: const Text('Muat Ulang',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    }
    if (_kategoriList.isEmpty) {
      return const Text('Tidak ada kategori.',
          style: TextStyle(color: Colors.red, fontSize: 12));
    }
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      hint: const Text('Pilih Kategori',
          style: TextStyle(color: Colors.grey, fontSize: 13)),
      isExpanded: true,
      items: _kategoriList
          .map((cat) => DropdownMenuItem<String>(
                value: cat['id'],
                child: Text(cat['name'],
                    style: const TextStyle(fontSize: 13)),
              ))
          .toList(),
      onChanged: (value) {
        setState(() => _selectedCategoryId = value);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _updateSku();
        });
      },
      validator: (value) =>
          value == null ? 'Kategori wajib dipilih' : null,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.category_outlined,
            color: Colors.grey, size: 18),
        filled: true,
        fillColor: abukuMuda,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: hijauUtama, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
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
            borderSide: BorderSide.none),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: hijauUtama, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
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
            borderSide: BorderSide.none),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
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
}

// ============================================================
// FORM EDIT PRODUK — Bottom Sheet
// ============================================================
class _FormEditProduk extends StatefulWidget {
  final Produk produk;
  final Future<void> Function(Map<String, dynamic> data) onSimpan;

  const _FormEditProduk({
    required this.produk,
    required this.onSimpan,
  });

  @override
  State<_FormEditProduk> createState() => _FormEditProdukState();
}

class _FormEditProdukState extends State<_FormEditProduk> {
  static const Color hijauUtama = Color(0xFF059669);
  static const Color hijauMuda = Color(0xFFD1FAE5);
  static const Color merahTeks = Color(0xFFD32F2F);
  static const Color abukuMuda = Color(0xFFF3F4F6);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaCtrl;
  late final TextEditingController _hargaCtrl;
  late final TextEditingController _hargaBeliCtrl;
  late final TextEditingController _stokCtrl;
  late final TextEditingController _deskripsiCtrl;
  late final TextEditingController _skuCtrl;

  String? _selectedSatuan;
  String? _selectedCategoryId;
  List<Map<String, dynamic>> _kategoriList = [];
  bool _loadingKategori = false;
  String? _kategoriError;
  bool _isAddingCategory = false;
  bool _isSaving = false;

  File? _imageFile;
  bool _imageHapus = false;
  final ImagePicker _picker = ImagePicker();

  static const List<String> _listSatuan = [
    'pcs', 'kg', 'gram', 'liter', 'ml', 'botol', 'dus', 'karton', 'lusin', 'meter',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.produk;
    _namaCtrl = TextEditingController(text: p.nama);
    _hargaCtrl = TextEditingController(text: p.hargaJual?.toString() ?? '');
    _hargaBeliCtrl = TextEditingController(text: p.hargaBeli?.toString() ?? '');
    _stokCtrl = TextEditingController(text: p.stok.toString());
    _deskripsiCtrl = TextEditingController(text: p.deskripsi ?? '');
    _skuCtrl = TextEditingController(text: p.sku);

    _selectedSatuan = _listSatuan.contains(p.satuan) ? p.satuan : null;
    _selectedCategoryId = p.categoryId.isNotEmpty ? p.categoryId : null;

    _fetchKategori();
  }

  // ── SKU helpers ──
  String _singkat(String teks) {
    if (teks.trim().isEmpty) return '';
    final kata = teks.trim().split(RegExp(r'\s+'));
    if (kata.length == 1) {
      return kata[0].substring(0, kata[0].length.clamp(0, 3)).toUpperCase();
    }
    return kata.take(3).map((k) => k.isNotEmpty ? k[0].toUpperCase() : '').join();
  }

  String _getSelectedCategoryName() {
    for (var cat in _kategoriList) {
      if (cat['id'] == _selectedCategoryId) return cat['name'] as String;
    }
    return '';
  }

  String _generateSku() {
    final singkatKategori = _singkat(_getSelectedCategoryName());
    final singkatNama = _singkat(_namaCtrl.text);
    final angka = Random().nextInt(90000) + 10000;
    final parts = [
      if (singkatKategori.isNotEmpty) singkatKategori,
      if (singkatNama.isNotEmpty) singkatNama,
      '$angka',
    ];
    return parts.join('-');
  }

  // ── Kategori ──
  Future<void> _fetchKategori() async {
    setState(() {
      _loadingKategori = true;
      _kategoriError = null;
    });
    try {
      final response = await ApiService.get('categories');
      List data = [];
      if (response is List) data = response;
      else if (response is Map) {
        data = response['data'] ?? response['categories'] ?? [];
      }
      setState(() {
        _kategoriList = data
            .map((e) => {
                  'id': e['id'].toString(),
                  'name': e['name'].toString(),
                })
            .toList();
      });
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _kategoriError = msg.contains('403')
          ? 'Akses ditolak. Hubungi admin.'
          : 'Gagal memuat kategori: $msg');
    } finally {
      setState(() => _loadingKategori = false);
    }
  }

  Future<void> _addCategory(String name) async {
    setState(() => _isAddingCategory = true);
    try {
      final response = await ApiService.post('categories', {'name': name});
      final newCategory = {
        'id': response['id'].toString(),
        'name': response['name'].toString(),
      };
      setState(() {
        _kategoriList.add(newCategory);
        _selectedCategoryId = newCategory['id'];
        _kategoriError = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Kategori berhasil ditambahkan'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg.contains('403')
              ? 'Akses ditolak. Hanya admin yang dapat menambah kategori.'
              : 'Gagal menambah kategori: $msg'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isAddingCategory = false);
    }
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tambah Kategori Baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'Nama kategori', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context);
                await _addCategory(name);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ── Gambar ──
  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _imageHapus = false;
      });
    }
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (widget.produk.imageUrl != null || _imageFile != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Hapus Gambar',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imageFile = null;
                    _imageHapus = true;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── Submit ──
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.onSimpan({
        'sku': _skuCtrl.text.trim(),
        'name': _namaCtrl.text.trim(),
        'selling_price': double.tryParse(_hargaCtrl.text.trim()) ?? 0,
        'purchase_price': double.tryParse(_hargaBeliCtrl.text.trim()) ?? 0,
        'stock': int.tryParse(_stokCtrl.text.trim()) ?? 0,
        'unit': _selectedSatuan ?? '',
        'category_id': _selectedCategoryId,
        'description': _deskripsiCtrl.text.trim(),
        'remove_image': _imageHapus,
        '__image_file': _imageFile,
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
    _namaCtrl.dispose();
    _hargaCtrl.dispose();
    _hargaBeliCtrl.dispose();
    _stokCtrl.dispose();
    _deskripsiCtrl.dispose();
    _skuCtrl.dispose();
    super.dispose();
  }

  // ── Preview gambar ──
  Widget _buildImagePreview() {
    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(_imageFile!,
            fit: BoxFit.cover, width: double.infinity, height: 120),
      );
    }
    if (!_imageHapus && widget.produk.imageUrl != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.produk.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _imagePlaceholder(),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: const Text('Tap untuk ganti gambar',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
        ],
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, color: Colors.grey, size: 40),
        SizedBox(height: 8),
        Text('Tap untuk pilih gambar', style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildKategoriDropdown() {
    if (_loadingKategori) {
      return const SizedBox(
          height: 50, child: Center(child: CircularProgressIndicator()));
    }
    if (_kategoriError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_kategoriError!,
              style: const TextStyle(color: Colors.red, fontSize: 12)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _fetchKategori,
            style: ElevatedButton.styleFrom(backgroundColor: hijauUtama),
            child: const Text('Muat Ulang',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    }
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      hint: const Text('Pilih Kategori',
          style: TextStyle(color: Colors.grey, fontSize: 13)),
      isExpanded: true,
      items: _kategoriList
          .map((cat) => DropdownMenuItem<String>(
                value: cat['id'],
                child: Text(cat['name'],
                    style: const TextStyle(fontSize: 13)),
              ))
          .toList(),
      onChanged: (value) => setState(() => _selectedCategoryId = value),
      validator: (value) => value == null ? 'Kategori wajib dipilih' : null,
      decoration: InputDecoration(
        prefixIcon:
            const Icon(Icons.category_outlined, color: Colors.grey, size: 18),
        filled: true,
        fillColor: abukuMuda,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: hijauUtama, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87));

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
            borderSide: BorderSide.none),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: hijauUtama, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
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
            borderSide: BorderSide.none),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
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
              // ── Handle bar ──
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),

              // ── Header ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: hijauMuda,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.edit_outlined,
                        color: hijauUtama, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Edit Produk',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        Text(widget.produk.nama,
                            style:
                                const TextStyle(fontSize: 12, color: Colors.grey),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Nama Produk ──
              _buildLabel('Nama Produk *'),
              const SizedBox(height: 6),
              _buildField(
                controller: _namaCtrl,
                hint: 'Nama produk',
                icon: Icons.label_outline,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Nama produk wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),

              // ── SKU ──
              _buildLabel('SKU'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: _skuCtrl.text.isEmpty ? abukuMuda : hijauMuda,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.qr_code_2_outlined,
                              color: _skuCtrl.text.isEmpty
                                  ? Colors.grey
                                  : hijauUtama,
                              size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _skuCtrl.text.isEmpty ? 'SKU kosong' : _skuCtrl.text,
                              style: TextStyle(
                                color: _skuCtrl.text.isEmpty
                                    ? Colors.grey
                                    : hijauUtama,
                                fontWeight: _skuCtrl.text.isEmpty
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _skuCtrl.text = _generateSku()),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: hijauMuda,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          color: hijauUtama, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Harga Jual & Harga Beli ──
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

              // ── Stok ──
              _buildLabel('Stok *'),
              const SizedBox(height: 6),
              _buildField(
                controller: _stokCtrl,
                hint: '0',
                icon: Icons.inventory_2_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) =>
                    v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // ── Satuan & Kategori ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          onChanged: (v) =>
                              setState(() => _selectedSatuan = v),
                          validator: (v) =>
                              v == null ? 'Pilih satuan' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Kategori *'),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(child: _buildKategoriDropdown()),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isAddingCategory
                                    ? null
                                    : _showAddCategoryDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: abukuMuda,
                                  foregroundColor: Colors.grey.shade700,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                ),
                                child: _isAddingCategory
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Icon(Icons.add, size: 24),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Deskripsi ──
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
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 16),

              // ── Gambar Produk ──
              _buildLabel('Gambar Produk'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _showImagePickerDialog,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: abukuMuda,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _buildImagePreview(),
                ),
              ),

              // Info hapus gambar
              if (_imageHapus)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 14, color: merahTeks),
                      const SizedBox(width: 6),
                      const Text('Gambar akan dihapus saat disimpan.',
                          style: TextStyle(color: merahTeks, fontSize: 12)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _imageHapus = false),
                        child: const Text('Batalkan',
                            style: TextStyle(
                                color: hijauUtama,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 28),

              // ── Tombol Batal & Simpan ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
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
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
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
                        _isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
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
}