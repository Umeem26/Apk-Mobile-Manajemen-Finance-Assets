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
  late TextEditingController _expiredDateController;
  late TextEditingController _usageTernakController;
  late TextEditingController _usageDaysController;

  String? _namaAset;
  final TextEditingController _customNameController = TextEditingController();

  String _kategoriUtama = 'Ternak';
  final List<String> _listKategoriUtama = ['Ternak', 'Operasional Habis Pakai', 'Aset Tetap'];

  String? _jenisHewan;
  final List<String> _listHewan = ['Ayam Broiler', 'Ayam Petelur', 'Ayam Kampung', 'Bebek', 'Puyuh', 'Domba'];

  String? _jenisBarang;
  final List<String> _listBarang = ['Pakan Starter', 'Pakan Finisher', 'Vitamin', 'Vaksin', 'Desinfektan', 'Sekam'];

  String? _jenisAsetTetap;
  final List<String> _listAsetTetap = ['Kandang', 'Gudang Pakan', 'Mesin Giling', 'Tempat Minum Otomatis', 'Pemanas (Gasolec)', 'Lahan'];

  String _satuan = 'Ekor';
  final List<String> _listSatuan = ['Ekor', 'Karung', 'Kg', 'Liter', 'Botol', 'Pcs', 'Unit', 'Set', 'Paket', 'm2', 'ha', 'tumbak'];

  String _kondisi = 'Baik';
  final List<String> _listKondisi = ['Baik', 'Rusak Ringan', 'Rusak Berat', 'Perlu Perbaikan'];

  String? _statusKepemilikan;
  final List<String> _listKepemilikan = ['Hak Milik', 'Sewa', 'Hak Milik dan Sewa'];
  
  List<String> _selectedFungsiLahan = [];
  final List<String> _listFungsiLahan = ['Peternakan', 'Pertanian', 'Perkebunan'];

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.asset != null) {
      _kategoriUtama = widget.asset!.kategori;
      _namaAset = widget.asset!.nama; 
      
      if (!_listHewan.contains(_namaAset) && !_listBarang.contains(_namaAset) && !_listAsetTetap.contains(_namaAset)) {
        _customNameController.text = _namaAset!;
        _namaAset = 'Lainnya'; 
      } else {
        if (_kategoriUtama == 'Ternak') _jenisHewan = _namaAset;
        if (_kategoriUtama == 'Operasional Habis Pakai') _jenisBarang = _namaAset;
        if (_kategoriUtama == 'Aset Tetap') _jenisAsetTetap = _namaAset;
      }

      _quantityController = TextEditingController(text: widget.asset!.jumlah.toString());
      _descController = TextEditingController(text: widget.asset!.deskripsi);
      _imageFile = widget.asset!.imagePath.isNotEmpty ? File(widget.asset!.imagePath) : null;
      _kondisi = widget.asset!.kondisi;
      _satuan = widget.asset!.satuan ?? 'Ekor';
      _expiredDateController = TextEditingController(text: widget.asset!.expiredDate ?? '');
      _usageTernakController = TextEditingController(text: widget.asset!.usageForTernak?.toString() ?? '');
      _usageDaysController = TextEditingController(text: widget.asset!.usageDuration?.toString() ?? '');
      
      _statusKepemilikan = widget.asset!.statusKepemilikan;
      if (widget.asset!.fungsiLahan != null && widget.asset!.fungsiLahan!.isNotEmpty) {
        _selectedFungsiLahan = widget.asset!.fungsiLahan!.split(', ');
      }

    } else {
      _quantityController = TextEditingController();
      _descController = TextEditingController();
      _expiredDateController = TextEditingController();
      _usageTernakController = TextEditingController();
      _usageDaysController = TextEditingController();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source, imageQuality: 50);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _showMultiSelectDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text("Pilih Fungsi Lahan"),
              content: SingleChildScrollView(
                child: ListBody(
                  children: _listFungsiLahan.map((item) {
                    return CheckboxListTile(
                      value: _selectedFungsiLahan.contains(item),
                      title: Text(item),
                      activeColor: polbanBlue,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? checked) {
                        setStateDialog(() {
                          if (checked == true) _selectedFungsiLahan.add(item);
                          else _selectedFungsiLahan.remove(item);
                        });
                        setState(() {}); 
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Selesai"))],
            );
          },
        );
      },
    );
  }

  void _saveAsset() async {
    if (_formKey.currentState!.validate()) {
      String finalName = '';
      if (_kategoriUtama == 'Ternak') finalName = _jenisHewan ?? 'Hewan Lain';
      else if (_kategoriUtama == 'Operasional Habis Pakai') finalName = _jenisBarang ?? 'Barang Lain';
      else if (_kategoriUtama == 'Aset Tetap') finalName = _jenisAsetTetap ?? 'Aset Lain';

      if (finalName == 'Lainnya' || finalName == 'Hewan Lain' || finalName == 'Barang Lain' || finalName == 'Aset Lain') {
        if (_customNameController.text.isNotEmpty) finalName = _customNameController.text;
      }

      String? fungsiLahanString;
      if (_selectedFungsiLahan.isNotEmpty) fungsiLahanString = _selectedFungsiLahan.join(', ');

      final asset = AssetModel(
        id: widget.asset?.id,
        nama: finalName,
        kategori: _kategoriUtama,
        jumlah: int.parse(_quantityController.text),
        deskripsi: _descController.text,
        imagePath: _imageFile?.path ?? '',
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        kondisi: _kondisi,
        satuan: _satuan,
        expiredDate: _expiredDateController.text,
        usageForTernak: int.tryParse(_usageTernakController.text),
        usageDuration: int.tryParse(_usageDaysController.text),
        statusKepemilikan: (_kategoriUtama == 'Aset Tetap') ? _statusKepemilikan : null,
        fungsiLahan: (_kategoriUtama == 'Aset Tetap') ? fungsiLahanString : null,
      );

      if (widget.asset == null) await _dbHelper.create(asset);
      else await _dbHelper.update(asset);
      
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.asset == null ? "Tambah Aset" : "Edit Aset", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: polbanBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Foto Aset"),
              GestureDetector(
                onTap: () => _pickImage(ImageSource.gallery),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                    image: _imageFile != null ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover) : null,
                  ),
                  child: _imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded, size: 40, color: polbanBlue.withOpacity(0.5)),
                            const SizedBox(height: 8),
                            Text("Ketuk untuk ambil foto", style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 30),

              _buildSectionTitle("Informasi Dasar"),
              DropdownButtonFormField<String>(
                value: _kategoriUtama,
                items: _listKategoriUtama.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) {
                  setState(() {
                    _kategoriUtama = val!;
                    _jenisHewan = null; _jenisBarang = null; _jenisAsetTetap = null;
                    if(_kategoriUtama == 'Aset Tetap') _satuan = 'Unit';
                    else if(_kategoriUtama == 'Ternak') _satuan = 'Ekor';
                    else _satuan = 'Karung';
                  });
                },
                decoration: _inputDecoration(icon: Icons.category, hint: "Pilih Kategori"),
              ),
              const SizedBox(height: 15),

              if (_kategoriUtama == 'Ternak')
                DropdownButtonFormField<String>(
                  value: _jenisHewan,
                  items: [..._listHewan, 'Lainnya'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _jenisHewan = val),
                  decoration: _inputDecoration(icon: Icons.pets, hint: "Jenis Hewan"),
                ),
              if (_kategoriUtama == 'Operasional Habis Pakai')
                DropdownButtonFormField<String>(
                  value: _jenisBarang,
                  items: [..._listBarang, 'Lainnya'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _jenisBarang = val),
                  decoration: _inputDecoration(icon: Icons.inventory_2, hint: "Jenis Barang"),
                ),
              if (_kategoriUtama == 'Aset Tetap')
                DropdownButtonFormField<String>(
                  value: _jenisAsetTetap,
                  items: [..._listAsetTetap, 'Lainnya'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _jenisAsetTetap = val),
                  decoration: _inputDecoration(icon: Icons.domain, hint: "Jenis Aset"),
                ),
              
              if (_jenisHewan == 'Lainnya' || _jenisBarang == 'Lainnya' || _jenisAsetTetap == 'Lainnya')
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: TextFormField(
                    controller: _customNameController,
                    decoration: _inputDecoration(hint: "Masukkan Nama Aset Manual"),
                  ),
                ),
              
              const SizedBox(height: 30),
              _buildSectionTitle("Detail & Jumlah"),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(hint: "Jumlah"),
                      validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _satuan,
                      items: _listSatuan.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setState(() => _satuan = val!),
                      decoration: _inputDecoration(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _kondisi,
                items: _listKondisi.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _kondisi = val!),
                decoration: _inputDecoration(icon: Icons.info_outline, hint: "Kondisi Aset"),
              ),

              if (_kategoriUtama == 'Aset Tetap') ...[
                const SizedBox(height: 30),
                _buildSectionTitle("Detail Aset Tetap"),
                DropdownButtonFormField<String>(
                  value: _statusKepemilikan,
                  items: _listKepemilikan.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _statusKepemilikan = val),
                  decoration: _inputDecoration(icon: Icons.verified_user, hint: "Status Kepemilikan"),
                ),
                const SizedBox(height: 15),
                InkWell(
                  onTap: _showMultiSelectDialog,
                  child: InputDecorator(
                    decoration: _inputDecoration(icon: Icons.map, hint: "Fungsi Lahan"),
                    child: Text(
                      _selectedFungsiLahan.isEmpty ? "Pilih Fungsi Lahan (Bisa > 1)" : _selectedFungsiLahan.join(", "),
                      style: TextStyle(color: _selectedFungsiLahan.isEmpty ? Colors.grey[600] : Colors.black87),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 30),
              _buildSectionTitle("Catatan"),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: _inputDecoration(hint: "Keterangan tambahan..."),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: polbanBlue,
                    elevation: 5,
                    shadowColor: polbanBlue.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _saveAsset,
                  child: const Text('SIMPAN DATA', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({IconData? icon, String? suffix, String? hint}) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF5F7FA), // Warna fill soft
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.transparent)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF1E549F), width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.redAccent)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.redAccent)),
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF1E549F), size: 22) : null,
      suffixText: suffix,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, left: 5),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey[800])),
    );
  }
}