// lib/services/printer_service.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:flutter/material.dart';

class PrinterService {
  // Scan printer Bluetooth
  static Future<List<BluetoothDevice>> scanBluetooth() async {
    try {
      final devices = <BluetoothDevice>[];
      final completer = Completer<List<BluetoothDevice>>();
      final subscription = BluetoothPrintPlus.scanResults.listen((results) {
        devices.clear();
        devices.addAll(results);
        if (!completer.isCompleted) completer.complete(devices);
      });
      await BluetoothPrintPlus.startScan();
      await Future.delayed(const Duration(seconds: 5));
      await BluetoothPrintPlus.stopScan();
      await subscription.cancel();
      return devices;
    } catch (e) {
      debugPrint('Scan error: $e');
      return [];
    }
  }

  static Future<bool> connect(BluetoothDevice device) async {
    try {
      await BluetoothPrintPlus.connect(device);
      return true;
    } catch (e) {
      debugPrint('Connect error: $e');
      return false;
    }
  }

  static bool get isConnected => BluetoothPrintPlus.isConnected;

  static Future<void> disconnect() async {
    await BluetoothPrintPlus.disconnect();
  }

  static Future<bool> printReceipt({
    required String storeName,
    required String invoiceNumber,
    required DateTime date,
    required List<Map<String, dynamic>> items,
    required int total,
    required String paymentMethod,
    int? paidAmount,
    String? address,
    String? phone,
  }) async {
    if (!BluetoothPrintPlus.isConnected) {
      debugPrint('Printer not connected');
      return false;
    }

    try {
      final buffer = StringBuffer();
      void p(String line) => buffer.writeln(line);

      // Header
      p(storeName);
      if (address != null && address.isNotEmpty) p(address);
      if (phone != null && phone.isNotEmpty) p('Telp: $phone');
      p('=' * 32);
      p('No: $invoiceNumber');
      p('Tgl: ${_formatDate(date)}');
      p('Jam: ${_formatTime(date)}');
      p('-' * 32);

      // Items
      for (var item in items) {
        final name = item['name']?.toString() ?? '-';
        final qty = item['qty'] as int;
        final price = _toInt(item['selling_price']);
        final subtotal = qty * price;
        final line = '${_padRight(name, 20)} ${_formatRupiah(price)} x $qty = ${_formatRupiah(subtotal)}';
        p(line);
      }

      p('-' * 32);
      p('Total: ${_formatRupiah(total)}');
      p('Metode: ${_labelMetode(paymentMethod)}');
      if (paymentMethod == 'cash' && paidAmount != null) {
        p('Bayar: ${_formatRupiah(paidAmount)}');
        p('Kembali: ${_formatRupiah(paidAmount - total)}');
      }
      p('=' * 32);
      p('Terima kasih');
      p('Barang yang sudah dibeli');
      p('tidak dapat dikembalikan');
      p(''); // baris kosong
      p(''); // baris kosong

      // Perintah potong kertas ESC/POS (GS V 1 full cut)
      buffer.writeCharCode(0x1D);
      buffer.writeCharCode(0x56);
      buffer.writeCharCode(0x41);

      final bytes = Uint8List.fromList(buffer.toString().codeUnits);
      await BluetoothPrintPlus.write(bytes);
      return true;
    } catch (e) {
      debugPrint('Print error: $e');
      return false;
    }
  }

  // Helper konversi ke int dari dynamic (String, double, int)
  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return double.tryParse(value)?.toInt() ?? 0;
    return 0;
  }

  static String _padRight(String text, int length) {
    if (text.length <= length) return text.padRight(length);
    return text.substring(0, length - 3) + '...';
  }

  static String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
  static String _formatTime(DateTime date) => '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';

  static String _formatRupiah(int nominal) {
    if (nominal == 0) return 'Rp 0';
    final formatted = nominal.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
    return 'Rp $formatted';
  }

  static String _labelMetode(String type) {
    switch (type) {
      case 'cash': return 'Tunai';
      case 'debt': return 'Utang';
      case 'qris': return 'QRIS';
      case 'transfer': return 'Transfer';
      default: return type;
    }
  }
}