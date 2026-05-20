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

  @override
  void initState() {
    super.initState();
    _loadConnectedPrinter();
  }

  Future<void> _loadConnectedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _connectedDeviceAddress = prefs.getString('printer_address');
    });
  }

  Future<void> _saveConnectedPrinter(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_address', address);
    setState(() => _connectedDeviceAddress = address);
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
    if (success && mounted) {
      await _saveConnectedPrinter(device.address);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terhubung ke ${device.name}')),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal terhubung')),
      );
    }
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
                      Expanded(child: Text('Printer terhubung: $_connectedDeviceAddress')),
                      TextButton(
                        onPressed: () async {
                          await PrinterService.disconnect();
                          await _saveConnectedPrinter('');
                          setState(() {});
                        },
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
              child: ListView.builder(
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