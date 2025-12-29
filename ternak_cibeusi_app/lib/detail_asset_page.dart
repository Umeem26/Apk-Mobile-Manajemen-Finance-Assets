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
    final db = DatabaseHelper.instance;
    final allAssets = await db.readAllAssets();
    try {
      final updated = allAssets.firstWhere((element) => element.id == _currentAsset.id);
      setState(() => _currentAsset = updated);
    } catch (e) {
      // Jika terhapus
      if(mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasImage = _currentAsset.imagePath.isNotEmpty && File(_currentAsset.imagePath).existsSync();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: polbanBlue,
            flexibleSpace: FlexibleSpaceBar(
              background: hasImage 
                ? Image.file(File(_currentAsset.imagePath), fit: BoxFit.cover)
                : Container(
                    color: polbanBlue.withOpacity(0.1),
                    child: Icon(Icons.image, size: 80, color: polbanBlue.withOpacity(0.3)),
                  ),
            ),
            actions: [
              IconButton(onPressed: _navigateToEdit, icon: const Icon(Icons.edit, color: Colors.white)),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildChip(_currentAsset.kategori, polbanBlue),
                        const SizedBox(width: 10),
                        _buildChip(_currentAsset.kondisi, _currentAsset.kondisi == 'Baik' ? Colors.green : Colors.red),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _currentAsset.nama,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Color(0xFF2D3436)),
                    ),
                    const SizedBox(height: 25),
                    
                    // DETAIL UTAMA
                    _buildInfoRow(Icons.production_quantity_limits, "Jumlah", "${_currentAsset.jumlah} ${_currentAsset.satuan ?? ''}"),
                    const SizedBox(height: 15),
                    _buildInfoRow(Icons.calendar_today, "Tanggal Input", _currentAsset.date),
                    
                    // DETAIL KHUSUS (Tampil jika ada datanya)
                    if (_currentAsset.statusKepemilikan != null) ...[
                      const SizedBox(height: 15),
                      _buildInfoRow(Icons.verified_user, "Status Kepemilikan", _currentAsset.statusKepemilikan!),
                    ],
                    if (_currentAsset.fungsiLahan != null) ...[
                      const SizedBox(height: 15),
                      _buildInfoRow(Icons.map, "Fungsi Lahan", _currentAsset.fungsiLahan!),
                    ],

                    const SizedBox(height: 25),
                    const Divider(),
                    const SizedBox(height: 15),
                    const Text("Deskripsi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      _currentAsset.deskripsi.isEmpty ? "-" : _currentAsset.deskripsi,
                      style: TextStyle(color: Colors.grey[600], height: 1.5),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ]),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
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
}