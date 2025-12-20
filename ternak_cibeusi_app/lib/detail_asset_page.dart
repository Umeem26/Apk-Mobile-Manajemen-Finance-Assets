import 'package:flutter/material.dart';
import 'asset_model.dart';
import 'database/database_helper.dart';
import 'form_asset_page.dart';
import 'dart:io';

class DetailAssetPage extends StatefulWidget {
  final AssetModel asset;
  const DetailAssetPage({Key? key, required this.asset}) : super(key: key);

  @override
  State<DetailAssetPage> createState() => _DetailAssetPageState();
}

class _DetailAssetPageState extends State<DetailAssetPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Color polbanBlue = const Color(0xFF1E549F);
  final Color polbanOrange = const Color(0xFFFA9C1B);

  void _deleteAsset() async {
    await _dbHelper.delete(widget.asset.id!);
    if (!mounted) return;
    Navigator.pop(context); 
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Anda yakin ingin menghapus "${widget.asset.nama}"?'),
        actions: [
          TextButton(child: const Text('Batal'), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAsset();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasImage = widget.asset.imagePath.isNotEmpty && File(widget.asset.imagePath).existsSync();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Rincian Aset', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: polbanBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FormAssetPage(asset: widget.asset)),
              ).then((_) => setState(() {})); 
            },
          ),
          IconButton(icon: const Icon(Icons.delete), onPressed: _confirmDelete),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: polbanBlue,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                image: hasImage
                    ? DecorationImage(
                        image: FileImage(File(widget.asset.imagePath)),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                      )
                    : null,
              ),
              child: !hasImage
                  ? Center(child: Icon(Icons.image, size: 100, color: Colors.white.withOpacity(0.3))) // GANTI PAW JADI IMAGE
                  : null,
            ),

            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.blueGrey.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.asset.nama, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: polbanBlue)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildBadge(widget.asset.kategori.toUpperCase(), polbanOrange),
                          const SizedBox(width: 8),
                          _buildBadge(widget.asset.kondisi.toUpperCase(), Colors.green), // BADGE KONDISI
                        ],
                      ),
                      const Divider(height: 30),

                      _buildDetailRow(Icons.numbers, "Jumlah Stok", "${widget.asset.jumlah} Unit"),
                      _buildDetailRow(Icons.health_and_safety, "Kondisi", widget.asset.kondisi), // TAMPIL KONDISI
                      _buildDetailRow(Icons.calendar_today, "Tanggal Input", widget.asset.date),
                      
                      const Divider(height: 30),
                      const Text("Keterangan", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(widget.asset.deskripsi.isEmpty ? "-" : widget.asset.deskripsi, style: const TextStyle(fontSize: 15, height: 1.5)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
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
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}