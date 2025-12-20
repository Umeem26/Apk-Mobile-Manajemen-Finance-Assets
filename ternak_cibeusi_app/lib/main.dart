import 'dart:io'; // Import wajib untuk cek Windows
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Import wajib database Windows
import 'list_asset_page.dart';
import 'finance_page.dart';

void main() {
  // --- KODE KHUSUS WINDOWS (WAJIB ADA) ---
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Inisialisasi Database Desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // ----------------------------------------

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ternak Cibeusi',
      theme: ThemeData(
        primaryColor: const Color(0xFF1E549F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E549F),
          secondary: const Color(0xFFFA9C1B),
          surface: Colors.grey.shade50,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1E549F),
          elevation: 2,
          shadowColor: Colors.black12,
        ),
      ),
      home: const BerandaPage(),
    );
  }
}

class BerandaPage extends StatelessWidget {
  const BerandaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Ternak Cibeusi App',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selamat Datang,',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Text(
              'Dashboard Utama',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E549F)),
            ),
            const SizedBox(height: 30),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.1, 
                children: [
                  // MENU 1: MANAJEMEN ASET
                  HoverMenuCard(
                    icon: Icons.domain_verification,
                    label: 'MANAJEMEN ASET',
                    subLabel: 'Kandang, Alat & Hewan',
                    baseColor: const Color(0xFF1E549F),
                    hoverColor: const Color(0xFF5A8FDC), 
                    iconColor: Colors.white,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ListAssetPage()),
                      );
                    },
                  ),

                  // MENU 2: KEUANGAN
                  HoverMenuCard(
                    icon: Icons.monetization_on,
                    label: 'KEUANGAN',
                    subLabel: 'Pemasukan & Pengeluaran',
                    baseColor: const Color(0xFFFA9C1B),
                    hoverColor: const Color(0xFFFBC02D),
                    iconColor: Colors.white,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FinancePage()),
                      );
                    },
                  ),

                  // MENU 3: LAPORAN
                  HoverMenuCard(
                    icon: Icons.bar_chart,
                    label: 'LAPORAN',
                    subLabel: 'Statistik Peternakan',
                    baseColor: Colors.grey.shade600,
                    hoverColor: Colors.grey.shade500,
                    iconColor: Colors.white,
                    onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Fitur Laporan akan segera hadir!")),
                      );
                    },
                  ),

                  // MENU 4: PENGATURAN
                  HoverMenuCard(
                    icon: Icons.settings,
                    label: 'PENGATURAN',
                    subLabel: 'Profil & Aplikasi',
                    baseColor: Colors.blueGrey.shade700,
                    hoverColor: Colors.blueGrey.shade600,
                    iconColor: Colors.white,
                    onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Fitur Pengaturan akan segera hadir!")),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HoverMenuCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subLabel;
  final Color baseColor;
  final Color hoverColor;
  final Color iconColor;
  final VoidCallback onTap;

  const HoverMenuCard({
    super.key,
    required this.icon,
    required this.label,
    required this.subLabel,
    required this.baseColor,
    required this.hoverColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<HoverMenuCard> createState() => _HoverMenuCardState();
}

class _HoverMenuCardState extends State<HoverMenuCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: _isHovering ? Matrix4.identity().scaled(1.02) : Matrix4.identity(),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isHovering ? widget.hoverColor : widget.baseColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (_isHovering)
                BoxShadow(
                  color: widget.hoverColor.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, size: 42, color: widget.iconColor),
              ),
              const SizedBox(height: 16),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}