import 'package:flutter/material.dart';
import 'ternak_model.dart'; // Import blueprint tadi
import 'tambah_ternak_page.dart';
import 'detail_ternak_page.dart';

class DataTernakPage extends StatefulWidget {
  const DataTernakPage({super.key});

  @override
  State<DataTernakPage> createState() => _DataTernakPageState();
}

class _DataTernakPageState extends State<DataTernakPage> {
  // Ini adalah memori sementara daftar ternak kita
  List<Ternak> daftarTernak = [
    Ternak(nama: 'Sapi Limosin A1', jenis: 'Sapi', berat: '450', kondisi: 'Sehat'),
    Ternak(nama: 'Domba Garut 04', jenis: 'Domba', berat: '65', kondisi: 'Perawatan'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Ternak'),
        backgroundColor: Colors.green.shade100,
      ),
      // Jika data kosong, tampilkan pesan. Jika ada, tampilkan list.
      body: daftarTernak.isEmpty
          ? const Center(child: Text('Belum ada data ternak'))
          : ListView.builder(
              itemCount: daftarTernak.length,
              itemBuilder: (context, index) {
                final hewan = daftarTernak[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: Text(hewan.jenis[0]), // Ambil huruf depan (S/D/K)
                    ),
                    title: Text(hewan.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${hewan.jenis} - ${hewan.berat} kg - ${hewan.kondisi}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async { // <--- Tambahkan 'async' di sini
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailTernakPage(ternak: hewan),
                        ),
                      );
                      // Jika pesan yang dibawa pulang adalah 'hapus'
                      if (result == 'hapus') {
                        setState(() {
                          daftarTernak.remove(hewan); // Buang hewan ini dari memori
                        });
                        // Tampilkan notifikasi kecil di bawah
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Data berhasil dihapus')),
                        );
                      }
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          // Tunggu hasil dari halaman Tambah
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TambahTernakPage()),
          );

          // Jika ada data yang dibawa pulang (result tidak null)
          if (result != null && result is Ternak) {
            setState(() {
              daftarTernak.add(result); // Masukkan ke daftar!
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data berhasil disimpan!')),
            );
          }
        },
      ),
    );
  }
}