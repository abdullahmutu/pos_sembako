// lib/features/produk/produk_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/api/api_service.dart';
import '../../models/produk.dart';

import 'tambah_produk_screen.dart';
import 'edit_produk.dart';

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
  String? _errorMessage;
  String? _highlightedProdukId;

  @override
  void initState() {
    super.initState();
    _fetchProduk();
  }

  Future<void> _fetchProduk() async {
    setState(() {
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
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ── Buka form tambah produk (tetap ada di header) ──
  void _bukaFormTambahProduk() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TambahProdukPage(
          semuaProduk: _semuaProduk,
          onSavedCallback: () async {
            await _fetchProduk();
          },
        ),
      ),
    );
  }

  // ── Buka form edit ──
  void _bukaFormEditProduk(Produk produk) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FormEditProduk(
        produk: produk,
        onSimpan: (data) async {
          final imageFile = data.remove('__image_file') as File?;
          final hapusGambar = data.remove('remove_image') as bool? ?? false;

          if (imageFile != null) {
            final fields = data.map((k, v) => MapEntry(k, v.toString()));
            await ApiService.putMultipart('products/${produk.id}', fields, imageFile);
          } else {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: _errorMessage != null ? _buildError() : _buildKonten(),
          ),
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
            Text(_errorMessage ?? 'Terjadi kesalahan',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchProduk,
              style: ElevatedButton.styleFrom(backgroundColor: hijauUtama),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
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
        controller: _scroll_controller_isFixed(),
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

  // Helper to ensure correct controller reference (avoids accidental typos)
  ScrollController _scroll_controller_isFixed() => _scrollController;

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
            Text('Produk',
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                const Icon(Icons.inventory_2_outlined, color: Colors.white70, size: 20),
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
                const Icon(Icons.warning_amber_rounded, color: merahTeks, size: 20),
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
          child: Text('Produk tidak ditemukan.', style: TextStyle(color: Colors.grey)),
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
        border: isHighlighted ? Border.all(color: hijauUtama, width: 1.5) : Border.all(color: Colors.transparent),
      ),
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: isHighlighted ? 8 : 0),
      child: Row(
        children: [
          // Gambar produk
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 70,
              height: 70,
              color: abukuMuda,
              child: produk.imageUrl != null
                  ? Image.network(produk.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 30))
                  : const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 30),
            ),
          ),
          const SizedBox(width: 14),

          // Info produk
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(produk.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                const SizedBox(height: 2),
                Text('${produk.kategori} • ${produk.satuan}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: lowStock ? merahMuda : hijauMuda,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Stok: ${produk.stok}',
                      style: TextStyle(color: lowStock ? merahTeks : hijauUtama, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          // Tombol Edit
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
              child: const Icon(Icons.edit_outlined, color: Colors.grey, size: 16),
            ),
          ),

          // No add/remove controls shown
          const SizedBox(width: 8),
        ],
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
