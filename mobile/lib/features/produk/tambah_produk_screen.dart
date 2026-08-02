// lib/features/produk/tambah_produk_screen.dart
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/produk.dart';
import '../../core/api/api_service.dart';
import 'tambah_produk_baru.dart';

class TambahProdukPage extends StatelessWidget {
  final List<Produk> semuaProduk;
  final Future<void> Function()? onSavedCallback;

  const TambahProdukPage({
    required this.semuaProduk,
    this.onSavedCallback,
    super.key,
  });

  static const Color kDrawerBg = Color(0xFFE8F5F0);
  static const Color kAccent = Color(0xFF059669);
  static const Color kTextPrimary = Color(0xFF111827);
  static const Color kCardBg = Color(0xFFF3F4F6);

  @override
  Widget build(BuildContext context) {
    final GlobalKey<_FormTambahProdukBodyState> formKey = GlobalKey<_FormTambahProdukBodyState>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        title: const Text(
          'Tambah Produk',
          style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _FormTambahProdukBody(
                      key: formKey,
                      semuaProduk: semuaProduk,
                      // onSaved SATU-SATUNYA tempat yang melakukan pop + refresh.
                      // _submit() TIDAK BOLEH memanggil pop lagi setelah ini.
                      onSaved: () async {
                        if (onSavedCallback != null) await onSavedCallback!();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('Simpan Nota',
                            style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12)),
                        SizedBox(height: 4),
                        Text('Tekan untuk menyimpan nota dan memperbarui stok',
                            style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      formKey.currentState?.submit();
                    },
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text('Simpan', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TambahProdukPage.kAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormTambahProdukBody extends StatefulWidget {
  final List<Produk> semuaProduk;
  final Future<void> Function() onSaved;
  const _FormTambahProdukBody({
    required this.semuaProduk,
    required this.onSaved,
    super.key,
  });

  @override
  State<_FormTambahProdukBody> createState() => _FormTambahProdukBodyState();
}

class _ItemRow {
  Produk? produk;
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();

  void dispose() {
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

class _FormTambahProdukBodyState extends State<_FormTambahProdukBody> {
  static const Color kCardBg = Color(0xFFF3F4F6);

  final _formKey = GlobalKey<FormState>();
  File? _notaImage;
  final ImagePicker _picker = ImagePicker();

  bool _isSubmitting = false;

  final TextEditingController _supplierCtrl = TextEditingController();
  final TextEditingController _nomorCtrl = TextEditingController();
  DateTime _tanggal = DateTime.now();
  final TextEditingController _catatanCtrl = TextEditingController();

  final List<_ItemRow> _items = [];

  @override
  void initState() {
    super.initState();
    _addEmptyRow();
  }

  @override
  void dispose() {
    for (final r in _items) {
      r.dispose();
    }
    _supplierCtrl.dispose();
    _nomorCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  void _addEmptyRow() => setState(() => _items.add(_ItemRow()));

  Future<bool> _ensureCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      if (status.isGranted) return true;

      if (status.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin kamera diblokir. Buka pengaturan aplikasi untuk mengizinkan.'),
            action: SnackBarAction(label: 'Buka Pengaturan', onPressed: openAppSettings),
          ),
        );
        return false;
      }

      final result = await Permission.camera.request();
      if (result.isGranted) return true;

      if (result.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin kamera diblokir. Buka pengaturan aplikasi untuk mengizinkan.'),
            action: SnackBarAction(label: 'Buka Pengaturan', onPressed: openAppSettings),
          ),
        );
        return false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin kamera diperlukan untuk mengambil foto')),
      );
      return false;
    } catch (e, st) {
      debugPrint('ensureCameraPermission error: $e\n$st');
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memeriksa izin kamera: $e')),
      );
      return false;
    }
  }

  Future<bool> _ensureGalleryPermission() async {
    try {
      if (Platform.isIOS) {
        final status = await Permission.photos.status;
        if (status.isGranted) return true;
        if (status.isPermanentlyDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin galeri diblokir. Buka pengaturan aplikasi untuk mengizinkan.'),
              action: SnackBarAction(label: 'Buka Pengaturan', onPressed: openAppSettings),
            ),
          );
          return false;
        }
        final result = await Permission.photos.request();
        return result.isGranted;
      } else {
        final status = await Permission.storage.status;
        if (status.isGranted) return true;
        if (status.isPermanentlyDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin penyimpanan diblokir. Buka pengaturan aplikasi untuk mengizinkan.'),
              action: SnackBarAction(label: 'Buka Pengaturan', onPressed: openAppSettings),
            ),
          );
          return false;
        }
        final result = await Permission.storage.request();
        return result.isGranted;
      }
    } catch (e, st) {
      debugPrint('ensureGalleryPermission error: $e\n$st');
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memeriksa izin galeri: $e')));
      return false;
    }
  }

  Future<void> _pickFromCamera() async {
    if (!await _ensureCameraPermission()) return;
    try {
      debugPrint('Opening camera...');
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      debugPrint('pickImage result: $picked');
      if (picked != null && mounted) {
        setState(() => _notaImage = File(picked.path));
      }
    } catch (e, st) {
      debugPrint('pickFromCamera error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuka kamera: $e')));
    }
  }

  Future<void> _pickFromGallery() async {
    if (!await _ensureGalleryPermission()) return;
    try {
      debugPrint('Opening gallery...');
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      debugPrint('pickGallery result: $picked');
      if (picked != null && mounted) {
        setState(() => _notaImage = File(picked.path));
      }
    } catch (e, st) {
      debugPrint('pickFromGallery error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memilih dari galeri: $e')));
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: false,
      );
      if (result == null) {
        debugPrint('User cancelled file picking');
        return;
      }
      final path = result.files.single.path;
      if (path != null && mounted) {
        setState(() => _notaImage = File(path));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mendapatkan file path')));
      }
    } catch (e, st) {
      debugPrint('pickFile error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memilih file: $e')));
    }
  }

  Future<void> _openTambahProduk() async {
    try {
      debugPrint('Opening add product screen...');
      final Produk? produkBaru = await Navigator.of(context).push<Produk?>(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text('Tambah Produk Baru'),
              backgroundColor: TambahProdukPage.kCardBg,
              iconTheme: const IconThemeData(color: TambahProdukPage.kAccent),
            ),
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: FormTambahProduk(
                  semuaProduk: widget.semuaProduk,
                  onProdukSudahAda: (produk) {
                    Navigator.of(context).pop(null);
                  },
                ),
              ),
            ),
          ),
        ),
      );

      debugPrint('Returned from add product: $produkBaru');

      if (!mounted) return;
      if (produkBaru != null) {
        try {
          // Tambah produk ke daftar lokal
          setState(() {
            widget.semuaProduk.add(produkBaru);
          });

          // Pastikan ada baris item untuk menaruh produk
          if (_items.isEmpty) {
            _addEmptyRow();
          }

          // Ambil referensi ke baris terakhir (baru dibuat jika perlu)
          final targetRow = _items.last;

          // Set produk pada row (boleh dilakukan di setState)
          setState(() {
            targetRow.produk = produkBaru;
          });

          // Jadwalkan assignment controller setelah frame selesai
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              if (!mounted) return;
              if (_items.isEmpty) return;
              final lastRow = _items.last;
              if (lastRow.priceCtrl.text.trim().isEmpty && produkBaru.hargaBeli != null) {
                lastRow.priceCtrl.text = produkBaru.hargaBeli!.toString();
              }
              // Isi "Jumlah masuk" dengan Stok Awal dari form produk baru.
              // Fallback ke '1' hanya kalau stok awal-nya 0/kosong,
              // supaya validator (harus > 0) tidak langsung gagal.
              if (lastRow.qtyCtrl.text.trim().isEmpty) {
                lastRow.qtyCtrl.text = produkBaru.stok > 0 ? produkBaru.stok.toString() : '1';
              }
            } catch (e, st) {
              debugPrint('Error in postFrame assignment: $e\n$st');
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Produk "${produkBaru.nama}" ditambahkan ke nota'),
              backgroundColor: TambahProdukPage.kAccent,
            ),
          );
        } catch (e, st) {
          debugPrint('Error while applying produkBaru to UI: $e\n$st');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menambahkan produk ke nota: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e, st) {
      debugPrint('Error in _openTambahProduk: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan saat membuka form produk: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return; // cegah double-tap tombol simpan
    if (!_formKey.currentState!.validate()) return;
    if (_notaImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload foto nota terlebih dahulu')));
      return;
    }

    setState(() => _isSubmitting = true);

    final itemsPayload = <Map<String, dynamic>>[];
    // Sebelum membuat payload, jika ada produk lokal (id == null) -> buat produk di server dulu
    for (final r in _items) {
      if (r.produk == null) continue;
      final qty = int.tryParse(r.qtyCtrl.text.trim()) ?? 0;
      if (qty <= 0) continue;

      // Jika produk lokal (belum punya id), buat dulu di server
      if (r.produk!.id == null) {
        try {
          final createBody = r.produk!.toJsonForCreate();

          createBody['skip_purchase_record'] = '1';
          // produkBaru.imageUrl berisi PATH LOKAL file gambar (bukan URL server),
          // karena FormTambahProduk hanya menyimpan _imageFile.path.
          // toJsonForCreate() TIDAK menyertakan file ini (hanya teks biasa),
          // jadi kalau dikirim lewat ApiService.post biasa, gambar tidak akan
          // pernah terupload dan kolom image di DB tetap null.
          // Solusi: deteksi apakah imageUrl adalah path file lokal yang valid,
          // lalu kirim via endpoint multipart (postMultipart) agar file
          // benar-benar terupload bersamaan dengan data produk.
          File? gambarUntukUpload;
          final localImagePath = r.produk!.imageUrl;
          if (localImagePath != null &&
              localImagePath.isNotEmpty &&
              !localImagePath.startsWith('http')) {
            final f = File(localImagePath);
            if (await f.exists()) {
              gambarUntukUpload = f;
            }
          }

          dynamic created;
          if (gambarUntukUpload != null) {
            created = await ApiService.postMultipart('products', createBody, gambarUntukUpload);
          } else {
            created = await ApiService.post('products', createBody);
          }

          Map<String, dynamic> createdData;
          if (created is Map && created.containsKey('data')) {
            createdData = Map<String, dynamic>.from(created['data']);
          } else if (created is Map) {
            createdData = Map<String, dynamic>.from(created);
          } else {
            throw Exception('Response tidak valid saat membuat produk');
          }
          final newProduk = Produk.fromJson(createdData);
          // update objek produk lokal dengan id baru
          r.produk = newProduk;
          // juga tambahkan ke daftar semuaProduk agar bisa dicari
          setState(() {
            widget.semuaProduk.add(newProduk);
          });

          // PENTING: produk baru ini sudah dibuat dengan "Stok Awal" yang benar
          // (lihat toJsonForCreate() -> field 'stock'), jadi item ini TIDAK
          // boleh menambah stok lagi di stock_invoices (kalau ditambah lagi,
          // stok akan dobel: stok awal + quantity nota).
          //
          // TAPI item ini tetap harus tercatat sebagai transaksi pembelian &
          // pengeluaran (Purchase + Expenditure) — sebelumnya baris ini
          // di-skip total dari itemsPayload, sehingga uang yang dikeluarkan
          // untuk stok awal produk baru TIDAK PERNAH muncul di halaman
          // Pengeluaran admin. Sekarang tetap dikirim, hanya dengan flag
          // 'skip_stock_update' supaya backend tahu untuk tidak menambah
          // stok lagi, tapi tetap mencatat PurchaseItem & Expenditure-nya.
          itemsPayload.add({
            'product_id': r.produk!.id,
            'quantity': qty,
            'purchase_price': double.tryParse(r.priceCtrl.text.trim()) ?? r.produk!.hargaBeli ?? 0,
            'skip_stock_update': true,
          });
          continue;
        } catch (e, st) {
          debugPrint('Gagal membuat produk sebelum submit nota: $e\n$st');
          if (mounted) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat produk: $e'), backgroundColor: Colors.red));
          }
          return;
        }
      }

      // Produk yang SUDAH ADA sebelumnya (dipilih via Autocomplete, bukan
      // baru dibuat di sesi ini) dikirim sebagai item nota biasa, sehingga
      // stoknya benar ditambah sesuai jumlah masuk.
      itemsPayload.add({
        'product_id': r.produk!.id,
        'quantity': qty,
        'purchase_price': double.tryParse(r.priceCtrl.text.trim()) ?? r.produk!.hargaBeli ?? 0,
      });
    }

    if (itemsPayload.isEmpty) {
      // Semua item (termasuk produk baru) sekarang selalu masuk ke
      // itemsPayload, jadi ini hanya terjadi kalau tidak ada satupun baris
      // valid (qty > 0 dan produk terisi) sama sekali.
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tambahkan minimal 1 item')));
      return;
    }

    final body = {
      'supplier': _supplierCtrl.text.trim(),
      'nomor_nota': _nomorCtrl.text.trim(),
      'tanggal': _tanggal.toIso8601String(),
      'catatan': _catatanCtrl.text.trim(),
      'items': jsonEncode(itemsPayload),
    };

    try {
      final fields = body.map((k, v) => MapEntry(k, v.toString()));
      // PENTING: backend (StockInvoiceController@store) memvalidasi &
      // mencari file dengan nama field 'receipt_image', BUKAN 'image'.
      // Kalau fileFieldName tidak diisi eksplisit di sini, ApiService akan
      // pakai default 'image' dan Laravel tidak akan melihat file ini sama
      // sekali (hasFile('receipt_image') selalu false), sehingga request
      // tetap sukses tapi kolom receipt_image di DB tetap NULL.
      await ApiService.postMultipart(
        'stock_invoices',
        fields,
        _notaImage!,
        fileFieldName: 'receipt_image',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Nota berhasil disimpan'), backgroundColor: TambahProdukPage.kAccent),
      );

      // PENTING: onSaved() SUDAH menangani refresh data (onSavedCallback)
      // DAN menutup halaman ini (Navigator.pop()).
      // Jangan panggil Navigator.pop() lagi setelah baris ini —
      // itu penyebab layar hitam sebelumnya (pop dobel).
      await widget.onSaved();
    } catch (e, st) {
      debugPrint('Error saat submit nota: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void submit() => _submit();

  Widget _buildItemCard(int index) {
    final row = _items[index];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Autocomplete<Produk>(
              optionsBuilder: (TextEditingValue text) {
                final q = text.text.toLowerCase();
                return widget.semuaProduk.where((p) => p.nama.toLowerCase().contains(q));
              },
              displayStringForOption: (p) => p.nama,
              onSelected: (p) {
                setState(() {
                  row.produk = p;
                  if (row.priceCtrl.text.trim().isEmpty && p.hargaBeli != null) {
                    row.priceCtrl.text = p.hargaBeli!.toString();
                  }
                });
              },
              fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                // Jangan panggil setState di sini; hanya sinkronisasi controller
                if (row.produk != null && controller.text != row.produk!.nama) {
                  // assign text tanpa setState
                  controller.text = row.produk!.nama;
                }
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(labelText: 'Produk'),
                  validator: (v) => (row.produk == null) ? 'Pilih produk' : null,
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: row.qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Jumlah masuk'),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Masukkan jumlah > 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: row.priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Harga beli (opsional)'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      row.dispose();
                      _items.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Card(
              color: kCardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.black54),
                title: const Text('Foto Nota / Bukti'),
                subtitle: _notaImage == null ? const Text('Belum ada foto') : null,
                trailing: ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.camera_alt),
                              title: const Text('Ambil Foto'),
                              onTap: () {
                                Navigator.of(ctx).pop();
                                _pickFromCamera();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('Pilih dari Galeri'),
                              onTap: () {
                                Navigator.of(ctx).pop();
                                _pickFromGallery();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.attach_file),
                              title: const Text('Pilih File'),
                              onTap: () {
                                Navigator.of(ctx).pop();
                                _pickFile();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.add_box_outlined),
                              title: const Text('Produk Baru'),
                              onTap: () {
                                Navigator.of(ctx).pop();
                                _openTambahProduk();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.close),
                              title: const Text('Batal'),
                              onTap: () => Navigator.of(ctx).pop(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Ambil Foto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TambahProdukPage.kAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_notaImage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_notaImage!, height: 140, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(controller: _supplierCtrl, decoration: const InputDecoration(labelText: 'Supplier')),
            const SizedBox(height: 8),
            TextFormField(controller: _nomorCtrl, decoration: const InputDecoration(labelText: 'Nomor Nota')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('Tanggal: ${_tanggal.toLocal().toString().split(' ')[0]}')),
                TextButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _tanggal,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (d != null && mounted) setState(() => _tanggal = d);
                  },
                  child: const Text('Pilih Tanggal'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(controller: _catatanCtrl, decoration: const InputDecoration(labelText: 'Catatan (opsional)')),
            const SizedBox(height: 12),
            Column(children: List.generate(_items.length, (i) => _buildItemCard(i))),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _addEmptyRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TambahProdukPage.kAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _openTambahProduk,
                  icon: const Icon(Icons.add_box_outlined),
                  label: const Text('Produk Baru'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TambahProdukPage.kAccent,
                    side: const BorderSide(color: TambahProdukPage.kAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}