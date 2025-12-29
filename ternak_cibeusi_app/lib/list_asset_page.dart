import 'dart:io';
import 'package:flutter/material.dart';
import 'asset_model.dart';
import 'database/database_helper.dart';
import 'detail_asset_page.dart';
import 'form_asset_page.dart';

class ListAssetPage extends StatefulWidget {
  const ListAssetPage({Key? key}) : super(key: key);

  @override
  State<ListAssetPage> createState() => _ListAssetPageState();
}

class _ListAssetPageState extends State<ListAssetPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<AssetModel> _allAssets = [];
  bool _isLoading = true;

  final Color polbanBlue = const Color(0xFF1E549F);
  
  @override
  void initState() {
    super.initState();
    _refreshAssetList();
  }

  void _refreshAssetList() async {
    setState(() => _isLoading = true);
    try {
      final data = await _dbHelper.readAllAssets();
      if (mounted) setState(() { _allAssets = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<AssetModel> _getAssetsByCategory(String categoryName) => _allAssets.where((asset) => asset.kategori == categoryName).toList();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA), 
        appBar: AppBar(
          title: const Text('Manajemen Aset', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: polbanBlue,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white, // GANTI JADI PUTIH/BIRU MUDA
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [Tab(text: "TERNAK"), Tab(text: "OPS.HABIS PAKAI"), Tab(text: "ASET TETAP")],
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: polbanBlue))
            : TabBarView(
                children: [
                  _buildAssetList(_getAssetsByCategory('Ternak'), Icons.pets, polbanBlue),
                  _buildAssetList(_getAssetsByCategory('Operasional Habis Pakai'), Icons.inventory, Colors.teal),
                  _buildAssetList(_getAssetsByCategory('Aset Tetap'), Icons.domain, Colors.indigo),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: polbanBlue, // GANTI JADI BIRU
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Tambah Aset", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => const FormAssetPage()));
            _refreshAssetList();
          },
        ),
      ),
    );
  }

  Widget _buildAssetList(List<AssetModel> assets, IconData defaultIcon, Color themeColor) {
    if (assets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 15),
            Text("Belum ada data aset", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        final bool hasImage = asset.imagePath.isNotEmpty && File(asset.imagePath).existsSync();

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => DetailAssetPage(asset: asset)));
                _refreshAssetList();
              },
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  children: [
                    Container(
                      width: 65, height: 65,
                      decoration: BoxDecoration(
                        color: hasImage ? Colors.transparent : themeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        image: hasImage ? DecorationImage(image: FileImage(File(asset.imagePath)), fit: BoxFit.cover) : null,
                      ),
                      child: !hasImage ? Icon(defaultIcon, color: themeColor, size: 30) : null,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(asset.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3436))),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _badge("${asset.jumlah} ${asset.satuan ?? 'Unit'}", themeColor),
                              const SizedBox(width: 8),
                              _badge(asset.kondisi, asset.kondisi == 'Baik' ? Colors.green : Colors.redAccent),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey[300]),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}