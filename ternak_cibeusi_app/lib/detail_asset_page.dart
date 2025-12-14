import 'package:flutter/material.dart';
import 'asset_model.dart';
import 'form_asset_page.dart';

class DetailAssetPage extends StatefulWidget {
  final AssetModel asset;
  final Color temaWarna; 

  const DetailAssetPage({
    super.key, 
    required this.asset,
    this.temaWarna = Colors.blue, 
  });

  @override
  State<DetailAssetPage> createState() => _DetailAssetPageState();
}

class _DetailAssetPageState extends State<DetailAssetPage> {
  late AssetModel dataAsset;
  bool _isEdited = false;

  @override
  void initState() {
    super.initState();
    dataAsset = widget.asset;
  }

  void _onBack() {
    Navigator.pop(context, _isEdited ? dataAsset : null);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) { if (!didPop) _onBack(); },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: widget.temaWarna,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _onBack,
          ),
          title: const Text('Detail Aset', style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () => _konfirmasiHapus(context),
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header Besar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 40, top: 20),
                decoration: BoxDecoration(
                  color: widget.temaWarna,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_getIcon(dataAsset.kategori), size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 15),
                    Text(dataAsset.nama, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        dataAsset.kategori.toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.bold, color: widget.temaWarna, fontSize: 12),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Grid Informasi Style Polban
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildPolbanInfoRow("Jenis / Spesifikasi", dataAsset.jenis, Icons.description),
                    _buildPolbanInfoRow("Jumlah Total", "${dataAsset.jumlah} ${dataAsset.satuan}", Icons.analytics),
                    _buildPolbanInfoRow("Lokasi Penyimpanan", dataAsset.lokasi, Icons.place),
                    _buildPolbanInfoRow("Kondisi Terkini", dataAsset.kondisi, Icons.verified_user),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              
              // Tombol Edit
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        // PERUBAHAN DISINI: Kirim temaWarna ke form edit
                        MaterialPageRoute(builder: (context) => FormAssetPage(assetEdit: dataAsset, themeColor: widget.temaWarna)),
                      );
                      if (result != null && result is AssetModel) {
                        setState(() { dataAsset = result; _isEdited = true; });
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil diperbarui')));
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('EDIT DATA'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.temaWarna,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolbanInfoRow(String label, String value, IconData icon) {
    // (Kode sama seperti sebelumnya)
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade500, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _konfirmasiHapus(BuildContext context) {
    // (Kode sama seperti sebelumnya)
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data'),
        content: Text('Hapus ${dataAsset.nama}?'),
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
  }

  IconData _getIcon(String kategori) {
    if (kategori == 'Biologis') return Icons.pets;
    if (kategori == 'Operasional') return Icons.settings;
    return Icons.house_siding;
  }
}