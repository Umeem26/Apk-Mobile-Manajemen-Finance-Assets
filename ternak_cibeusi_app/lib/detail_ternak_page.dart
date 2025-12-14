import 'package:flutter/material.dart';
import 'ternak_model.dart';
import 'tambah_ternak_page.dart';

class DetailTernakPage extends StatefulWidget {
  final Ternak ternak; // Data awal

  const DetailTernakPage({super.key, required this.ternak});

  @override
  State<DetailTernakPage> createState() => _DetailTernakPageState();
}

class _DetailTernakPageState extends State<DetailTernakPage> {
  late Ternak dataTernak; // Data yang bisa berubah

  @override
  void initState() {
    super.initState();
    dataTernak = widget.ternak; // Inisialisasi data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(dataTernak.nama),
        backgroundColor: _getWarnaStatus(dataTernak.kondisi),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
               // Logika hapus (sama seperti sebelumnya)
               showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Hapus Data?'),
                  content: Text('Yakin ingin menghapus ${dataTernak.nama}?'),
                  actions: [
                    TextButton(child: const Text('Batal'), onPressed: () => Navigator.pop(ctx)),
                    TextButton(
                      child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context, 'hapus');
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                color: _getWarnaStatus(dataTernak.kondisi).withOpacity(0.2),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Icon(Icons.pets, size: 100, color: _getWarnaStatus(dataTernak.kondisi)),
                  const SizedBox(height: 10),
                  Text(dataTernak.nama, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Status: ${dataTernak.kondisi}', style: TextStyle(fontSize: 16, color: _getWarnaStatus(dataTernak.kondisi), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInfoCard(Icons.category, 'Jenis', dataTernak.jenis),
                  _buildInfoCard(Icons.monitor_weight, 'Berat', '${dataTernak.berat} kg'),
                  _buildInfoCard(Icons.medical_services, 'Kesehatan', dataTernak.kondisi),
                ],
              ),
            ),
            // Tombol Edit
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Buka halaman edit, kirim data saat ini
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TambahTernakPage(ternakEdit: dataTernak),
                    ),
                  );

                  // Jika ada data update yang dikirim balik
                  if (result != null && result is Ternak) {
                    setState(() {
                      dataTernak = result; // Update tampilan dengan data baru
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil diperbarui!')));
                  }
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Data'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Color _getWarnaStatus(String kondisi) {
    if (kondisi == 'Sakit' || kondisi == 'Perawatan') return Colors.orange;
    if (kondisi == 'Hamil') return Colors.purple;
    return Colors.green;
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.blueGrey),
        title: Text(label, style: const TextStyle(color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }
}