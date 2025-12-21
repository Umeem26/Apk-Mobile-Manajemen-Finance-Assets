class AssetModel {
  final int? id;
  final String nama;
  final String kategori;
  final String deskripsi;
  final int jumlah;
  final String imagePath;
  final String date; // Tanggal Input
  final String kondisi;
  
  // KOLOM BARU KHUSUS
  final String? satuan;       // Karung, Ton, dll
  final String? expiredDate;  // DD/MM/YYYY (Manual)
  final int? usageForTernak;  // Untuk berapa ekor
  final int? usageDuration;   // Untuk berapa hari

  AssetModel({
    this.id,
    required this.nama,
    required this.kategori,
    required this.jumlah,
    required this.deskripsi,
    required this.imagePath,
    required this.date,
    required this.kondisi,
    this.satuan,
    this.expiredDate,
    this.usageForTernak,
    this.usageDuration,
  });

  // Konversi ke Map (untuk Database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': nama,
      'category': kategori,
      'description': deskripsi,
      'quantity': jumlah,
      'imagePath': imagePath,
      'date': date,
      'condition': kondisi,
      'unit': satuan,
      'expired_date': expiredDate,
      'usage_ternak': usageForTernak,
      'usage_days': usageDuration,
    };
  }

  // Konversi dari Map (dari Database)
  factory AssetModel.fromMap(Map<String, dynamic> map) {
    return AssetModel(
      id: map['id'],
      nama: map['name'],
      kategori: map['category'],
      jumlah: map['quantity'],
      deskripsi: map['description'],
      imagePath: map['imagePath'],
      date: map['date'],
      kondisi: map['condition'],
      satuan: map['unit'],
      expiredDate: map['expired_date'],
      usageForTernak: map['usage_ternak'],
      usageDuration: map['usage_days'],
    );
  }
}