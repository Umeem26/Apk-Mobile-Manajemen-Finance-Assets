import 'package:flutter/material.dart';
import 'data_ternak_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ternak Cibeusi',
      theme: ThemeData(
        // Mengubah warna tema menjadi hijau (identik dengan peternakan/alam)
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Ternak Cibeusi App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menu 1: Data Ternak
            _buildMenuCard(
              icon: Icons.grass,
              label: 'Data Ternak',
              color: Colors.green.shade100,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DataTernakPage()),
                );
              },
            ), // <--- Pastikan ada koma dan kurung tutup ini

            // Menu 2: Keuangan
            _buildMenuCard(
              icon: Icons.monetization_on,
              label: 'Keuangan',
              color: Colors.orange.shade100,
              onTap: () {
                print("Masuk ke Keuangan");
              },
            ),

            // Menu 3: Kesehatan
            _buildMenuCard(
              icon: Icons.medical_services,
              label: 'Kesehatan',
              color: Colors.blue.shade100,
              onTap: () {
                print("Masuk ke Kesehatan");
              },
            ),

            // Menu 4: Laporan
            _buildMenuCard(
              icon: Icons.bar_chart,
              label: 'Laporan',
              color: Colors.purple.shade100,
              onTap: () {
                print("Masuk ke Laporan");
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget kecil untuk membuat Kartu Menu agar kodingan rapi
  Widget _buildMenuCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.black54),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}