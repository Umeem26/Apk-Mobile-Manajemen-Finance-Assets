import 'package:flutter/material.dart';
import 'asset_model.dart';

class FormAssetPage extends StatefulWidget {
  final AssetModel? assetEdit; // Data jika mode edit
  final Color themeColor; // <-- Tambahan: Warna tema yang dioper

  // Kita wajibkan pengiriman warna tema
  const FormAssetPage({super.key, this.assetEdit, required this.themeColor});

  @override
  State<FormAssetPage> createState() => _FormAssetPageState();
}

class _FormAssetPageState extends State<FormAssetPage> {
  final _namaController = TextEditingController();
  final _jenisController = TextEditingController();
  final _jumlahController = TextEditingController();
  final _lokasiController = TextEditingController();

  String _kategori = 'Biologis';
  String _satuan = 'Ekor';
  String _kondisi = 'Baik';

  final List<String> _kategoriList = ['Biologis', 'Operasional', 'Kandang'];
  final List<String> _kondisiList = ['Baik', 'Perawatan/Service', 'Rusak/Sakit', 'Afkir/Tidak Aktif'];

  @override
  void initState() {
    super.initState();
    if (widget.assetEdit != null) {
      _namaController.text = widget.assetEdit!.nama;
      _jenisController.text = widget.assetEdit!.jenis;
      _jumlahController.text = widget.assetEdit!.jumlah.toString();
      _lokasiController.text = widget.assetEdit!.lokasi;
      _kategori = widget.assetEdit!.kategori;
      _satuan = widget.assetEdit!.satuan;
      
      if (_kondisiList.contains(widget.assetEdit!.kondisi)) {
        _kondisi = widget.assetEdit!.kondisi;
      } else {
        _kondisi = 'Baik'; 
      }
    } else {
        // Jika mode tambah baru, set kategori default berdasarkan warna tema untuk UX yang lebih baik
        // (Opsional, tapi membantu)
        if (widget.themeColor == const Color(0xFF1E549F)) { // Biru Kandang
             _kategori = 'Kandang'; _satuan = 'Unit';
        } else if (widget.themeColor == const Color(0xFFFA9C1B)) { // Oranye Ops
             _kategori = 'Operasional'; _satuan = 'Unit';
        }
    }
  }

  void _updateSatuanOtomatis(String kategoriBaru) {
    setState(() {
      _kategori = kategoriBaru;
      if (_kategori == 'Biologis') {
        _satuan = 'Ekor';
      } else if (_kategori == 'Operasional') {
        _satuan = 'Unit';
      } else {
        _satuan = 'Unit';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assetEdit == null ? 'Tambah Aset Baru' : 'Edit Aset'),
        backgroundColor: widget.themeColor, // <-- GUNAKAN WARNA TEMA DISINI
        iconTheme: const IconThemeData(color: Colors.white), // Ikon back putih
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), // Teks putih
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _kategori,
              decoration: const InputDecoration(
                labelText: 'Kategori Aset',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _kategoriList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => _updateSatuanOtomatis(val!),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _namaController,
              decoration: InputDecoration(
                labelText: _kategori == 'Biologis' ? 'Nama Hewan / Kode' : 'Nama Aset / Alat',
                hintText: _kategori == 'Biologis' ? 'Contoh: Ayam Petelur A1' : 'Contoh: Mesin Pencacah',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _jenisController,
              decoration: InputDecoration(
                labelText: 'Jenis / Spesifikasi',
                hintText: _kategori == 'Biologis' ? 'Contoh: Lele Sangkuriang' : 'Contoh: Diesel 5000 Watt',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.info_outline),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _jumlahController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: TextEditingController(text: _satuan),
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Satuan',
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _lokasiController,
              decoration: const InputDecoration(
                labelText: 'Lokasi Penempatan',
                hintText: 'Contoh: Kolam 3 / Gudang A',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pin_drop),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _kondisi,
              decoration: const InputDecoration(
                labelText: 'Kondisi Saat Ini',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.health_and_safety),
              ),
              items: _kondisiList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _kondisi = val!),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () {
                if (_namaController.text.isEmpty) return;

                final assetBaru = AssetModel(
                  id: widget.assetEdit?.id ?? DateTime.now().toString(),
                  nama: _namaController.text,
                  kategori: _kategori,
                  jenis: _jenisController.text,
                  jumlah: int.tryParse(_jumlahController.text) ?? 0,
                  satuan: _satuan,
                  lokasi: _lokasiController.text,
                  kondisi: _kondisi,
                );
                Navigator.pop(context, assetBaru);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.themeColor, // <-- GUNAKAN WARNA TEMA DISINI JUGA
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('SIMPAN ASET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}