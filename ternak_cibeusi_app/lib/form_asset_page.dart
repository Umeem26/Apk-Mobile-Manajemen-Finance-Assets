import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; 
import 'dart:io';
import 'asset_model.dart';
import 'database/database_helper.dart';

class FormAssetPage extends StatefulWidget {
  final AssetModel? asset; 
  const FormAssetPage({Key? key, this.asset}) : super(key: key);

  @override
  State<FormAssetPage> createState() => _FormAssetPageState();
}

class _FormAssetPageState extends State<FormAssetPage> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Color polbanBlue = const Color(0xFF1E549F);
  
  // Controllers
  late TextEditingController _quantityController;
  late TextEditingController _descController;
  late TextEditingController _expiredDateController; // Manual Text DD/MM/YYYY
  late TextEditingController _usageTernakController; // Butuh brp ternak
  late TextEditingController _usageDaysController;   // Butuh brp hari

  // Kategori
  String _kategoriUtama = 'Ternak';
  final List<String> _listKategoriUtama = ['Ternak', 'Operasional Habis Pakai', 'Aset Tetap'];

  // Hewan (+DOMBA)
  String? _jenisHewan;
  final List<String> _listHewan = ['Ayam', 'Bebek', 'Lele', 'Kambing', 'Sapi', 'Domba'];
  
  String? _tipeHewan;
  final List<String> _listTipe = ['Petelur', 'Pedaging', 'Pejantan', 'Anakan/Bibit', 'Qurban/Aqiqah'];

  // Kondisi
  String? _kondisi;
  final List<String> _kondisiHewan = ['Sehat', 'Sakit', 'Karantina', 'Mati/Afkir'];
  final List<String> _kondisiBarang = ['Baik', 'Rusak Ringan', 'Rusak Berat', 'Kadaluarsa'];

  // Satuan (+KARUNG, LITER, TON, DLL)
  String? _satuanDipilih;
  final List<String> _listSatuan = [
    'Unit', 'Buah', 'Ekor', 
    'Karung', 'Sak', 'Liter', 'Mili Liter', 
    'Kg', 'Ton', 'Kuintal', 'Botol'
  ];

  String? _namaManual;
  String _imagePath = '';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.asset?.jumlah.toString() ?? '');
    _descController = TextEditingController(text: widget.asset?.deskripsi ?? '');
    
    // Init data baru
    _expiredDateController = TextEditingController(text: widget.asset?.expiredDate ?? '');
    _usageTernakController = TextEditingController(text: widget.asset?.usageForTernak?.toString() ?? '');
    _usageDaysController = TextEditingController(text: widget.asset?.usageDuration?.toString() ?? '');
    
    _kondisi = widget.asset?.kondisi;
    _imagePath = widget.asset?.imagePath ?? '';
    _satuanDipilih = widget.asset?.satuan;

    if (widget.asset != null) {
      if (_listKategoriUtama.contains(widget.asset!.kategori)) {
        _kategoriUtama = widget.asset!.kategori;
      }
      
      if (_kategoriUtama == 'Ternak') {
        final split = widget.asset!.nama.split(' - ');
        if (split.length >= 2) {
          if (_listHewan.contains(split[0])) _jenisHewan = split[0];
          if (_listTipe.contains(split[1])) _tipeHewan = split[1];
        } else {
          if (_listHewan.contains(widget.asset!.nama)) _jenisHewan = widget.asset!.nama;
        }
      } else {
        _namaManual = widget.asset!.nama;
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _imagePath = image.path);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _descController.dispose();
    _expiredDateController.dispose();
    _usageTernakController.dispose();
    _usageDaysController.dispose();
    super.dispose();
  }

  void _saveAsset() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      String finalName = '';
      
      if (_kategoriUtama == 'Ternak') {
        if (_jenisHewan == null || _tipeHewan == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lengkapi data hewan!")));
          return;
        }
        finalName = "$_jenisHewan - $_tipeHewan";
      } else {
        if (_namaManual == null || _namaManual!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama Aset wajib diisi!")));
          return;
        }
        finalName = _namaManual!;
      }

      String finalKondisi = _kondisi ?? (_kategoriUtama == 'Ternak' ? 'Sehat' : 'Baik');
      
      // Default satuan jika user lupa pilih
      String finalSatuan = _satuanDipilih ?? (_kategoriUtama == 'Ternak' ? 'Ekor' : 'Unit');

      final newAsset = AssetModel(
        id: widget.asset?.id,
        nama: finalName,
        kategori: _kategoriUtama,
        jumlah: int.parse(_quantityController.text),
        deskripsi: _descController.text,
        imagePath: _imagePath,
        date: widget.asset?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
        kondisi: finalKondisi,
        satuan: finalSatuan,
        // SIMPAN DATA KHUSUS OPERASIONAL
        expiredDate: _kategoriUtama == 'Operasional Habis Pakai' ? _expiredDateController.text : null,
        usageForTernak: _kategoriUtama == 'Operasional Habis Pakai' ? int.tryParse(_usageTernakController.text) : 0,
        usageDuration: _kategoriUtama == 'Operasional Habis Pakai' ? int.tryParse(_usageDaysController.text) : 0,
      );

      if (widget.asset == null) await _dbHelper.create(newAsset);
      else await _dbHelper.update(newAsset);
      
      if (!mounted) return;
      Navigator.pop(context); 
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> currentKondisiList = _kategoriUtama == 'Ternak' ? _kondisiHewan : _kondisiBarang;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.asset == null ? 'Tambah Data' : 'Edit Data'),
        backgroundColor: polbanBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FOTO ASET
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade400),
                    image: _imagePath.isNotEmpty
                        ? DecorationImage(image: FileImage(File(_imagePath)), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _imagePath.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 50, color: Colors.grey[600]),
                            const SizedBox(height: 10),
                            Text("Ketuk untuk upload foto", style: TextStyle(color: Colors.grey[600])),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 25),

              // KATEGORI UTAMA
              _buildSectionTitle("Kategori Aset"),
              DropdownButtonFormField<String>(
                value: _kategoriUtama,
                decoration: _inputDecoration(icon: Icons.category),
                items: _listKategoriUtama.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                onChanged: (val) {
                  setState(() {
                    _kategoriUtama = val!;
                    _jenisHewan = null;
                    _tipeHewan = null;
                    _kondisi = null;
                    _satuanDipilih = null;
                  });
                },
              ),
              const SizedBox(height: 20),

              // PILIHAN TERNAK / BARANG
              if (_kategoriUtama == 'Ternak') ...[
                _buildSectionTitle("Jenis Hewan"),
                DropdownButtonFormField<String>(
                  value: _jenisHewan,
                  hint: const Text("Pilih Hewan (Domba/Sapi/dll)"),
                  decoration: _inputDecoration(icon: Icons.pets),
                  items: _listHewan.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                  onChanged: (val) => setState(() => _jenisHewan = val),
                ),
                const SizedBox(height: 15),
                _buildSectionTitle("Tipe Produksi"),
                DropdownButtonFormField<String>(
                  value: _tipeHewan,
                  hint: const Text("Pilih Tipe"),
                  decoration: _inputDecoration(icon: Icons.layers),
                  items: _listTipe.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                  onChanged: (val) => setState(() => _tipeHewan = val),
                ),
              ] else ...[
                _buildSectionTitle("Nama Barang / Alat"),
                TextFormField(
                  initialValue: _namaManual,
                  decoration: _inputDecoration(
                    icon: Icons.inventory_2, 
                    hint: _kategoriUtama == 'Operasional Habis Pakai' 
                          ? 'Cth: Pakan / Obat / Vitamin' 
                          : 'Cth: Kandang / Cangkul / Mesin'
                  ),
                  onSaved: (val) => _namaManual = val,
                ),
              ],
              const SizedBox(height: 20),
              
              // KONDISI
              _buildSectionTitle("Kondisi Saat Ini"),
              DropdownButtonFormField<String>(
                value: _kondisi,
                hint: Text("Pilih Kondisi"),
                decoration: _inputDecoration(icon: Icons.health_and_safety),
                items: currentKondisiList.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                onChanged: (val) => setState(() => _kondisi = val),
              ),
              const SizedBox(height: 20),

              // === BAGIAN BARU: KHUSUS OPERASIONAL HABIS PAKAI ===
              if (_kategoriUtama == 'Operasional Habis Pakai') ...[
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withOpacity(0.3))
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Detail Operasional", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                      const SizedBox(height: 15),
                      
                      // 1. EXPIRED DATE MANUAL (TEXT)
                      _buildSectionTitle("Tanggal Kadaluarsa (Expired)"),
                      TextFormField(
                        controller: _expiredDateController,
                        keyboardType: TextInputType.datetime,
                        decoration: _inputDecoration(
                          icon: Icons.event_busy, 
                          hint: "DD/MM/YYYY (Contoh: 31/12/2025)"
                        ),
                      ),
                      const SizedBox(height: 15),

                      // 2. ESTIMASI KEBUTUHAN
                      _buildSectionTitle("Estimasi Penggunaan"),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _usageTernakController,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration(hint: "Jml Ternak", suffix: "Ekor"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text("Selama", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _usageDaysController,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration(hint: "Durasi", suffix: "Hari"),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Text("*Contoh: Untuk 100 Ayam selama 30 Hari", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 25),
              ],
              // ==================================================

              // JUMLAH & SATUAN (Row)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Jumlah Stok"),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(icon: Icons.numbers),
                          validator: (val) => val!.isEmpty ? 'Wajib' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Satuan"),
                        DropdownButtonFormField<String>(
                          value: _satuanDipilih,
                          hint: const Text("Pilih"),
                          decoration: _inputDecoration(),
                          items: _listSatuan.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                          onChanged: (val) => setState(() => _satuanDipilih = val),
                          validator: (val) => val == null ? 'Wajib' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSectionTitle("Keterangan Tambahan"),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: polbanBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveAsset,
                  child: const Text('SIMPAN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({IconData? icon, String? suffix, String? hint}) {
    return InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[50],
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF1E549F)) : null,
      suffixText: suffix,
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
    );
  }
}