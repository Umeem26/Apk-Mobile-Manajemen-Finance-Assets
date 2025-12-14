// File: lib/asset_model.dart
class AssetModel {
  final String id; // Untuk unik ID (bisa pakai timestamp nanti)
  final String nama; // Misal: "Kandang A1", "Mesin Pencacah", "Lele Sangkuriang"
  final String kategori; // "Kandang", "Operasional", "Biologis"
  final String jenis; // Detail: "Ayam Petelur", "Mesin Diesel", "Beton"
  final int jumlah; // Total unit/ekor
  final String satuan; // "Ekor", "Unit", "Blok"
  final String lokasi; // "Area Belakang", "Gudang Pakan", "Kolam 1"
  final String kondisi; // "Sehat", "Rusak", "Perlu Service", "Baik"

  AssetModel({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.jenis,
    required this.jumlah,
    required this.satuan,
    required this.lokasi,
    required this.kondisi,
  });
}