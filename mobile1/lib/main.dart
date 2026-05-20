import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile1/features/hutang/utang_screen.dart';
import 'package:mobile1/widgets/sidebar_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile1/features/auth/login_screen.dart';
import 'package:mobile1/features/dashboard/dashboard_screen.dart';
import 'package:mobile1/features/transaksi/transaksi_screen.dart';
import 'package:mobile1/features/produk/produk_screen.dart';
import 'package:mobile1/features/profil/profil_screen.dart';

void main() async  {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kasir App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF059669)),
        useMaterial3: true,
      ),
      home: const SplashScreen(), // ✅ cek token dulu
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home' : (_) => const MainScreen(),
      },
    );
  }
}

// ── Cek apakah sudah login ──
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        token != null ? '/home' : '/login',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF059669),
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

// ── Main Screen dengan Sidebar ──
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Dashboard',
    'Transaksi',
    'Tambah Produk',
    'Utang',
    'Profil',
  ];

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransaksiScreen(),
    const ProdukScreen(),
    const UtangScreen(),
    const ProfilScreen(),
  ];

  void _onMenuTap(int index) {
    Navigator.pop(context);
    setState(() => _selectedIndex = index);
  }

  // ── Logout ──
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          // Tombol logout
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF6B7280)),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: SidebarDrawer(
        selectedIndex: _selectedIndex,
        onItemTap: _onMenuTap,
      ),
      body: _screens[_selectedIndex],
    );
  }
}