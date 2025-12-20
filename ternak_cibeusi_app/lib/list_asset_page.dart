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
  final Color polbanOrange = const Color(0xFFFA9C1B);

  @override
  void initState() {
    super.initState();
    _refreshAssetList();
  }

  void _refreshAssetList() async {
    setState(() => _isLoading = true);
    try {
      final data = await _dbHelper.readAllAssets();
      if (mounted) {
        setState(() {
          _allAssets = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<AssetModel> _getAssetsByCategory(String categoryName) {
    return _allAssets.where((asset) => asset.kategori == categoryName).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('Manajemen Aset', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: polbanBlue,
          centerTitle: true,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            indicatorColor: polbanOrange,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: "BIOLOGIS", icon: Icon(Icons.grass)),
              Tab(text: "OPERASIONAL", icon: Icon(Icons.layers)), // GANTI NAMA TAB
              Tab(text: "INFRASTRUKTUR", icon: Icon(Icons.build_circle)),
            ],
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: polbanBlue))
            : TabBarView(
                children: [
                  _buildAssetList(_getAssetsByCategory('Aset Biologis'), 'Hewan Ternak Kosong', Icons.grass, polbanBlue),
                  // FILTER BERDASARKAN "OPERASIONAL"
                  _buildAssetList(_getAssetsByCategory('Operasional'), 'Data Operasional Kosong', Icons.layers, Colors.green),
                  _buildAssetList(_getAssetsByCategory('Infrastruktur'), 'Alat & Kandang Kosong', Icons.build_circle, polbanOrange),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: polbanBlue,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Tambah Aset", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FormAssetPage()),
            );
            _refreshAssetList();
          },
        ),
      ),
    );
  }

  Widget _buildAssetList(List<AssetModel> assets, String emptyMsg, IconData defaultIcon, Color themeColor) {
    if (assets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.folder_open, size: 70, color: themeColor.withOpacity(0.5)),
            ),
            const SizedBox(height: 20),
            Text(emptyMsg, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        final bool hasImage = asset.imagePath.isNotEmpty && File(asset.imagePath).existsSync();

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.blueGrey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: hasImage ? Colors.transparent : themeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                image: hasImage
                    ? DecorationImage(
                        image: FileImage(File(asset.imagePath)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !hasImage
                  ? Icon(defaultIcon, color: themeColor, size: 30)
                  : null,
            ),
            title: Text(
              asset.nama,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: polbanBlue),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: polbanOrange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${asset.jumlah} Unit",
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text("•  ${asset.kondisi}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey[300]),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DetailAssetPage(asset: asset)),
              );
              _refreshAssetList();
            },
          ),
        );
      },
    );
  }
}