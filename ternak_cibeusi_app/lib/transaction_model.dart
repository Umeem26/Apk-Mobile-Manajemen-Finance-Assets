class TransactionModel {
  final int? id;
  final String type; // 'IN' atau 'OUT'
  final double amount;
  final String category;
  final String description;
  final String date;

  TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
  });

  // Konversi ke Map (untuk simpan ke DB)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date,
    };
  }

  // Konversi dari Map (baca dari DB)
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      type: map['type'] ?? 'OUT', // Default jika null
      amount: (map['amount'] is int) ? (map['amount'] as int).toDouble() : map['amount'], // Handle int/double
      category: map['category'] ?? 'Umum',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
    );
  }
}