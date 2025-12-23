import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; // Import ini

import 'list_asset_page.dart';
import 'list_finance_page.dart';
import 'report_page.dart';
import 'settings_page.dart';
import 'database/database_helper.dart';
import 'splash_page.dart'; // Import Halaman Splash

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SiKaya App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8), 
        fontFamily: 'Roboto',
      ),
      home: const SplashPage(), // [UBAH] Mulai dari SplashPage
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color polbanBlue = const Color(0xFF1E549F);
  final Color polbanOrange = const Color(0xFFFA9C1B);
  
  int _totalTernak = 0;
  double _saldoKas = 0;
  double _totalMasuk = 0;
  double _totalKeluar = 0;
  String _lastUpdate = "-";
  
  // [BARU] Variabel Nama
  String _ownerName = "Juragan Ternak"; 

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  void _loadSummary() async {
    final db = DatabaseHelper.instance;
    final prefs = await SharedPreferences.getInstance(); // Akses Prefs

    // 1. Ambil Nama User
    String? savedName = prefs.getString('owner_name');
    
    // 2. Hitung Aset
    final assets = await db.readAllAssets();
    int countTernak = 0;
    for (var a in assets) {
      if (a.kategori == 'Ternak') countTernak += a.jumlah;
    }
    
    // 3. Hitung Keuangan
    final cashflow = await db.getSaldoCashflow();

    if (mounted) {
      setState(() {
        _ownerName = savedName ?? "Juragan Ternak"; // Set Nama
        _totalTernak = countTernak;
        _totalMasuk = cashflow['in']!;
        _totalKeluar = cashflow['out']!;
        _saldoKas = cashflow['total']!;
        _lastUpdate = DateFormat('dd MMM HH:mm').format(DateTime.now());
      });
    }
  }

  String _fmtUangFull(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    bool hasData = _totalMasuk > 0 || _totalKeluar > 0;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: 240, 
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [polbanBlue, const Color(0xFF2A75C7)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Selamat Datang,", style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 4),
                          // [UPDATE] Tampilkan Nama User
                          Text(_ownerName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: const CircleAvatar(radius: 24, backgroundColor: Colors.white, child: Icon(Icons.person, color: Color(0xFF1E549F))),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // DASHBOARD CARD
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: const Color(0xFF1E549F).withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _itemInfo(Icons.pets, polbanOrange, "Populasi", "$_totalTernak Ekor"),
                              const SizedBox(height: 20),
                              _itemInfo(Icons.account_balance_wallet, Colors.blueAccent, "Saldo Kas", _fmtUangFull(_saldoKas)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 80, color: Colors.grey[200], margin: const EdgeInsets.symmetric(horizontal: 15)),
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 80, 
                            child: hasData 
                              ? Stack(
                                  children: [
                                    PieChart(
                                      PieChartData(
                                        sectionsSpace: 0,
                                        centerSpaceRadius: 28,
                                        sections: [
                                          PieChartSectionData(color: Colors.greenAccent[700], value: _totalMasuk, title: '', radius: 10),
                                          PieChartSectionData(color: Colors.redAccent, value: _totalKeluar, title: '', radius: 10),
                                        ],
                                      ),
                                    ),
                                    Center(
                                      child: Icon(
                                        _saldoKas >= 0 ? Icons.check_circle_rounded : Icons.warning_rounded,
                                        color: _saldoKas >= 0 ? Colors.green : Colors.red,
                                        size: 28,
                                      ),
                                    )
                                  ],
                                )
                              : const Center(child: Icon(Icons.pie_chart_outline, color: Colors.grey, size: 40)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Menu Utama", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
                            Text("Updated: $_lastUpdate", style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 1.2, 
                            padding: const EdgeInsets.only(bottom: 20),
                            children: [
                              HoverMenuCard(title: "Aset Ternak", icon: Icons.inventory_2_rounded, color: polbanBlue, onTap: () => _navTo(const ListAssetPage())),
                              HoverMenuCard(title: "Keuangan", icon: Icons.monetization_on_rounded, color: polbanOrange, onTap: () => _navTo(const ListFinancePage())),
                              HoverMenuCard(title: "Laporan", icon: Icons.analytics_rounded, color: Colors.teal, onTap: () => _navTo(const ReportPage())),
                              HoverMenuCard(title: "Pengaturan", icon: Icons.settings_rounded, color: Colors.blueGrey, onTap: () => _navTo(const SettingsPage())),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navTo(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => page));
    _loadSummary();
  }

  Widget _itemInfo(IconData icon, Color color, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 14, color: color), const SizedBox(width: 5), Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12))]),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: Colors.blueGrey[900], fontSize: 17, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class HoverMenuCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const HoverMenuCard({Key? key, required this.title, required this.icon, required this.color, required this.onTap}) : super(key: key);

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
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scale(_isHovering ? 1.05 : 1.0), 
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _isHovering ? widget.color.withOpacity(0.3) : Colors.grey.withOpacity(0.05),
                blurRadius: _isHovering ? 20 : 10,
                offset: _isHovering ? const Offset(0, 10) : const Offset(0, 5),
              )
            ],
            border: _isHovering ? Border.all(color: widget.color.withOpacity(0.5), width: 2) : Border.all(color: Colors.transparent),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, size: 32, color: widget.color),
              ),
              const SizedBox(height: 15),
              Text(widget.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            ],
          ),
        ),
      ),
    );
  }
}