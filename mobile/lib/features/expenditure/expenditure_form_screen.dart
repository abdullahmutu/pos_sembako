// lib/features/expenditure/expenditure_form_screen.dart
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_service.dart';
import '../../utils/format_helper.dart'; // parseDateOnly() agar tanggal tidak mundur akibat parsing UTC

class ExpenditureFormScreen extends StatefulWidget {
  /// Pass an existing expenditure map to edit it, or leave null to create a new one.
  final Map<String, dynamic>? expenditure;

  const ExpenditureFormScreen({super.key, this.expenditure});

  @override
  State<ExpenditureFormScreen> createState() => _ExpenditureFormScreenState();
}

/// Satu baris item pembelian yang terkait dengan purchase yang dikaitkan.
/// Dipakai untuk mengoreksi qty / harga beli yang salah input waktu di
/// halaman "Tambah Produk", tanpa harus buka halaman terpisah.
class _PurchaseItemRow {
  final int? id; // id PurchaseItem di backend (null kalau baris baru, tidak dipakai di sini)
  final int productId;
  final String productName;
  final int originalQuantity;
  final double originalPrice;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;

  _PurchaseItemRow({
    required this.id,
    required this.productId,
    required this.productName,
    required this.originalQuantity,
    required this.originalPrice,
  })  : qtyCtrl = TextEditingController(text: originalQuantity.toString()),
        priceCtrl = TextEditingController(text: originalPrice.toStringAsFixed(0));

  bool get isDirty {
    final qty = int.tryParse(qtyCtrl.text.trim()) ?? originalQuantity;
    final price = double.tryParse(priceCtrl.text.trim()) ?? originalPrice;
    return qty != originalQuantity || price != originalPrice;
  }

  Map<String, dynamic> toPayload() {
    return {
      'id': id,
      'product_id': productId,
      'quantity': int.tryParse(qtyCtrl.text.trim()) ?? originalQuantity,
      'purchase_price': double.tryParse(priceCtrl.text.trim()) ?? originalPrice,
    };
  }

  void dispose() {
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

class _ExpenditureFormScreenState extends State<ExpenditureFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _amountController;
  DateTime _expenseDate = DateTime.now();

  bool _isSaving = false;

  // ── Kaitan pembelian ──
  bool _isLoadingPurchases = true;
  List<Map<String, dynamic>> _purchases = [];
  int? _selectedPurchaseId;

  // ── Detail item pembelian (untuk koreksi qty/harga dari "Tambah Produk") ──
  bool _isLoadingItems = false;
  List<_PurchaseItemRow> _purchaseItemRows = [];
  String? _purchaseItemsError;

  // ── Nota / receipt ──
  File? _pickedReceiptFile; // foto baru yang dipilih user (belum diupload)
  String? _existingReceiptUrl; // url nota yang sudah ada dari purchase terkait

  bool get _isEditing => widget.expenditure != null;

  @override
  void initState() {
    super.initState();
    final exp = widget.expenditure;
    _descriptionController =
        TextEditingController(text: exp?['description']?.toString() ?? '');
    _categoryController =
        TextEditingController(text: exp?['category']?.toString() ?? '');

    final rawAmount = exp?['amount'];
    // FIX: backend mengirim 'amount' sebagai STRING berdesimal, misalnya
    // "362500.00" (bukan tipe double). Sebelumnya kondisi `rawAmount is
    // double` tidak pernah true untuk kasus ini, jadi jatuh ke
    // `.toString()` polos yang MEMPERTAHANKAN ".00" di teks controller.
    // Di tempat lain (saat mengirim ke backend & saat membandingkan
    // header berubah/tidak), teks ini diproses dengan
    // `.replaceAll('.', '')` yang menghapus SEMUA titik termasuk titik
    // desimal — sehingga "362500.00" salah menjadi "36250000" (x100).
    // Akibatnya nilai "amount" yang tidak diubah user dianggap berubah,
    // dan form terus mencoba update header padahal tidak perlu.
    // Sekarang selalu di-parse jadi angka dulu lalu dibulatkan ke string
    // tanpa desimal, apa pun tipe aslinya (int/double/String).
    final amountValue = rawAmount == null
        ? ''
        : (double.tryParse(rawAmount.toString())?.toStringAsFixed(0) ??
            rawAmount.toString());
    _amountController = TextEditingController(text: amountValue);

    if (exp?['expense_date'] != null) {
      _expenseDate = parseDateOnly(exp!['expense_date'].toString());
    }

    _selectedPurchaseId = exp?['purchase_id'] is int
        ? exp!['purchase_id'] as int
        : int.tryParse(exp?['purchase_id']?.toString() ?? '');

    // Kalau data expenditure sudah membawa relasi 'purchase' (dari
    // ->load('purchase') di backend) dan punya receipt_image, tampilkan
    // preview nota yang sudah ada.
    final purchase = exp?['purchase'];
    if (purchase is Map && purchase['receipt_url'] != null) {
      _existingReceiptUrl = purchase['receipt_url'].toString();
    }

    _loadPurchases();

    // Kalau expenditure yang diedit sudah terkait purchase, langsung muat
    // detail itemnya supaya bisa dikoreksi.
    if (_selectedPurchaseId != null) {
      _loadPurchaseItems(_selectedPurchaseId!);
    }
  }

  Future<void> _loadPurchases({String? search}) async {
    setState(() => _isLoadingPurchases = true);
    try {
      final query = search != null && search.isNotEmpty
          ? 'expenditures/purchases-lookup?search=$search'
          : 'expenditures/purchases-lookup';
      final response = await ApiService.get(query);
      final List raw = response is List ? response : (response['data'] ?? []);
      final parsed = raw.map((e) => Map<String, dynamic>.from(e)).toList();

      if (!mounted) return;
      setState(() {
        _purchases = parsed;
        _isLoadingPurchases = false;

        // Kalau expenditure yang sedang diedit sudah punya purchase_id
        // tapi _existingReceiptUrl belum terisi dari relasi 'purchase'
        // (misalnya backend tidak mengirim ->load('purchase')), coba
        // ambil dari daftar lookup yang baru saja dimuat.
        if (_selectedPurchaseId != null && _existingReceiptUrl == null) {
          final match = _findPurchaseById(_selectedPurchaseId);
          if (match != null && match['receipt_url'] != null) {
            _existingReceiptUrl = match['receipt_url'].toString();
          }
        }
      });
    } catch (e) {
      debugPrint('Load purchases error: $e');
      if (!mounted) return;
      setState(() => _isLoadingPurchases = false);
    }
  }

  /// Ambil detail item (produk, qty, harga beli) dari purchase yang
  /// dikaitkan, supaya bisa dikoreksi kalau salah input di "Tambah Produk".
  ///
  /// Route: GET stock_invoices/{purchase} -> StockInvoiceController@show,
  /// yang mengembalikan Purchase dengan relasi 'items.product' ter-load
  /// (bukan field flat 'product_name'). Struktur tiap item kira-kira:
  /// {
  ///   "id": 1,
  ///   "product_id": 5,
  ///   "quantity": 25,
  ///   "purchase_price": "12000",
  ///   "product": { "id": 5, "name": "Gulaku 1kg", ... }
  /// }
  ///
  /// FIX: sebelumnya nama produk dibaca dari item['product_name'], yang
  /// TIDAK PERNAH dikirim backend (makanya selalu jatuh ke fallback
  /// 'Produk' di UI, padahal halaman admin—yang membaca $item->product->name
  /// lewat relasi Eloquent—bisa menampilkan nama produk dengan benar).
  /// Sekarang dibaca dari relasi item['product']['name'].
  Future<void> _loadPurchaseItems(int purchaseId) async {
    setState(() {
      _isLoadingItems = true;
      _purchaseItemsError = null;
    });
    try {
      final response = await ApiService.get('stock_invoices/$purchaseId');
      final Map<String, dynamic> data =
          response is Map && response.containsKey('data')
              ? Map<String, dynamic>.from(response['data'])
              : Map<String, dynamic>.from(response);

      final List rawItems = data['items'] ?? [];
      final rows = rawItems.map((raw) {
        final item = Map<String, dynamic>.from(raw);
        final productId = item['product_id'] is int
            ? item['product_id'] as int
            : int.tryParse(item['product_id'].toString()) ?? 0;
        final quantity = item['quantity'] is int
            ? item['quantity'] as int
            : int.tryParse(item['quantity'].toString()) ?? 0;
        final price = item['purchase_price'] is num
            ? (item['purchase_price'] as num).toDouble()
            : double.tryParse(item['purchase_price'].toString()) ?? 0.0;

        // Nama produk ada di dalam objek relasi 'product', bukan sebagai
        // field flat 'product_name'. Fallback ke 'Produk' hanya kalau
        // relasi memang tidak ter-load / null.
        final productMap = item['product'];
        final productName = (productMap is Map && productMap['name'] != null)
            ? productMap['name'].toString()
            : 'Produk';

        return _PurchaseItemRow(
          id: item['id'] is int ? item['id'] as int : int.tryParse(item['id']?.toString() ?? ''),
          productId: productId,
          productName: productName,
          originalQuantity: quantity,
          originalPrice: price,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        // buang controller lama dulu sebelum diganti
        for (final r in _purchaseItemRows) {
          r.dispose();
        }
        _purchaseItemRows = rows;
        _isLoadingItems = false;
      });
    } catch (e) {
      debugPrint('Load purchase items error: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingItems = false;
        _purchaseItemsError = 'Gagal memuat detail item pembelian';
      });
    }
  }

  void _clearPurchaseItems() {
    for (final r in _purchaseItemRows) {
      r.dispose();
    }
    _purchaseItemRows = [];
    _purchaseItemsError = null;
  }

  /// Cari purchase pada _purchases berdasarkan id (aman terhadap
  /// id bertipe int maupun String dari backend).
  Map<String, dynamic>? _findPurchaseById(int? id) {
    if (id == null) return null;
    for (final p in _purchases) {
      final pid = p['id'] is int ? p['id'] as int : int.tryParse(p['id'].toString());
      if (pid == id) return p;
    }
    return null;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _categoryController.dispose();
    _amountController.dispose();
    for (final r in _purchaseItemRows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _expenseDate = picked);
    }
  }

  Future<void> _pickReceiptImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file != null) {
      setState(() {
        _pickedReceiptFile = File(file.path);
        _existingReceiptUrl = null; // preview lama diganti preview baru
      });
    }
  }

  void _removePickedReceipt() {
    setState(() {
      _pickedReceiptFile = null;
      // Setelah foto baru dibuang, kembalikan preview nota lama milik
      // purchase yang sedang dikaitkan (kalau ada), supaya user tidak
      // kehilangan konteks nota yang sudah tersimpan.
      final match = _findPurchaseById(_selectedPurchaseId);
      _existingReceiptUrl = match?['receipt_url']?.toString();
    });
  }

  /// Total dari item pembelian versi terbaru (setelah dikoreksi user),
  /// dipakai untuk tombol "Samakan dengan Total Item".
  double get _purchaseItemsTotal {
    return _purchaseItemRows.fold(0.0, (sum, r) {
      final qty = int.tryParse(r.qtyCtrl.text.trim()) ?? r.originalQuantity;
      final price = double.tryParse(r.priceCtrl.text.trim()) ?? r.originalPrice;
      return sum + (qty * price);
    });
  }

  void _syncAmountWithItemsTotal() {
    setState(() {
      _amountController.text = _purchaseItemsTotal.toStringAsFixed(0);
    });
  }

  /// Kirim perubahan qty/harga item pembelian ke backend.
  /// Dipanggil terpisah dari update expenditure karena keduanya adalah
  /// resource berbeda (Expenditure vs StockInvoice/PurchaseItem).
  ///
  /// Route PUT stock_invoices/{id}/items sudah terdaftar di routes/api.php
  /// dan ditangani oleh StockInvoiceController::updateItems(), yang
  /// menghitung delta qty terhadap stok produk (bukan overwrite polos)
  /// dan menyinkronkan ulang total Purchase & amount Expenditure terkait.
  Future<void> _submitPurchaseItemChanges() async {
    if (_selectedPurchaseId == null) return;
    final dirtyRows = _purchaseItemRows.where((r) => r.isDirty).toList();
    if (dirtyRows.isEmpty) return; // tidak ada koreksi, skip request

    final payload = {
      'items': jsonEncode(_purchaseItemRows.map((r) => r.toPayload()).toList()),
    };

    await ApiService.put('stock_invoices/$_selectedPurchaseId/items', payload);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Nota hanya bisa dilampirkan kalau ada pembelian yang dikaitkan,
    // sesuai aturan backend (receipt_image disimpan ke record Purchase,
    // bukan ke Expenditure).
    if (_pickedReceiptFile != null && _selectedPurchaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih pembelian terlebih dahulu untuk melampirkan nota'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final fields = <String, String>{
      'description': _descriptionController.text.trim(),
      'amount': (double.tryParse(
                  _amountController.text.replaceAll('.', '').replaceAll(',', '')) ??
              0)
          .toString(),
      'expense_date': DateFormat('yyyy-MM-dd').format(_expenseDate),
    };
    if (_categoryController.text.trim().isNotEmpty) {
      fields['category'] = _categoryController.text.trim();
    }
    if (_selectedPurchaseId != null) {
      fields['purchase_id'] = _selectedPurchaseId.toString();
    }

    // Dicek SEBELUM dikirim, supaya pesan sukses/gagal nanti akurat:
    // apakah memang ada baris item yang diubah user pada sesi ini atau
    // tidak (kalau tidak ada, tidak perlu klaim "item berhasil disimpan").
    final hasDirtyItems = _purchaseItemRows.any((r) => r.isDirty);

    // FIX: sebelumnya form SELALU mengirim PUT expenditures/{id} setiap
    // kali Simpan ditekan, walau field deskripsi/kategori/jumlah/tanggal/
    // nota TIDAK diubah sama sekali dari data asli. Karena endpoint itu
    // butuh akses admin, kasir yang cuma mengoreksi item pembelian akan
    // selalu melihat peringatan "butuh akses admin" walau sebenarnya tidak
    // ada apa pun yang gagal disimpan (data yang memang diubah — item —
    // sudah berhasil). Sekarang dicek dulu: apakah field header ini benar-
    // benar berubah dibanding data awal? Kalau tidak, lewati saja request
    // ke expenditures/{id} — tidak perlu minta izin untuk perubahan yang
    // memang tidak ada.
    bool headerFieldsChanged = true;
    if (_isEditing) {
      final exp = widget.expenditure!;
      final originalDescription = (exp['description'] ?? '').toString();
      final originalCategory = (exp['category'] ?? '').toString();
      final originalAmountRaw = exp['amount'];
      final originalAmount = originalAmountRaw == null
          ? 0.0
          : (originalAmountRaw is num
              ? originalAmountRaw.toDouble()
              : double.tryParse(originalAmountRaw.toString()) ?? 0.0);
      final originalExpenseDate = exp['expense_date'] != null
          ? DateFormat('yyyy-MM-dd').format(parseDateOnly(exp['expense_date'].toString()))
          : '';
      final originalPurchaseId = exp['purchase_id'] is int
          ? exp['purchase_id'] as int
          : int.tryParse(exp['purchase_id']?.toString() ?? '');

      final currentAmount = double.tryParse(
              _amountController.text.replaceAll('.', '').replaceAll(',', '')) ??
          0.0;

      // FIX: kalau pengeluaran ini terkait pembelian (purchase_id ada),
      // field 'amount' SELALU otomatis disinkronkan oleh backend lewat
      // StockInvoiceController::updateItems() setiap kali item dikoreksi
      // (termasuk saat user menekan tombol "Samakan Jumlah" di form ini,
      // yang cuma menyalin _purchaseItemsTotal ke _amountController).
      // Jadi membandingkan amount saat ini terhadap amount ASLI sebelum
      // sesi edit ini salah — amount memang SEHARUSNYA berubah mengikuti
      // total item terbaru, dan itu sudah tersimpan otomatis lewat request
      // item, bukan lewat PUT expenditures/{id}. Untuk kasus ini,
      // bandingkan terhadap total item saat ini (_purchaseItemsTotal),
      // bukan terhadap amount lama.
      final amountChanged = originalPurchaseId != null
          ? (currentAmount - _purchaseItemsTotal).abs() > 0.5
          : currentAmount != originalAmount;

      headerFieldsChanged = _descriptionController.text.trim() != originalDescription ||
          _categoryController.text.trim() != originalCategory ||
          amountChanged ||
          DateFormat('yyyy-MM-dd').format(_expenseDate) != originalExpenseDate ||
          _selectedPurchaseId != originalPurchaseId ||
          _pickedReceiptFile != null;
    }

    try {
      // 1) Simpan koreksi item pembelian dulu (kalau ada perubahan).
      //    Route ini pakai middleware 'kasir_or_admin', jadi kasir tetap
      //    boleh mengoreksi qty/harga item. StockInvoiceController::
      //    updateItems() SUDAH menyinkronkan ulang Purchase.total dan
      //    Expenditure.amount di sisi backend saat ini berhasil.
      await _submitPurchaseItemChanges();

      // 2) Simpan field lain milik Expenditure (deskripsi, kategori,
      //    tanggal, nota, dst) — HANYA kalau memang ada yang berubah.
      //
      // Kalau sedang edit dan tidak ada field header yang berubah sama
      // sekali, tidak perlu kirim request ini. Ini penting terutama untuk
      // kasir: PUT expenditures/{id} didaftarkan di bawah middleware
      // 'admin' (lihat routes/api.php), sedangkan POST expenditures
      // (create) di bawah 'kasir_or_admin'. Kalau dipaksa kirim padahal
      // tidak ada perubahan, request akan selalu ditolak 403 "Unauthorized.
      // Admin access required." (yang oleh ApiService diterjemahkan jadi
      // "Akses ditolak"), dan itu memunculkan peringatan yang membingungkan
      // walau sebenarnya tidak ada apa pun yang gagal disimpan.
      bool expenditureFieldsBlockedByPermission = false;
      if (!_isEditing || headerFieldsChanged) {
        try {
          if (_isEditing) {
            final id = widget.expenditure!['id'];
            // fileFieldName HARUS 'receipt_image' — itu nama yang divalidasi
            // via $request->hasFile('receipt_image') di ExpenditureController.
            await ApiService.putMultipart(
              'expenditures/$id',
              fields,
              _pickedReceiptFile,
              fileFieldName: 'receipt_image',
            );
          } else {
            // Route create (POST expenditures) pakai 'kasir_or_admin', jadi
            // seharusnya tidak pernah kena 403 di sini untuk kasir.
            await ApiService.postMultipart(
              'expenditures',
              fields,
              _pickedReceiptFile,
              fileFieldName: 'receipt_image',
            );
          }
        } catch (e) {
          final msg = e.toString();
          // FIX: ApiService rupanya MENERJEMAHKAN respons 403 backend
          // ("Unauthorized. Admin access required.") menjadi pesan Indonesia
          // "Akses ditolak" sebelum melempar Exception. Deteksi sebelumnya
          // hanya mencocokkan teks Inggris mentah, jadi tidak pernah kena di
          // sini — selalu jatuh ke rethrow dan tampil sebagai kegagalan total.
          // Sekarang deteksi juga string hasil terjemahannya.
          final isForbidden = msg.contains('403') ||
              msg.contains('Unauthorized') ||
              msg.contains('Admin access required') ||
              msg.contains('Akses ditolak') ||
              msg.toLowerCase().contains('forbidden');
          if (_isEditing && isForbidden) {
            expenditureFieldsBlockedByPermission = true;
          } else {
            rethrow;
          }
        }
      }

      if (!mounted) return;

      if (expenditureFieldsBlockedByPermission) {
        final message = hasDirtyItems
            ? 'Koreksi item pembelian berhasil disimpan. Perubahan deskripsi/kategori/tanggal/nota tidak disimpan karena butuh akses admin.'
            : 'Perubahan tidak disimpan: mengubah deskripsi/kategori/tanggal/nota pengeluaran butuh akses admin.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
        // Kalau memang ada item yang berhasil dikoreksi, kembalikan true
        // supaya list refresh menampilkan amount terbaru. Kalau tidak ada
        // apa pun yang berhasil tersimpan, tidak perlu trigger refresh.
        Navigator.pop(context, hasDirtyItems);
      } else {
        if (mounted && hasDirtyItems && !headerFieldsChanged && _isEditing) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Koreksi item pembelian berhasil disimpan.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Save expenditure error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Pengeluaran' : 'Tambah Pengeluaran',
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _label('Deskripsi'),
            _textField(
              controller: _descriptionController,
              hint: 'Contoh: Bayar listrik toko',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Deskripsi wajib diisi' : null,
            ),
            const SizedBox(height: 16),

            _label('Kategori (opsional)'),
            _textField(
              controller: _categoryController,
              hint: 'Contoh: Operasional',
            ),
            const SizedBox(height: 16),

            _label('Jumlah'),
            _textField(
              controller: _amountController,
              hint: '0',
              keyboardType: TextInputType.number,
              prefixText: 'Rp ',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Jumlah wajib diisi';
                final parsed = double.tryParse(v.replaceAll('.', '').replaceAll(',', ''));
                if (parsed == null || parsed <= 0) return 'Jumlah tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 16),

            _label('Tanggal'),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: Color(0xFF6B7280)),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('d MMMM y').format(_expenseDate),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            _label('Kaitkan Pembelian (opsional)'),
            _buildPurchaseDropdown(),

            // ── Detail item pembelian (koreksi qty/harga) ──
            if (_selectedPurchaseId != null) ...[
              const SizedBox(height: 16),
              _buildPurchaseItemsSection(),
            ],

            const SizedBox(height: 16),

            _label('Nota / Bukti (opsional)'),
            _buildReceiptPicker(),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _isEditing ? 'Simpan Perubahan' : 'Simpan Pengeluaran',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseDropdown() {
    if (_isLoadingPurchases) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          isExpanded: true,
          value: _selectedPurchaseId,
          hint: const Text(
            'Tidak dikaitkan',
            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Tidak dikaitkan',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            ),
            ..._purchases.map((p) {
              final invoice = p['invoice']?.toString() ?? '-';
              final supplier = p['supplier']?.toString() ?? '';
              return DropdownMenuItem<int?>(
                value: p['id'] is int ? p['id'] as int : int.tryParse(p['id'].toString()),
                child: Text(
                  '$invoice — $supplier',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
                ),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedPurchaseId = value;

              if (value == null) {
                // Purchase dilepas → nota lama/baru sama-sama tidak
                // relevan lagi (backend hanya menyimpan nota ke purchase
                // yang dikaitkan), dan detail item juga tidak relevan lagi.
                _pickedReceiptFile = null;
                _existingReceiptUrl = null;
                _clearPurchaseItems();
              } else {
                // Purchase baru dipilih → buang foto baru yang mungkin
                // sempat dipilih untuk purchase sebelumnya, lalu tampilkan
                // nota yang sudah ada pada purchase yang baru dipilih
                // (kalau lookup mengembalikan receipt_url), dan muat ulang
                // detail item pembelian yang baru dipilih.
                _pickedReceiptFile = null;
                final match = _findPurchaseById(value);
                _existingReceiptUrl = match?['receipt_url']?.toString();
                _clearPurchaseItems();
              }
            });
            if (value != null) {
              _loadPurchaseItems(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildPurchaseItemsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 6),
              const Text(
                'Detail Item Pembelian',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
              ),
              const Spacer(),
              if (_isLoadingItems)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Koreksi jumlah / harga beli kalau ada salah input waktu di halaman Tambah Produk.',
            style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 10),

          if (_purchaseItemsError != null)
            Text(
              _purchaseItemsError!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
            )
          else if (!_isLoadingItems && _purchaseItemRows.isEmpty)
            const Text(
              'Tidak ada item pada pembelian ini.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            )
          else
            Column(
              children: _purchaseItemRows.map((row) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          row.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF111827)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: row.qtyCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 12),
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Qty',
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n <= 0) return 'Wajib';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: row.priceCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 12),
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Harga',
                            prefixText: 'Rp ',
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          if (_purchaseItemRows.isNotEmpty) ...[
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total item: ${formatRupiah(_purchaseItemsTotal)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                  ),
                ),
                TextButton(
                  onPressed: _syncAmountWithItemsTotal,
                  child: const Text('Samakan Jumlah', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReceiptPicker() {
    final hasNewFile = _pickedReceiptFile != null;
    final hasExisting = _existingReceiptUrl != null && !hasNewFile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasNewFile || hasExisting)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasNewFile
                ? Image.file(_pickedReceiptFile!, fit: BoxFit.cover)
                : Image.network(
                    _existingReceiptUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFF3F4F6),
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined,
                          color: Color(0xFF9CA3AF)),
                    ),
                  ),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectedPurchaseId == null ? null : _pickReceiptImage,
                icon: const Icon(Icons.upload_outlined, size: 18),
                label: Text(hasNewFile || hasExisting ? 'Ganti Foto' : 'Pilih Foto'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (hasNewFile) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: _removePickedReceipt,
                icon: const Icon(Icons.close, color: Color(0xFFDC2626)),
              ),
            ],
          ],
        ),
        if (_selectedPurchaseId == null)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Kaitkan pembelian dulu untuk bisa melampirkan nota',
              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
          ),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? prefixText,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF059669)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}