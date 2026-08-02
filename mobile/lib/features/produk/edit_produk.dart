import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_service.dart';
import '../../models/produk.dart';



class FormEditProduk extends StatefulWidget {
  final Produk produk;
  final Future<void> Function(Map<String, dynamic> data) onSimpan;

  const FormEditProduk({
    required this.produk,
    required this.onSimpan,
  });

  @override
  State<FormEditProduk> createState() => _FormEditProdukState();
}

class _FormEditProdukState extends State<FormEditProduk> {
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
    'pcs',
    'kg',
    'gram',
    'liter',
    'ml',
    'botol',
    'dus',
    'karton',
    'lusin',
    'meter',
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
    return kata
        .take(3)
        .map((k) => k.isNotEmpty ? k[0].toUpperCase() : '')
        .join();
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
      if (response is List)
        data = response;
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
            child:
                const Text('Muat Ulang', style: TextStyle(color: Colors.white)),
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
                child: Text(cat['name'], style: const TextStyle(fontSize: 13)),
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
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
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
                              _skuCtrl.text.isEmpty
                                  ? 'SKU kosong'
                                  : _skuCtrl.text,
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
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // ── Satuan di atas, Kategori di bawah ──
              Column(
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
                    validator: (v) => v == null ? 'Pilih satuan' : null,
                  ),
                  const SizedBox(height: 12),
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
                          onPressed: _isAddingCategory ? null : _showAddCategoryDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: abukuMuda,
                            foregroundColor: Colors.grey.shade700,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: _isAddingCategory
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.add, size: 24),
                        ),
                      ),
                    ],
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
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
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
