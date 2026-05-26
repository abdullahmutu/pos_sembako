import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/api/api_service.dart';

// ============================================================
// MODEL LOKAL
// ============================================================
class _CustomerOption {
  final int id;
  final String nama;
  final String? noHp;
  final String? alamat;

  _CustomerOption({
    required this.id,
    required this.nama,
    this.noHp,
    this.alamat,
  });

  factory _CustomerOption.fromJson(Map<String, dynamic> json) {
    return _CustomerOption(
      id: json['id'],
      nama: json['name'] ?? json['nama'] ?? '',
      noHp: json['phone'] ?? json['no_hp'] ?? json['telp'],
      alamat: json['address'] ?? json['alamat'],
    );
  }
}

class _ProductOption {
  final int id;
  final String nama;
  final double harga;
  final int stok;

  _ProductOption({
    required this.id,
    required this.nama,
    required this.harga,
    required this.stok,
  });

  factory _ProductOption.fromJson(Map<String, dynamic> json) {
    return _ProductOption(
      id: json['id'],
      nama: json['name'] ?? json['nama'] ?? '',
      harga: double.tryParse(json['selling_price']?.toString() ?? '0') ?? 0,
      stok: json['stock'] ?? json['stok'] ?? 0,
    );
  }
}

class ItemBaris {
  _ProductOption? produk;
  int jumlah;

  ItemBaris({this.produk, this.jumlah = 1});

  double get hargaSatuan => produk?.harga ?? 0;
  double get subtotal => hargaSatuan * jumlah;
}

// ============================================================
// FORM TAMBAH UTANG
// ============================================================
class TambahUtangForm extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic> data)? onSimpan;
  final List<ItemBaris>? initialItems;
  final List<Map<String, dynamic>>? initialCartItems;

  const TambahUtangForm({
    super.key,
    this.onSimpan,
    this.initialItems,
    this.initialCartItems,
  });

  @override
  State<TambahUtangForm> createState() => _TambahUtangFormState();
}

class _TambahUtangFormState extends State<TambahUtangForm> {
  static const Color hijauUtama = Color(0xFF1A7A4A);
  static const Color hijauMuda = Color(0xFFE8F5EE);
  static const Color abukuMuda = Color(0xFFF5F5F5);
  static const Color merah = Color(0xFFD32F2F);

  final _formatRupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoadingInit = true;
  bool _isSaving = false;
  String? _initError;

  List<_CustomerOption> _customers = [];
  List<_ProductOption> _products = [];

  // ── Pelanggan ──
  _CustomerOption? _selectedCustomer;
  final _searchCtrl = TextEditingController();
  List<_CustomerOption> _filteredCustomers = [];
  bool _showSuggestions = false;

  // ── Field pelanggan baru ──
  final _noHpCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  bool _isNewCustomer = false; // true jika nama tidak cocok di daftar

  // ── Waktu pembayaran ──
  DateTime _waktuPembayaran = DateTime.now();

  // ── Items ──
  late List<ItemBaris> _items;

  // ── Catatan ──
  String? _notes;

  double get _subtotal => _items.fold(0, (s, i) => s + i.subtotal);

  @override
  void initState() {
    super.initState();
    if (widget.initialCartItems != null &&
        widget.initialCartItems!.isNotEmpty) {
      _items = widget.initialCartItems!.map((cartItem) {
        final produk = _ProductOption(
          id: cartItem['id'],
          nama: cartItem['name'] ?? '-',
          harga:
              double.tryParse(cartItem['selling_price']?.toString() ?? '0') ??
                  0,
          stok: cartItem['stock'] ?? 0,
        );
        return ItemBaris(produk: produk, jumlah: cartItem['qty'] ?? 1);
      }).toList();
    } else if (widget.initialItems != null) {
      _items = List.from(widget.initialItems!);
    } else {
      _items = [ItemBaris()];
    }
    _fetchInitialData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _noHpCtrl.dispose();
    _alamatCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoadingInit = true;
      _initError = null;
    });
    try {
      final results = await Future.wait([
        ApiService.get('customers'),
        ApiService.get('products'),
      ]);

      final rawCustomers =
          results[0] is List ? results[0] : (results[0]['data'] ?? []);
      final rawProducts =
          results[1] is List ? results[1] : (results[1]['data'] ?? []);

      setState(() {
        _customers = (rawCustomers as List)
            .map((e) => _CustomerOption.fromJson(e))
            .toList();
        _products = (rawProducts as List)
            .map((e) => _ProductOption.fromJson(e))
            .toList();
        _isLoadingInit = false;
      });
    } catch (e) {
      setState(() {
        _initError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingInit = false;
      });
    }
  }

  // ── Pilih waktu pembayaran ──
  Future<void> _pilihWaktuPembayaran() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: _waktuPembayaran,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: hijauUtama),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_waktuPembayaran),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: hijauUtama),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    setState(() {
      _waktuPembayaran = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _onSearchCustomer(String query) {
    setState(() {
      _selectedCustomer = null;
      _isNewCustomer = false;
      _noHpCtrl.clear();
      _alamatCtrl.clear();

      if (query.trim().isEmpty) {
        _filteredCustomers = [];
        _showSuggestions = false;
      } else {
        _filteredCustomers = _customers
            .where((c) => c.nama.toLowerCase().contains(query.toLowerCase()))
            .toList();
        _showSuggestions = true;
        // Jika tidak ada yang cocok persis → tandai sebagai pelanggan baru
        _isNewCustomer = _filteredCustomers.isEmpty;
      }
    });
  }

  void _pilihCustomer(_CustomerOption c) {
    setState(() {
      _selectedCustomer = c;
      _searchCtrl.text = c.nama;
      _showSuggestions = false;
      _filteredCustomers = [];
      _isNewCustomer = false;
      // Isi otomatis field dari data pelanggan
      _noHpCtrl.text = c.noHp ?? '';
      _alamatCtrl.text = c.alamat ?? '';
    });
  }

  Future<void> _simpan() async {
    final namaInput = _searchCtrl.text.trim();

    if (namaInput.isEmpty) {
      _snack('Nama pelanggan wajib diisi!');
      return;
    }

    final itemsValid =
        _items.where((i) => i.produk != null && i.jumlah > 0).toList();
    if (itemsValid.isEmpty) {
      _snack('Pilih minimal satu produk!');
      return;
    }

    setState(() => _isSaving = true);
    try {
      int customerId;

      if (_selectedCustomer != null) {
        customerId = _selectedCustomer!.id;
      } else {
        // Buat pelanggan baru dengan data lengkap
        final bodyCustomer = {
          'name': namaInput,
          'customer_type': 'regular',
          if (_noHpCtrl.text.trim().isNotEmpty) 'phone': _noHpCtrl.text.trim(),
          if (_alamatCtrl.text.trim().isNotEmpty)
            'address': _alamatCtrl.text.trim(),
        };

        _snack('Membuat pelanggan baru: $namaInput...');
        final res = await ApiService.post('customers', bodyCustomer);

        final resData = res is Map && res['data'] != null ? res['data'] : res;
        customerId = resData['id'];

        final customerBaru = _CustomerOption(
          id: customerId,
          nama: namaInput,
          noHp: _noHpCtrl.text.trim().isNotEmpty ? _noHpCtrl.text.trim() : null,
          alamat: _alamatCtrl.text.trim().isNotEmpty
              ? _alamatCtrl.text.trim()
              : null,
        );
        setState(() {
          _customers.add(customerBaru);
          _selectedCustomer = customerBaru;
          _isNewCustomer = false;
        });
      }

      final payload = {
        'customer_id': customerId,
        'payment_type': 'debt',
        'due_date': _waktuPembayaran.toIso8601String(),
        'items': itemsValid
            .map((i) => {
                  'product_id': i.produk!.id,
                  'quantity': i.jumlah,
                  'unit_price': i.produk!.harga,
                })
            .toList(),
        if (_notes != null && _notes!.trim().isNotEmpty)
          'notes': _notes!.trim(),
      };

      debugPrint('=== PAYLOAD SIMPAN ===');
      debugPrint('customer_id : ${payload['customer_id']}');
      debugPrint('due_date    : ${payload['due_date']}');
      debugPrint('items       : ${payload['items']}');

      await widget.onSimpan?.call(payload);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('=== ERROR SIMPAN ===\n$e');
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ============================================================
  // BUILD
  // ============================================================
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
      child: _isLoadingInit
          ? const SizedBox(
              height: 180,
              child:
                  Center(child: CircularProgressIndicator(color: hijauUtama)),
            )
          : _initError != null
              ? _buildError()
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHandle(),
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildSectionPelanggan(),
                      const SizedBox(height: 16),
                      _buildSectionWaktuPembayaran(),
                      const SizedBox(height: 16),
                      _buildRincianProduk(),
                      const SizedBox(height: 16),
                      _buildFieldCatatan(),
                      const SizedBox(height: 20),
                      _buildKartuTotal(),
                      const SizedBox(height: 20),
                      _buildTombolAksi(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildError() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(_initError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _fetchInitialData,
            style: ElevatedButton.styleFrom(backgroundColor: hijauUtama),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label:
                const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tambah Utang Baru',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          SizedBox(height: 2),
          Text('Catat transaksi kredit pelanggan.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
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
    );
  }

  // ── SECTION PELANGGAN ──────────────────────────────────────
  Widget _buildSectionPelanggan() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel('PELANGGAN'),
      const SizedBox(height: 8),

      // Search field
      TextField(
        controller: _searchCtrl,
        onChanged: _onSearchCustomer,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          hintText: 'Ketik nama atau cari pelanggan...',
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          filled: true,
          fillColor: abukuMuda,
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
          suffixIcon: _selectedCustomer != null
              ? GestureDetector(
                  onTap: () => setState(() {
                    _selectedCustomer = null;
                    _searchCtrl.clear();
                    _noHpCtrl.clear();
                    _alamatCtrl.clear();
                    _filteredCustomers = [];
                    _showSuggestions = false;
                    _isNewCustomer = false;
                  }),
                  child: const Icon(Icons.close, color: Colors.grey, size: 18),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: _selectedCustomer != null
                ? const BorderSide(color: hijauUtama, width: 1.5)
                : BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: hijauUtama, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),

      // Badge pelanggan terpilih
      if (_selectedCustomer != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [
            const Icon(Icons.check_circle, color: hijauUtama, size: 16),
            const SizedBox(width: 6),
            Text(
              'Dipilih: ${_selectedCustomer!.nama}',
              style: const TextStyle(
                  color: hijauUtama, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ]),
        ),

      // Badge pelanggan baru
      if (_isNewCustomer)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [
            const Icon(Icons.person_add_alt_1, color: Colors.orange, size: 16),
            const SizedBox(width: 6),
            const Text(
              'Pelanggan baru akan dibuat',
              style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ]),
        ),

      // Dropdown suggestion
      if (_showSuggestions)
        Container(
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: _filteredCustomers.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(children: [
                    Icon(Icons.person_add_alt_1,
                        color: Colors.orange, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tidak ditemukan. Data di bawah akan disimpan sebagai pelanggan baru.',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ]),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: _filteredCustomers.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, indent: 16, color: Color(0xFFEEEEEE)),
                  itemBuilder: (_, i) {
                    final c = _filteredCustomers[i];
                    final query = _searchCtrl.text.trim().toLowerCase();
                    final namaBawah = c.nama.toLowerCase();
                    final start = namaBawah.indexOf(query);
                    return InkWell(
                      onTap: () => _pilihCustomer(c),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: hijauMuda,
                            child: Text(
                              c.nama.isNotEmpty ? c.nama[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  color: hijauUtama,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                start >= 0
                                    ? RichText(
                                        text: TextSpan(
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87),
                                          children: [
                                            if (start > 0)
                                              TextSpan(
                                                  text: c.nama
                                                      .substring(0, start)),
                                            TextSpan(
                                              text: c.nama.substring(
                                                  start, start + query.length),
                                              style: const TextStyle(
                                                  color: hijauUtama,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            TextSpan(
                                                text: c.nama.substring(
                                                    start + query.length)),
                                          ],
                                        ),
                                      )
                                    : Text(c.nama,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87)),
                                if (c.noHp != null)
                                  Text(c.noHp!,
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: Colors.grey, size: 18),
                        ]),
                      ),
                    );
                  },
                ),
        ),

      // Field No HP & Alamat — tampil untuk pelanggan baru ATAU pelanggan lama
      if (_searchCtrl.text.trim().isNotEmpty) ...[
        const SizedBox(height: 12),
        _buildFieldNoHp(),
        const SizedBox(height: 10),
        _buildFieldAlamat(),
      ],
    ]);
  }

  Widget _buildFieldNoHp() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel('NOMOR HP'),
      const SizedBox(height: 6),
      TextField(
        controller: _noHpCtrl,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: _inputDeco(
          hint: 'Contoh: 08123456789',
          prefix:
              const Icon(Icons.phone_outlined, color: Colors.grey, size: 18),
        ),
      ),
    ]);
  }

  Widget _buildFieldAlamat() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel('ALAMAT'),
      const SizedBox(height: 6),
      TextField(
        controller: _alamatCtrl,
        maxLines: 2,
        textCapitalization: TextCapitalization.sentences,
        decoration: _inputDeco(
          hint: 'Masukkan alamat lengkap...',
          prefix: const Icon(Icons.location_on_outlined,
              color: Colors.grey, size: 18),
        ),
      ),
    ]);
  }

  // ── SECTION WAKTU PEMBAYARAN ───────────────────────────────
  Widget _buildSectionWaktuPembayaran() {
    final fmt = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel('JATUH TEMPO PEMBAYARAN'),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _pilihWaktuPembayaran,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: abukuMuda,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined,
                color: hijauUtama, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fmt.format(_waktuPembayaran),
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ]),
        ),
      ),
      const SizedBox(height: 6),
      // Chip pilihan cepat
      Wrap(
        spacing: 8,
        children: [
          _chipWaktu('Hari ini', 0),
          _chipWaktu('7 hari', 7),
          _chipWaktu('14 hari', 14),
          _chipWaktu('30 hari', 30),
        ],
      ),
    ]);
  }

  Widget _chipWaktu(String label, int tambahHari) {
    final target = DateTime.now().add(Duration(days: tambahHari));
    final isSelected = _waktuPembayaran.year == target.year &&
        _waktuPembayaran.month == target.month &&
        _waktuPembayaran.day == target.day;

    return GestureDetector(
      onTap: () => setState(() => _waktuPembayaran = DateTime(
            target.year,
            target.month,
            target.day,
            _waktuPembayaran.hour,
            _waktuPembayaran.minute,
          )),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? hijauUtama : hijauMuda,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : hijauUtama),
        ),
      ),
    );
  }

  // ── RINCIAN PRODUK ─────────────────────────────────────────
  Widget _buildRincianProduk() {
    final bool isReadOnly =
        widget.initialCartItems != null && widget.initialCartItems!.isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _sectionLabel('RINCIAN PRODUK'),
        if (!isReadOnly)
          GestureDetector(
            onTap: () => setState(() => _items.add(ItemBaris())),
            child: const Row(children: [
              Icon(Icons.add_circle_outline, color: hijauUtama, size: 16),
              SizedBox(width: 4),
              Text('Tambah Baris',
                  style: TextStyle(
                      color: hijauUtama,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ]),
          ),
      ]),
      const SizedBox(height: 10),
      if (isReadOnly)
        ..._items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.produk?.nama ?? '-',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(
                            '${item.jumlah} x ${_formatRupiah.format(item.hargaSatuan)}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ]),
                ),
                Text(_formatRupiah.format(item.subtotal),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
            ))
      else
        ...List.generate(_items.length, _buildBarisProduk),
    ]);
  }

  Widget _buildBarisProduk(int index) {
    final item = _items[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: abukuMuda,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
          flex: 5,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            DropdownButtonHideUnderline(
              child: DropdownButton<_ProductOption>(
                isExpanded: true,
                value: item.produk,
                isDense: true,
                hint: const Text('Pilih produk',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                items: _products
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.nama,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => item.produk = val),
              ),
            ),
            if (item.produk != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _formatRupiah.format(item.hargaSatuan),
                  style: const TextStyle(
                      fontSize: 11,
                      color: hijauUtama,
                      fontWeight: FontWeight.w600),
                ),
              ),
          ]),
        ),
        const SizedBox(width: 8),
        Row(mainAxisSize: MainAxisSize.min, children: [
          _iconQty(
            icon: Icons.remove,
            onTap: item.jumlah > 1 ? () => setState(() => item.jumlah--) : null,
          ),
          SizedBox(
            width: 32,
            child: Text(
              item.jumlah.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          _iconQty(
            icon: Icons.add,
            onTap: () => setState(() => item.jumlah++),
          ),
        ]),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            _formatRupiah.format(item.subtotal),
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
        ),
        GestureDetector(
          onTap: _items.length > 1
              ? () => setState(() => _items.removeAt(index))
              : null,
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(Icons.delete_outline,
                color: _items.length > 1 ? merah : Colors.grey.shade300,
                size: 20),
          ),
        ),
      ]),
    );
  }

  Widget _iconQty({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap != null ? hijauUtama : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            color: onTap != null ? Colors.white : Colors.grey, size: 16),
      ),
    );
  }

  // ── CATATAN ────────────────────────────────────────────────
  Widget _buildFieldCatatan() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel('CATATAN (Opsional)'),
      const SizedBox(height: 8),
      TextFormField(
        onChanged: (v) => _notes = v,
        maxLines: 2,
        decoration: _inputDeco(hint: 'Tambahkan catatan...'),
      ),
    ]);
  }

  // ── TOTAL ──────────────────────────────────────────────────
  Widget _buildKartuTotal() {
    final fmt = DateFormat('dd MMM yyyy', 'id_ID');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
          color: hijauUtama, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('TOTAL TAGIHAN UTANG',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0)),
              const SizedBox(height: 4),
              Text(_formatRupiah.format(_subtotal),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ]),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long_outlined,
                  color: Colors.white, size: 22),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 1,
          color: Colors.white.withOpacity(0.2),
        ),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.event_outlined, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          const Text('Jatuh tempo: ',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          Text(
            fmt.format(_waktuPembayaran),
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ]),
      ]),
    );
  }

  // ── TOMBOL AKSI ────────────────────────────────────────────
  Widget _buildTombolAksi() {
    return Row(children: [
      Expanded(
        child: OutlinedButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: Colors.grey),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
          onPressed: _isSaving ? null : _simpan,
          style: ElevatedButton.styleFrom(
            backgroundColor: hijauUtama,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('Simpan\nCatatan Utang',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      height: 1.3)),
        ),
      ),
    ]);
  }

  // ── HELPERS ────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: hijauUtama,
          letterSpacing: 1.0),
    );
  }

  InputDecoration _inputDeco({
    required String hint,
    Widget? prefix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      filled: true,
      fillColor: abukuMuda,
      prefixIcon: prefix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: hijauUtama, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}

// ============================================================
// HELPER GLOBAL
// ============================================================
void showTambahUtangSheet(
  BuildContext context, {
  Future<void> Function(Map<String, dynamic>)? onSimpan,
  List<ItemBaris>? initialItems,
  List<Map<String, dynamic>>? initialCartItems,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TambahUtangForm(
      onSimpan: onSimpan,
      initialItems: initialItems,
      initialCartItems: initialCartItems,
    ),
  );
}
