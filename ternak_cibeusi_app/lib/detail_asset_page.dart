import 'dart:io';
import 'package:flutter/material.dart';
import 'asset_model.dart';
import 'form_asset_page.dart';
import 'database/database_helper.dart';

class DetailAssetPage extends StatefulWidget {
  final AssetModel asset;

  const DetailAssetPage({Key? key, required this.asset}) : super(key: key);

  @override
  State<DetailAssetPage> createState() => _DetailAssetPageState();
}

class _DetailAssetPageState extends State<DetailAssetPage> {
  final Color polbanBlue = const Color(0xFF1E549F);
  final Color polbanOrange = const Color(0xFFFA9C1B);

  // Perlu refresh asset jika ada edit
  late AssetModel _currentAsset;

  @override
  void initState() {
    super.initState();
    _currentAsset = widget.asset;
  }

  void _navigateToEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FormAssetPage(asset: _currentAsset)),
    );
    _refreshData();
  }

  void _refreshData() async {
    // Ambil data terbaru dari DB berdasarkan ID
    final db = DatabaseHelper.instance;
    final allAssets = await db.readAllAssets();
    final updated = allAssets.firstWhere((element) => element.id == _currentAsset.id, orElse: () => _currentAsset);
    
    if (mounted) {
      setState(() {
        _currentAsset = updated;
      });
    }
  }

  void _deleteAsset() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Aset?"),
        content: const Text("Data ini akan hilang permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseHelper.instance.delete(_currentAsset.id!);
              if (!mounted) return;
              Navigator.pop(ctx); // Tutup Dialog
              Navigator.pop(context); // Kembali ke List
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasImage = _currentAsset.imagePath.isNotEmpty && File(_currentAsset.imagePath).existsSync();

    return Scaffold(
      backgroundColor: polbanBlue,
      appBar: AppBar(
        title: const Text('Rincian Aset', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _navigateToEdit,
            tooltip: "Edit Data",
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _deleteAsset,
            tooltip: "Hapus Data",
          ),
        ],
      ),
      body: Column(
        children: [
          // BAGIAN ATAS (GAMBAR/ICON)
          Expanded(
            flex: 3,
            child: Center(
              child: hasImage
                  ? Container(
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 3),
                        image: DecorationImage(
                          image: FileImage(File(_currentAsset.imagePath)),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))
                        ],
                      ),
                    )
                  : Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _getIconByCategory(_currentAsset.kategori),
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          
          // BAGIAN BAWAH (DETAIL INFO)
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // JUDUL & CHIPS
                    Text(
                      _currentAsset.nama,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: polbanBlue),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildChip(_currentAsset.kategori, polbanOrange),
                        const SizedBox(width: 8),
                        _buildChip(_currentAsset.kondisi, _getConditionColor(_currentAsset.kondisi)),
                      ],
                    ),
                    const Divider(height: 30, thickness: 1),

                    // GRID INFO UTAMA
                    _buildInfoRow(Icons.numbers, "Jumlah Stok", "${_currentAsset.jumlah} ${_currentAsset.satuan ?? 'Unit'}"),
                    const SizedBox(height: 15),
                    _buildInfoRow(Icons.health_and_safety, "Kondisi", _currentAsset.kondisi),
                    const SizedBox(height: 15),
                    _buildInfoRow(Icons.calendar_today, "Tanggal Input", _currentAsset.date),
                    
                    // --- INFO KHUSUS OPERASIONAL (Jika Ada) ---
                    if (_currentAsset.kategori == 'Operasional Habis Pakai') ...[
                      const Divider(height: 30),
                      const Text("Informasi Operasional", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 15),
                      
                      if (_currentAsset.expiredDate != null && _currentAsset.expiredDate!.isNotEmpty)
                        _buildInfoRow(Icons.event_busy, "Kadaluarsa (Expired)", _currentAsset.expiredDate!),
                      
                      const SizedBox(height: 15),
                      if ((_currentAsset.usageForTernak ?? 0) > 0)
                        _buildInfoRow(Icons.timelapse, "Estimasi Pemakaian", 
                            "Cukup untuk ${_currentAsset.usageForTernak} Ekor selama ${_currentAsset.usageDuration} Hari"),
                    ],
                    // ------------------------------------------

                    const Divider(height: 30),
                    const Text("Keterangan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        _currentAsset.deskripsi.isEmpty ? "Tidak ada keterangan tambahan." : _currentAsset.deskripsi,
                        style: TextStyle(color: Colors.grey[800], height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // HELPER WIDGETS
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
          child: Icon(icon, color: polbanBlue, size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[800])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  IconData _getIconByCategory(String category) {
    if (category == 'Ternak') return Icons.pets;
    if (category == 'Operasional Habis Pakai') return Icons.inventory;
    return Icons.domain;
  }

  Color _getConditionColor(String condition) {
    if (condition.toLowerCase().contains('sehat') || condition.toLowerCase().contains('baik')) return Colors.green;
    return Colors.red;
  }
}