import 'package:flutter/material.dart';
import 'database/database_helper.dart'; // Buat fitur Reset Data

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Warna Polban
    final Color polbanBlue = const Color(0xFF1E549F);
    final Color polbanOrange = const Color(0xFFFA9C1B);

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
            // --- KARTU PROFIL ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.blueGrey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: polbanBlue.withOpacity(0.1),
                    child: Icon(Icons.person, size: 40, color: polbanBlue),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Administrator", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: polbanBlue)),
                      const SizedBox(height: 5),
                      const Text("admin@cibeusi.com", style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(5)),
                        child: const Text("Super Admin", style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                      )
                    ],
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            const Text("Aplikasi", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),

            // --- MENU LIST ---
            _buildSettingTile(Icons.info_outline, "Tentang Aplikasi", "Versi 1.0.0 (Polban Edition)", polbanBlue, () {}),
            _buildSettingTile(Icons.help_outline, "Bantuan & Panduan", "Cara penggunaan fitur", polbanBlue, () {}),
            
            const SizedBox(height: 30),
            const Text("Zona Bahaya", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
            const SizedBox(height: 10),

            // --- TOMBOL RESET DATABASE ---
            _buildSettingTile(Icons.delete_forever, "Hapus Semua Data", "Reset database ke awal (hati-hati!)", Colors.red, () {
              _showResetDialog(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reset Database?"),
        content: const Text("PERINGATAN: Semua data Aset dan Keuangan akan dihapus permanen. Aplikasi akan kembali seperti baru instal."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // Hapus Database
              await DatabaseHelper.instance.database.then((db) {
                db.delete('assets');
                db.delete('transactions');
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Data berhasil di-reset bersih!")),
              );
            },
            child: const Text("Ya, Hapus Semua", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}