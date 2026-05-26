// lib/features/profil/profil_screen.dart
import 'package:flutter/material.dart';
import '../../models/store_setting_model.dart';
import '../../services/store_setting_service.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  StoreSettingModel? _store;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final store = await StoreSettingService.getStoreSetting();
      if (mounted) setState(() { _store = store; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Logo & Nama Toko ──
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Logo
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _store?.logo != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            _store!.logo!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.store, color: Colors.white, size: 40),
                          ),
                        )
                      : const Icon(Icons.store, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 12),
                Text(
                  _store?.storeName ?? 'Toko Sembako',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                if (_store?.address != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _store!.address!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (_store?.phone != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Telp: ${_store!.phone}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Info detail ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.store_outlined,
                  label: 'Nama Toko',
                  value: _store?.storeName ?? '-',
                ),
                const Divider(height: 1, indent: 56),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Alamat',
                  value: _store?.address ?? '-',
                ),
                const Divider(height: 1, indent: 56),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Telepon',
                  value: _store?.phone ?? '-',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Catatan ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF059669), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Untuk mengubah profil toko, silakan login ke halaman admin Laravel.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF059669)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF059669), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7280))),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}