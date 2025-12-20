class AssetModel {
  final int? id;
  final String nama;
  final String kategori;
  final String deskripsi;
  final int jumlah;
  final String imagePath;
  final String date;
  final String kondisi; // KOLOM BARU

  AssetModel({
    this.id,
    required this.nama,
    required this.kategori,
    required this.deskripsi,
    required this.jumlah,
    required this.imagePath,
    required this.date,
    required this.kondisi, // Wajib diisi
  });

  factory AssetModel.fromMap(Map<String, dynamic> map) {
    return AssetModel(
      id: map['id'],
      nama: map['name'], // Mapping dari Database (name) ke Model (nama)
      kategori: map['category'],
      deskripsi: map['description'],
      jumlah: map['quantity'],
      imagePath: map['imagePath'],
      date: map['date'],
      kondisi: map['condition'] ?? 'Baik', // Default jika null
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': nama,
      'category': kategori,
      'description': deskripsi,
      'quantity': jumlah,
      'imagePath': imagePath,
      'date': date,
      'condition': kondisi, // Simpan ke DB
    };
  }
}