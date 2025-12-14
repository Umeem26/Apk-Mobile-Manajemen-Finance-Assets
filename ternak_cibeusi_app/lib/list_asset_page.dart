import 'package:flutter/material.dart';
import 'asset_model.dart';
import 'form_asset_page.dart';
import 'detail_asset_page.dart';

class ListAssetPage extends StatefulWidget {
  final int initialTab;
  const ListAssetPage({super.key, this.initialTab = 0});

  @override
  State<ListAssetPage> createState() => _ListAssetPageState();
}

class _ListAssetPageState extends State<ListAssetPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Warna Khas Polban
  final Color colorKandang = const Color(0xFF1E549F); // Biru
  final Color colorOps = const Color(0xFFFA9C1B);     // Oranye
  final Color colorBio = const Color(0xFF757575);     // Abu

  List<AssetModel> allAssets = [
    AssetModel(id: '1', nama: 'Kandang Ayam A', kategori: 'Kandang', jenis: 'Bambu 5x5m', jumlah: 1, satuan: 'Unit', lokasi: 'Area 1', kondisi: 'Baik'),
    AssetModel(id: '2', nama: 'Mesin Bubur Sampah', kategori: 'Operasional', jenis: 'Diesel 10PK', jumlah: 1, satuan: 'Unit', lokasi: 'Gudang Maggot', kondisi: 'Perawatan/Service'),
    AssetModel(id: '3', nama: 'Ayam Petelur', kategori: 'Biologis', jenis: 'Isa Brown', jumlah: 100, satuan: 'Ekor', lokasi: 'Kandang A', kondisi: 'Baik'),
    AssetModel(id: '4', nama: 'Lele', kategori: 'Biologis', jenis: 'Sangkuriang', jumlah: 500, satuan: 'Ekor', lokasi: 'Kolam 2', kondisi: 'Baik'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  Color _getActiveColor() {
    if (_tabController.index == 0) return colorKandang;
    if (_tabController.index == 1) return colorOps;
    return colorBio;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Aset', style: TextStyle(color: Colors.white)),
        backgroundColor: _getActiveColor(),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          tabs: const [
            Tab(icon: Icon(Icons.house_siding), text: 'KANDANG'),
            Tab(icon: Icon(Icons.settings), text: 'OPERASIONAL'),
            Tab(icon: Icon(Icons.pets), text: 'BIOLOGIS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAssetList('Kandang', colorKandang),
          _buildAssetList('Operasional', colorOps),
          _buildAssetList('Biologis', colorBio),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _getActiveColor(),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          // PERUBAHAN DISINI: Kirim warna aktif ke FormAssetPage
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FormAssetPage(themeColor: _getActiveColor())),
          );
          if (result != null && result is AssetModel) {
            setState(() { allAssets.add(result); });
          }
        },
      ),
    );
  }

  Widget _buildAssetList(String kategoriFilter, Color temaWarna) {
    final filteredAssets = allAssets.where((asset) => asset.kategori == kategoriFilter).toList();

    if (filteredAssets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text('Belum ada data $kategoriFilter', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filteredAssets.length,
      itemBuilder: (context, index) {
        final item = filteredAssets[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DetailAssetPage(asset: item, temaWarna: temaWarna)),
              );
               if (result == 'hapus') {
                setState(() => allAssets.remove(item));
              } else if (result is AssetModel) {
                setState(() {
                  final idx = allAssets.indexWhere((element) => element.id == result.id);
                  if (idx != -1) allAssets[idx] = result;
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: temaWarna.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_getIcon(item.kategori), color: temaWarna),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('${item.jenis} • ${item.jumlah} ${item.satuan}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getWarnaStatus(item.kondisi).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.kondisi,
                      style: TextStyle(color: _getWarnaStatus(item.kondisi), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getWarnaStatus(String kondisi) {
    if (kondisi == 'Baik') return Colors.green;
    if (kondisi == 'Rusak/Sakit') return Colors.red;
    return Colors.orange;
  }

  IconData _getIcon(String kategori) {
    if (kategori == 'Biologis') return Icons.pets;
    if (kategori == 'Operasional') return Icons.settings;
    return Icons.house_siding;
  }
}