import 'package:flutter/material.dart';
import 'ternak_model.dart';

class TambahTernakPage extends StatefulWidget {
  final Ternak? ternakEdit; // Variabel penampung data jika mode edit

  const TambahTernakPage({super.key, this.ternakEdit});

  @override
  State<TambahTernakPage> createState() => _TambahTernakPageState();
}

class _TambahTernakPageState extends State<TambahTernakPage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _beratController = TextEditingController();
  String _jenisHewan = 'Sapi';
  String _kondisiHewan = 'Sehat';

  @override
  void initState() {
    super.initState();
    // Cek: Apakah ini mode Edit? (ada data yang dikirim?)
    if (widget.ternakEdit != null) {
      _namaController.text = widget.ternakEdit!.nama;
      _beratController.text = widget.ternakEdit!.berat;
      _jenisHewan = widget.ternakEdit!.jenis;
      _kondisiHewan = widget.ternakEdit!.kondisi;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Judul berubah dinamis sesuai mode
        title: Text(widget.ternakEdit == null ? 'Tambah Ternak Baru' : 'Edit Data Ternak'),
        backgroundColor: Colors.green.shade100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama / Tag ID Hewan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _jenisHewan,
              decoration: const InputDecoration(labelText: 'Jenis Hewan', border: OutlineInputBorder()),
              items: ['Sapi', 'Domba', 'Kambing', 'Kerbau']
                  .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                  .toList(),
              onChanged: (value) => setState(() => _jenisHewan = value!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _beratController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Berat (kg)',
                border: OutlineInputBorder(),
                suffixText: 'kg',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _kondisiHewan,
              decoration: const InputDecoration(labelText: 'Kondisi', border: OutlineInputBorder()),
              items: ['Sehat', 'Sakit', 'Hamil', 'Perawatan']
                  .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                  .toList(),
              onChanged: (value) => setState(() => _kondisiHewan = value!),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final ternakBaru = Ternak(
                  nama: _namaController.text,
                  jenis: _jenisHewan,
                  berat: _beratController.text,
                  kondisi: _kondisiHewan,
                );
                // Kirim data balik
                Navigator.pop(context, ternakBaru);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.ternakEdit == null ? 'SIMPAN DATA' : 'UPDATE DATA',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}