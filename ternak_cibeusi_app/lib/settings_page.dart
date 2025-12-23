import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database/database_helper.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import ini
import 'splash_page.dart'; // Untuk Restart ke Splash

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final Color polbanBlue = const Color(0xFF1E549F);
  final Color polbanOrange = const Color(0xFFFA9C1B);
  String _ownerName = "Administrator"; // Default

  @override
  void initState() {
    super.initState();
    _loadOwnerName();
  }

  void _loadOwnerName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ownerName = prefs.getString('owner_name') ?? "Administrator";
    });
  }

  // ... (Fungsi Backup _backupData Tetap Sama seperti sebelumnya) ...
  // Silakan copy fungsi _backupData dari kode sebelumnya jika perlu, atau biarkan jika sudah ada.
  // Agar ringkas saya persingkat di sini, tapi pastikan fungsi _backupData Anda tetap ada.
  
  Future<void> _backupData() async {
     // ... (Kode Backup Sama seperti File Sebelumnya) ...
     try {
      final db = DatabaseHelper.instance;
      final trans = await db.getTransactions();
      if (trans.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data kosong."))); return; }
      List<List<dynamic>> rows = [];
      rows.add(["Tanggal", "Jenis", "Kategori", "Nominal", "Deskripsi"]);
      for (var t in trans) { rows.add([t.date, t.type, t.category, t.amount, t.description]); }
      String csvData = const ListToCsvConverter().convert(rows);
      String? filePath;
      String fileName = "Backup_Ternak_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv";
      if (Platform.isWindows) { final dir = await getDownloadsDirectory(); if (dir != null) filePath = "${dir.path}\\$fileName"; } 
      else { final dir = await getExternalStorageDirectory(); if (dir != null) filePath = "${dir.path}/$fileName"; }
      if (filePath != null) { final file = File(filePath); await file.writeAsString(csvData); _showDialog("Backup Berhasil", "File di:\n$filePath"); }
    } catch (e) { _showDialog("Gagal", e.toString()); }
  }
  void _showDialog(String t, String c) => showDialog(context: context, builder: (ctx) => AlertDialog(title: Text(t), content: Text(c), actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("OK"))]));


  void _showCloseBookDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Tutup Buku?"), content: const Text("Data reset & saldo jadi modal awal."), actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Batal")), ElevatedButton(onPressed: () async { Navigator.pop(ctx); await DatabaseHelper.instance.closeBookAndReset(); }, child: const Text("Ya"))]));
  }

  // [UPDATE] RESET TOTAL JUGA HAPUS NAMA
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Semua Data?"),
        content: const Text("PERINGATAN: Semua data & Nama Peternakan akan dihapus. Aplikasi akan restart."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // 1. Hapus DB
              await DatabaseHelper.instance.nukeDatabase();
              
              // 2. Hapus Nama di Prefs
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); 

              if (!mounted) return;
              Navigator.pop(ctx);
              
              // 3. Restart ke Splash Screen (Biar masuk Onboarding lagi)
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(builder: (context) => const SplashPage()), 
                (route) => false
              );
            },
            child: const Text("Hapus Semuanya", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: polbanBlue, foregroundColor: Colors.white, elevation: 0, centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER PROFIL
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]),
              child: Row(
                children: [
                  CircleAvatar(radius: 30, backgroundColor: polbanBlue.withOpacity(0.1), child: Icon(Icons.person, size: 35, color: polbanBlue)),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // [UPDATE] Nama Diambil dari Input
                      Text(_ownerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Pemilik Peternakan", style: TextStyle(color: polbanOrange, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),

            _header("Manajemen Data"),
            _tile(Icons.download_rounded, "Backup Data", "Simpan ke CSV", Colors.green, _backupData),
            _tile(Icons.history_edu_rounded, "Tutup Buku", "Reset periode akuntansi", polbanBlue, _showCloseBookDialog),
            
            const SizedBox(height: 20),
            _header("Sistem"),
            _tile(Icons.delete_forever_rounded, "Reset Aplikasi", "Hapus data & Login ulang", Colors.red, _showResetDialog),
            
            const SizedBox(height: 40),
            const Center(child: Text("Versi 1.1.0 (Polban Edition)", style: TextStyle(color: Colors.grey, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _header(String t) => Padding(padding: const EdgeInsets.only(bottom: 10, left: 5), child: Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])));
  Widget _tile(IconData i, String t, String s, Color c, VoidCallback tap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(i, color: c)),
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(s, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        onTap: tap,
      ),
    );
  }
}