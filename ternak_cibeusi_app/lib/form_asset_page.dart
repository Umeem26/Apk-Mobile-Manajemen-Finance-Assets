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
  
  late TextEditingController _quantityController;
  late TextEditingController _descController;
  
  // GANTI LOGISTIK JADI OPERASIONAL
  String _kategoriUtama = 'Aset Biologis';
  final List<String> _listKategoriUtama = ['Aset Biologis', 'Operasional', 'Infrastruktur'];

  String? _jenisHewan;
  final List<String> _listHewan = ['Ayam', 'Bebek', 'Lele'];
  String? _tipeHewan;
  final List<String> _listTipe = ['Petelur', 'Pedaging', 'Pejantan', 'Anakan/Bibit'];

  String? _kondisi;
  final List<String> _kondisiHewan = ['Sehat', 'Sakit', 'Karantina', 'Mati/Afkir'];
  final List<String> _kondisiBarang = ['Baik', 'Rusak Ringan', 'Rusak Berat', 'Kadaluarsa'];

  String? _namaManual;
  
  String _imagePath = '';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.asset?.jumlah.toString() ?? '');
    _descController = TextEditingController(text: widget.asset?.deskripsi ?? '');
    _kondisi = widget.asset?.kondisi;
    _imagePath = widget.asset?.imagePath ?? '';

    if (widget.asset != null) {
      if (_listKategoriUtama.contains(widget.asset!.kategori)) {
        _kategoriUtama = widget.asset!.kategori;
      }
      if (_kategoriUtama == 'Aset Biologis') {
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
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveAsset() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      String finalName = '';
      if (_kategoriUtama == 'Aset Biologis') {
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

      String finalKondisi = _kondisi ?? (_kategoriUtama == 'Aset Biologis' ? 'Sehat' : 'Baik');

      try {
        final newAsset = AssetModel(
          id: widget.asset?.id,
          nama: finalName,
          kategori: _kategoriUtama,
          jumlah: int.parse(_quantityController.text),
          deskripsi: _descController.text,
          imagePath: _imagePath,
          date: widget.asset?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
          kondisi: finalKondisi,
        );

        if (widget.asset == null) {
          await _dbHelper.create(newAsset);
        } else {
          await _dbHelper.update(newAsset);
        }
        if (!mounted) return;
        Navigator.pop(context); 

      } catch (e) {
        showDialog(context: context, builder: (ctx) => AlertDialog(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> currentKondisiList = _kategoriUtama == 'Aset Biologis' ? _kondisiHewan : _kondisiBarang;

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
                        ? DecorationImage(
                            image: FileImage(File(_imagePath)),
                            fit: BoxFit.cover,
                          )
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
                  });
                },
              ),
              const SizedBox(height: 20),

              if (_kategoriUtama == 'Aset Biologis') ...[
                _buildSectionTitle("Jenis Hewan"),
                DropdownButtonFormField<String>(
                  value: _jenisHewan,
                  hint: const Text("Pilih (Ayam / Bebek / Lele)"),
                  decoration: _inputDecoration(icon: Icons.grass),
                  items: _listHewan.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                  onChanged: (val) => setState(() => _jenisHewan = val),
                ),
                const SizedBox(height: 15),
                _buildSectionTitle("Tipe Produksi"),
                DropdownButtonFormField<String>(
                  value: _tipeHewan,
                  hint: const Text("Pilih (Petelur / Pedaging)"),
                  decoration: _inputDecoration(icon: Icons.layers),
                  items: _listTipe.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                  onChanged: (val) => setState(() => _tipeHewan = val),
                ),
              ] else ...[
                _buildSectionTitle("Nama Barang / Alat"),
                TextFormField(
                  initialValue: _namaManual,
                  // GANTI HINT TEXT UNTUK OPERASIONAL
                  decoration: _inputDecoration(
                    icon: Icons.inventory_2, 
                    hint: _kategoriUtama == 'Operasional' ? 'Cth: Pakan Konsentrat / Obat' : 'Cth: Cangkul / Sekop'
                  ),
                  onSaved: (val) => _namaManual = val,
                ),
              ],

              const SizedBox(height: 20),
              
              _buildSectionTitle("Kondisi Saat Ini"),
              DropdownButtonFormField<String>(
                value: _kondisi,
                hint: Text(_kategoriUtama == 'Aset Biologis' ? "Cth: Sehat / Sakit" : "Cth: Baik / Rusak"),
                decoration: _inputDecoration(icon: Icons.health_and_safety),
                items: currentKondisiList.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                onChanged: (val) => setState(() => _kondisi = val),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle("Jumlah Stok"),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(icon: Icons.numbers, suffix: "Unit/Ekor"),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),

              const SizedBox(height: 20),
              _buildSectionTitle("Keterangan"),
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
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: polbanBlue, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      prefixIcon: icon != null ? Icon(icon, color: polbanBlue) : null,
      suffixText: suffix,
      hintText: hint,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
    );
  }
}