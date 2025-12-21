import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database/database_helper.dart';

// Paket untuk Backup
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final Color polbanBlue = const Color(0xFF1E549F);
  final Color polbanOrange = const Color(0xFFFA9C1B);

 // --- LOGIKA BACKUP DATA (SIMPAN LOKAL) ---
  Future<void> _backupData() async {
    try {
      final db = DatabaseHelper.instance;
      final trans = await db.getTransactions();

      if (trans.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak ada data transaksi untuk dibackup.")));
        return;
      }

      List<List<dynamic>> rows = [];
      // Header CSV
      rows.add(["Tanggal", "Jenis", "Kategori", "Nominal", "Deskripsi"]);

      // Isi Data
      for (var t in trans) {
        rows.add([
          t.date,
          t.type == 'IN' ? 'Pemasukan' : 'Pengeluaran',
          t.category,
          t.amount,
          t.description
        ]);
      }

      // Konversi ke String CSV
      String csvData = const ListToCsvConverter().convert(rows);

      // --- TENTUKAN LOKASI SIMPAN (WINDOWS vs ANDROID) ---
      String? filePath;
      String fileName = "Backup_Ternak_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv";

      if (Platform.isWindows) {
        // Untuk Windows: Masuk ke folder Downloads user
        final directory = await getDownloadsDirectory(); 
        if (directory != null) {
          filePath = "${directory.path}\\$fileName";
        }
      } else {
        // Untuk Android: Masuk ke folder External App (Agar tidak perlu izin rumit)
        // Lokasi biasanya: Android/data/com.example.ternak_cibeusi_app/files/
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          filePath = "${directory.path}/$fileName";
        }
      }

      if (filePath != null) {
        final file = File(filePath);
        await file.writeAsString(csvData);

        // Beri Tahu User Lokasinya
        _showSuccessDialog(filePath);
      } else {
        throw Exception("Gagal menemukan folder penyimpanan.");
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal Backup: $e")));
    }
  }

  // Dialog Sukses biar User Tau Filenya Dimana
  void _showSuccessDialog(String path) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Backup Berhasil! ✅"),
        content: Text("File tersimpan di:\n\n$path\n\nSilakan cek folder tersebut."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK, Mantap"),
          ),
        ],
      ),
    );
  }

  // --- LOGIKA TUTUP BUKU ---
  void _showCloseBookDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tutup Buku Akhir Tahun?"),
        content: const Text(
          "Tindakan ini akan:\n"
          "1. Menghapus semua riwayat transaksi.\n"
          "2. Menjadikan sisa saldo saat ini sebagai Modal Awal baru.\n\n"
          "Pastikan Anda sudah melakukan BACKUP sebelum melanjutkan!",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: polbanBlue),
            onPressed: () async {
              Navigator.pop(ctx); // Tutup dialog dulu
              await DatabaseHelper.instance.closeBookAndReset();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Berhasil Tutup Buku! Periode baru dimulai.")),
              );
            },
            child: const Text("Ya, Tutup Buku", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- LOGIKA RESET TOTAL ---
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Semua Data?"),
        content: const Text("PERINGATAN: Semua data Aset dan Keuangan akan dihapus permanen menjadi 0."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseHelper.instance.nukeDatabase();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Aplikasi bersih seperti baru!")),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: polbanBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HEADER PROFIL ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [polbanBlue, const Color(0xFF4376C4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: polbanBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.grey[200],
                      child: Icon(Icons.person, size: 40, color: polbanBlue),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Administrator", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 5),
                        const Text("admin@cibeusi.com", style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: polbanOrange, borderRadius: BorderRadius.circular(20)),
                          child: const Text("Super Admin", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // --- 2. MANAJEMEN DATA (Updated) ---
            _sectionHeader("Manajemen Data"),
            
            // Tombol Backup
            _buildMenuTile(
              Icons.cloud_download, 
              "Backup Data Transaksi", 
              "Unduh riwayat transaksi (.csv)", 
              Colors.green, 
              _backupData
            ),

            // Tombol Tutup Buku
            _buildMenuTile(
              Icons.change_circle, 
              "Tutup Buku Akhir Tahun", 
              "Reset transaksi, saldo jadi modal awal", 
              polbanBlue, 
              _showCloseBookDialog
            ),

            const SizedBox(height: 20),
            
            // --- 3. INFO & BANTUAN ---
            _sectionHeader("Info & Bantuan"),
            _buildMenuTile(Icons.info_outline, "Tentang Aplikasi", "Versi 1.1.0 (Polban Edition)", Colors.blueGrey, () {}),
            
            const SizedBox(height: 30),
            
            // --- 4. ZONA BAHAYA ---
            const Padding(
              padding: EdgeInsets.only(left: 5, bottom: 10),
              child: Text("Zona Bahaya", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete_forever, color: Colors.red, size: 22),
                ),
                title: const Text("Hapus Semua Data", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                subtitle: const Text("Format ulang database ke 0", style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                onTap: _showResetDialog,
              ),
            ),

            const SizedBox(height: 40),
            Center(
              child: Text("Ternak Cibeusi App © 2025\nDeveloped with Flutter", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 5),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800], fontSize: 14)),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[300], size: 24),
        onTap: onTap,
      ),
    );
  }
}