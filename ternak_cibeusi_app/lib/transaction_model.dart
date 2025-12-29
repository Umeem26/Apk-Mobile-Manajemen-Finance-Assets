class TransactionModel {
  final int? id;
  final String type; // 'IN' atau 'OUT'
  final double amount; // Total Nominal (Harga x Qty)
  final String category;
  final String description;
  final String date;

  // [BARU] Detail Harga
  final int? qty;
  final double? price; // Harga Satuan

  TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.qty,
    this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date,
      'qty': qty,       // Simpan Qty
      'price': price,   // Simpan Harga Satuan
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      type: map['type'] ?? 'OUT',
      // Pastikan amount double
      amount: (map['amount'] is int) ? (map['amount'] as int).toDouble() : map['amount'], 
      category: map['category'] ?? 'Umum',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      qty: map['qty'],
      price: (map['price'] is int) ? (map['price'] as int).toDouble() : map['price'],
    );
  }
}