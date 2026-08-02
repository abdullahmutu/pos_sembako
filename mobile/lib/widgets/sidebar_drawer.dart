// lib/widgets/sidebar_drawer.dart
import 'package:flutter/material.dart';
import '../models/store_setting_model.dart';
import '../services/store_setting_service.dart';

class SidebarDrawer extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTap;

  const SidebarDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemTap,
  });

  @override
  State<SidebarDrawer> createState() => _SidebarDrawerState();
}

class _SidebarDrawerState extends State<SidebarDrawer> {
  StoreSettingModel? _store;

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  Future<void> _loadStore() async {
    try {
      final store = await StoreSettingService.getStoreSetting();
      if (mounted) setState(() => _store = store);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final storeName = _store?.storeName ?? 'Toko Sembako';

    return Drawer(
      backgroundColor: const Color(0xFFE8F5F0),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar → pakai logo jika ada, fallback icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFF2D4A3E),
                    ),
                    child: _store?.logo != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              _store!.logo!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.store, color: Colors.white, size: 32),
                            ),
                          )
                        : const Icon(Icons.store, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    storeName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (_store?.phone != null)
                    Text(
                      _store!.phone!,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF059669)),
                    )
                  else
                    const Text(
                      'Toko Sembako',
                      style: TextStyle(fontSize: 13, color: Color(0xFF059669)),
                    ),
                ],
              ),
            ),

            // ── Menu Items ──
            _MenuItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              isSelected: widget.selectedIndex == 0,
              onTap: () => widget.onItemTap(0),
            ),
            _MenuItem(
              icon: Icons.receipt_long_outlined,
              label: 'Transaksi',
              isSelected: widget.selectedIndex == 1,
              onTap: () => widget.onItemTap(1),
            ),
            _MenuItem(
              icon: Icons.add_box_outlined,
              label: 'Tambah Produk',
              isSelected: widget.selectedIndex == 2,
              onTap: () => widget.onItemTap(2),
            ),
            _MenuItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Utang',
              isSelected: widget.selectedIndex == 3,
              onTap: () => widget.onItemTap(3),
            ),
            _MenuItem(
              icon: Icons.wallet_outlined,
              label: 'Pengeluaran',
              isSelected: widget.selectedIndex == 4,
              onTap: () => widget.onItemTap(4),
            ),
            _MenuItem(
              icon: Icons.person_outline,
              label: 'Profil',
              isSelected: widget.selectedIndex == 5,
              onTap: () => widget.onItemTap(5),
            ),

            const Spacer(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Text(
                'Verdant Ledger v1.0.4',
                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC6F0E0) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: isSelected
                    ? const Color(0xFF059669)
                    : const Color(0xFF374151)),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF059669)
                    : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}