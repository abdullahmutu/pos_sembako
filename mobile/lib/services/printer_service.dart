import 'dart:async';
import 'dart:typed_data';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class PrinterService {
  static const int _charWidth = 32;
  static const int _dotWidth = 384;

  static Future<List<BluetoothDevice>> scanBluetooth() async {
    try {
      final devices = <BluetoothDevice>[];
      final completer = Completer<List<BluetoothDevice>>();
      final subscription = BluetoothPrintPlus.scanResults.listen((results) {
        devices..clear()..addAll(results);
        if (!completer.isCompleted) completer.complete(List.unmodifiable(devices));
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

  // 🔧 fungsi wrap text
  static List<String> _wrapText(String text, int maxWidth) {
    final words = text.split(RegExp(r'\s+'));
    final lines = <String>[];
    var currentLine = '';

    for (final word in words) {
      if ((currentLine.length + word.length + 1) > maxWidth) {
        lines.add(currentLine.trim());
        currentLine = word;
      } else {
        currentLine += (currentLine.isEmpty ? '' : ' ') + word;
      }
    }
    if (currentLine.isNotEmpty) lines.add(currentLine.trim());
    return lines;
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
    String? logoUrl,
  }) async {
    if (!BluetoothPrintPlus.isConnected) {
      debugPrint('Printer not connected');
      return false;
    }

    try {
      final out = <int>[];
      // Init printer
      out.addAll([0x1B, 0x40]);

      // Logo / initials block
      final hasLogo = logoUrl != null && logoUrl.isNotEmpty;
      if (hasLogo) {
        final logoBytes = await _buildLogoBytes(logoUrl);
        if (logoBytes != null) {
          out.addAll([0x1B, 0x61, 0x01]);
          out.addAll(logoBytes);
          out.add(0x0A);
        } else {
          out.addAll([0x1B, 0x61, 0x01]);
          out.addAll(_initialsBlock(storeName, _charWidth));
        }
      } else {
        out.addAll([0x1B, 0x61, 0x01]);
        out.addAll(_initialsBlock(storeName, _charWidth));
      }

      // Nama toko - center, bold
      out.addAll([0x1B, 0x61, 0x01]);
      out.addAll([0x1B, 0x45, 0x01]);
      out.addAll(_bytes(storeName));
      out.add(0x0A);
      out.addAll([0x1B, 0x45, 0x00]);

      // Alamat dengan word wrap
      if (address != null && address.isNotEmpty) {
        final wrapped = _wrapText(address, _charWidth);
        for (final line in wrapped) {
          out.addAll([0x1B, 0x61, 0x01]); // center
          out.addAll(_bytes(line));
          out.add(0x0A);
        }
      }

      // Telepon dengan word wrap
      if (phone != null && phone.isNotEmpty) {
        final wrapped = _wrapText('Telp: $phone', _charWidth);
        for (final line in wrapped) {
          out.addAll([0x1B, 0x61, 0x01]);
          out.addAll(_bytes(line));
          out.add(0x0A);
        }
      }

      // Kembali ke left align untuk isi struk
      out.addAll([0x1B, 0x61, 0x00]);
      out.addAll(_bytes('=' * _charWidth));
      out.add(0x0A);
      out.addAll(_bytes('No: $invoiceNumber'));
      out.add(0x0A);
      out.addAll(_bytes('Tgl: ${_fDate(date)}'));
      out.add(0x0A);
      out.addAll(_bytes('Jam: ${_fTime(date)}'));
      out.add(0x0A);
      out.addAll(_bytes('-' * _charWidth));
      out.add(0x0A);

      // Item struk tanpa "= subtotal"
      for (final item in items) {
        final name = item['name']?.toString() ?? '-';
        final qty = item['qty'] is int ? item['qty'] as int : _toInt(item['qty']);
        final price = _toInt(item['selling_price']);
        if (name.length > 20) {
          out.addAll(_bytes(name));
          out.add(0x0A);
          out.addAll(_bytes('  ${_rp(price)} x $qty')); // tanpa subtotal
          out.add(0x0A);
        } else {
          out.addAll(_bytes('${_pr(name, 16)} ${_rp(price)} x $qty'));
          out.add(0x0A);
        }
      }

      out.addAll(_bytes('-' * _charWidth));
      out.add(0x0A);
      out.addAll([0x1B, 0x45, 0x01]);
      out.addAll(_bytes(_pb('Total:', _rp(total), _charWidth)));
      out.add(0x0A);
      out.addAll([0x1B, 0x45, 0x00]);
      out.addAll(_bytes('Metode: ${_metode(paymentMethod)}'));
      out.add(0x0A);

      if (paymentMethod == 'cash' && paidAmount != null) {
        out.addAll(_bytes(_pb('Bayar:', _rp(paidAmount), _charWidth)));
        out.add(0x0A);
        out.addAll(_bytes(_pb('Kembali:', _rp(paidAmount - total), _charWidth)));
        out.add(0x0A);
      }

      out.addAll(_bytes('=' * _charWidth));
      out.add(0x0A);
      out.addAll([0x1B, 0x61, 0x01]);
      out.addAll(_bytes('Terima kasih!'));
      out.add(0x0A);
      out.add(0x0A);
      out.add(0x0A);
      out.addAll([0x1D, 0x56, 0x41]);

      final sanitized = Uint8List.fromList(out.map((b) => b == 0x40 ? 0x00 : b).toList());
      await BluetoothPrintPlus.write(sanitized);
      return true;
    } catch (e) {
      debugPrint('Print error: $e');
      return false;
    }
  }

  static List<int> _initialsBlock(String storeName, int charWidth) {
    final initials = _getInitials(storeName);
    final out = <int>[];
    final inner = charWidth - 2;
    final top = '+${'-' * inner}+';
    out.addAll(_bytes(top));
    out.add(0x0A);
    final label = ' ${initials.split('').join(' ')} ';
    final side = ((inner - label.length) / 2).floor();
    final sideStr = ' ' * (side > 0 ? side : 0);
    final mid = '|$sideStr$label$sideStr|';
    final midFinal = mid.length < charWidth ? '| $label$sideStr|' : mid;
    out.addAll(_bytes(midFinal));
    out.add(0x0A);
    out.addAll(_bytes(top));
    out.add(0x0A);
    return out;
  }

  static String _getInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) return '${words[0][0]}${words[1][0]}'.toUpperCase();
    final clean = name.trim();
    if (clean.isEmpty) return 'TS';
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  static Future<List<int>?> _buildLogoBytes(String url) async {
    try {
      debugPrint('[PRINTER] Downloading logo: $url');
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) {
        debugPrint('[PRINTER] Logo download failed: ${resp.statusCode}');
        return null;
      }

      final decoded = img.decodeImage(resp.bodyBytes);
      if (decoded == null) {
        debugPrint('[PRINTER] decodeImage returned null');
        return null;
      }
      img.Image image = decoded; // non-null now

      // 1. Trim transparant edges
      image = _trimTransparentEdges(image);

      // 2. Crop to square with white background
      image = _cropToSquare(image);

      // 3. Resize to target (slightly larger for better detail)
      const int targetSize = 200;
      image = img.copyResize(image, width: targetSize, height: targetSize);

      // 4. Grayscale
      image = img.grayscale(image);

      // 5. Slight adjust color (kontras lebih tinggi)
      image = img.adjustColor(image, contrast: 1.3, brightness: 1.0);

      // NOTE: removed img.sharpen because not available in some image package versions

      // 6. Despeckle grayscale
      image = _despeckle(image, radius: 1, minNeighbors: 2);

      // 7. Threshold to binary (nilai threshold diturunkan agar detail tetap terlihat)
      image = _applyThreshold(image, threshold: 150);

      // 8. Despeckle binary
      image = _despeckleBinary(image, radius: 1, minNeighbors: 2);

      debugPrint('[PRINTER] Logo processed: ${image.width}x${image.height}');

      // 9. Convert to ESC/POS raster with centering
      return _toEscRasterCentered(image, printerDotWidth: _dotWidth);
    } catch (e) {
      debugPrint('[PRINTER] Logo error: $e');
      return null;
    }
  }

  static img.Image _applyThreshold(img.Image src, {int threshold = 150}) {
    final out = img.Image(src.width, src.height);
    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final pixel = src.getPixel(x, y);
        final lum = img.getRed(pixel);
        if (lum < threshold) {
          out.setPixel(x, y, img.getColor(0, 0, 0));
        } else {
          out.setPixel(x, y, img.getColor(255, 255, 255));
        }
      }
    }
    return out;
  }

  static img.Image _despeckle(img.Image src, {int radius = 1, int minNeighbors = 2}) {
    final w = src.width;
    final h = src.height;
    final out = img.Image(w, h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = src.getPixel(x, y);
        final lum = img.getRed(p);
        int darkNeighbors = 0;
        for (int dy = -radius; dy <= radius; dy++) {
          for (int dx = -radius; dx <= radius; dx++) {
            if (dx == 0 && dy == 0) continue;
            final nx = x + dx;
            final ny = y + dy;
            if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
            final np = src.getPixel(nx, ny);
            final nl = img.getRed(np);
            if (nl < 200) darkNeighbors++;
          }
        }
        if (lum < 200 && darkNeighbors < minNeighbors) {
          out.setPixel(x, y, img.getColor(255, 255, 255));
        } else {
          out.setPixel(x, y, p);
        }
      }
    }
    return out;
  }

  static img.Image _despeckleBinary(img.Image src, {int radius = 1, int minNeighbors = 2}) {
    final w = src.width;
    final h = src.height;
    final out = img.Image(w, h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = src.getPixel(x, y);
        final isBlack = img.getRed(p) < 128;
        int blackNeighbors = 0;
        for (int dy = -radius; dy <= radius; dy++) {
          for (int dx = -radius; dx <= radius; dx++) {
            if (dx == 0 && dy == 0) continue;
            final nx = x + dx;
            final ny = y + dy;
            if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
            final np = src.getPixel(nx, ny);
            if (img.getRed(np) < 128) blackNeighbors++;
          }
        }
        if (isBlack && blackNeighbors < minNeighbors) {
          out.setPixel(x, y, img.getColor(255, 255, 255));
        } else {
          out.setPixel(x, y, p);
        }
      }
    }
    return out;
  }

  static img.Image _trimTransparentEdges(img.Image src) {
    int minX = src.width, minY = src.height;
    int maxX = -1, maxY = -1;
    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final p = src.getPixel(x, y);
        final a = img.getAlpha(p);
        if (a > 10) {
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }
    if (maxX < minX || maxY < minY) return src;
    return img.copyCrop(src, minX, minY, maxX - minX + 1, maxY - minY + 1);
  }

  static img.Image _cropToSquare(img.Image src) {
    final size = src.width > src.height ? src.width : src.height;
    final canvas = img.Image(size, size);
    img.fill(canvas, img.getColor(255, 255, 255));
    final left = ((size - src.width) / 2).floor();
    final top = ((size - src.height) / 2).floor();
    img.copyInto(canvas, src, dstX: left, dstY: top, blend: false);
    return canvas;
  }

  static List<int> _toEscRasterCentered(img.Image image, {required int printerDotWidth}) {
    final imgW = image.width;
    final imgH = image.height;

    final maxWidth = printerDotWidth;
    img.Image src = image;
    if (imgW > maxWidth) {
      final newH = ((imgH * maxWidth) / imgW).round();
      src = img.copyResize(image, width: maxWidth, height: newH);
    }

    final newW = src.width;
    final newH = src.height;

    final totalPad = (printerDotWidth - newW).clamp(0, printerDotWidth);
    final leftPad = (totalPad / 2).floor();
    final rightPad = totalPad - leftPad;

    final canvasW = leftPad + newW + rightPad;
    final canvas = img.Image(canvasW, newH);
    img.fill(canvas, img.getColor(255, 255, 255));
    img.copyInto(canvas, src, dstX: leftPad, dstY: 0, blend: false);

    final rowBytes = (canvasW + 7) ~/ 8;
    final raster = <int>[];

    for (int y = 0; y < newH; y++) {
      for (int byteIdx = 0; byteIdx < rowBytes; byteIdx++) {
        int byte = 0;
        for (int bit = 0; bit < 8; bit++) {
          final x = byteIdx * 8 + bit;
          if (x < canvasW) {
            final pixel = canvas.getPixel(x, y);
            final lum = img.getRed(pixel);
            if (lum < 128) byte |= (0x80 >> bit);
          }
        }
        raster.add(byte);
      }
    }

    final xL = rowBytes & 0xFF;
    final xH = (rowBytes >> 8) & 0xFF;
    final yL = newH & 0xFF;
    final yH = (newH >> 8) & 0xFF;

    return [0x1D, 0x76, 0x30, 0x00, xL, xH, yL, yH, ...raster];
  }

  static List<int> _bytes(String s) => s.codeUnits;

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return double.tryParse(v)?.toInt() ?? 0;
    return 0;
  }

  static String _pr(String t, int len) {
    if (t.length <= len) return t.padRight(len);
    return '${t.substring(0, len - 3)}...';
  }

  static String _pl(String t, int w) => t.length >= w ? t : t.padLeft(w);

  static String _pb(String left, String right, int w) {
    final space = w - left.length - right.length;
    if (space <= 0) return '$left $right';
    return '$left${' ' * space}$right';
  }

  static String _fDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _fTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';

  static String _rp(int n) {
    if (n == 0) return 'Rp 0';
    return 'Rp ${n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  static String _metode(String t) {
    switch (t) {
      case 'cash':
        return 'Tunai';
      case 'debt':
        return 'Utang';
      case 'qris':
        return 'QRIS';
      case 'transfer':
        return 'Transfer';
      default:
        return t;
    }
  }
}
