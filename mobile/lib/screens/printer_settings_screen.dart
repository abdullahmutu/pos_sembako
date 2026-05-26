// lib/screens/printer_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/printer_service.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  List<BluetoothDevice> _printers = [];
  bool _isScanning = false;
  String? _connectedDeviceAddress;
  String? _connectedDeviceName;

  @override
  void initState() {
    super.initState();
    _loadConnectedPrinter();
  }

  Future<void> _loadConnectedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _connectedDeviceAddress = prefs.getString('printer_address');
      _connectedDeviceName = prefs.getString('printer_name');
    });
  }

  Future<void> _saveConnectedPrinter(String? address, String? name) async {
    final prefs = await SharedPreferences.getInstance();
    if (address == null || address.isEmpty) {
      await prefs.remove('printer_address');
      await prefs.remove('printer_name');
      setState(() {
        _connectedDeviceAddress = null;
        _connectedDeviceName = null;
      });
    } else {
      await prefs.setString('printer_address', address);
      await prefs.setString('printer_name', name ?? '');
      setState(() {
        _connectedDeviceAddress = address;
        _connectedDeviceName = name;
      });
    }
  }

  Future<void> _scanAndConnect() async {
    setState(() => _isScanning = true);
    final devices = await PrinterService.scanBluetooth();
    setState(() {
      _printers = devices;
      _isScanning = false;
    });
  }

  Future<void> _connect(BluetoothDevice device) async {
    final success = await PrinterService.connect(device);
    if (!mounted) return; // guard

    if (success) {
      await _saveConnectedPrinter(device.address, device.name);
      if (!mounted) return; // guard lagi sebelum context
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terhubung ke ${device.name ?? device.address}')),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal terhubung')),
      );
    }
  }

  Future<void> _disconnect() async {
    await PrinterService.disconnect();
    await _saveConnectedPrinter(null, null);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Printer diputus')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Printer')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_connectedDeviceAddress != null)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Printer terhubung: ${_connectedDeviceName ?? _connectedDeviceAddress}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: _disconnect,
                        child: const Text('Putus'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isScanning ? null : _scanAndConnect,
              icon: const Icon(Icons.bluetooth),
              label: Text(_isScanning ? 'Memindai...' : 'Scan Printer'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _printers.isEmpty
                  ? const Center(child: Text('Tidak ada printer ditemukan'))
                  : ListView.builder(
                      itemCount: _printers.length,
                      itemBuilder: (_, i) {
                        final p = _printers[i];
                        final isConnected = p.address == _connectedDeviceAddress;
                        return ListTile(
                          leading: const Icon(Icons.print),
                          title: Text(p.name ?? 'Unknown'),
                          subtitle: Text(p.address ?? ''),
                          trailing: isConnected
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : ElevatedButton(
                                  onPressed: () => _connect(p),
                                  child: const Text('Hubungkan'),
                                ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
