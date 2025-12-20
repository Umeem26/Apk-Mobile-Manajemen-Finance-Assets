import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../asset_model.dart';
import '../transaction_model.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // GANTI NAMA DB AGAR DATA BARU YANG AKUNTANSI-READY MASUK
    _database = await _initDB('ternak_polban_accounting.db'); 
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Tabel Asset
    await db.execute('''
    CREATE TABLE assets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      description TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      imagePath TEXT NOT NULL,
      date TEXT NOT NULL,
      condition TEXT NOT NULL
    )
    ''');

    // 2. Tabel Transaksi
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT,
        amount REAL,
        category TEXT,
        description TEXT,
        date TEXT
      )
    ''');

    // --- DATA DUMMY ---
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String yesterday = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));

    // A. ASET (Tetap Aman)
    List<Map<String, dynamic>> assets = [
      {
        'name': 'Ayam - Petelur',
        'category': 'Aset Biologis',
        'description': 'Ayam produktif',
        'quantity': 150,
        'imagePath': '',
        'date': today,
        'condition': 'Sehat'
      },
      {
        'name': 'Pakan Konsentrat',
        'category': 'Operasional',
        'description': 'Stok gudang',
        'quantity': 25,
        'imagePath': '',
        'date': today,
        'condition': 'Baik'
      },
    ];

    for (var a in assets) {
      await db.insert('assets', a);
    }

    // B. KEUANGAN (AKUNTANSI READY)
    // Kita gunakan kategori yang baku agar bisa dipetakan ke Jurnal
    List<Map<String, dynamic>> transactions = [
      // 1. SETOR MODAL (Penting buat Neraca)
      {
        'type': 'IN',
        'amount': 10000000.0,
        'category': 'Modal Awal', 
        'description': 'Setoran modal pemilik',
        'date': '2025-01-01'
      },
      // 2. PENDAPATAN
      {
        'type': 'IN',
        'amount': 1500000.0,
        'category': 'Penjualan Hasil Ternak',
        'description': 'Jual Telur Minggu 1',
        'date': yesterday
      },
      // 3. BEBAN (PENGELUARAN)
      {
        'type': 'OUT',
        'amount': 500000.0,
        'category': 'Biaya Pakan',
        'description': 'Beli konsentrat',
        'date': today
      },
      {
        'type': 'OUT',
        'amount': 200000.0,
        'category': 'Biaya Listrik & Air',
        'description': 'Token listrik',
        'date': today
      },
      // 4. PRIVE (TARIK UANG)
      {
        'type': 'OUT',
        'amount': 100000.0,
        'category': 'Prive (Tarik Modal)',
        'description': 'Keperluan pribadi',
        'date': today
      },
    ];

    for (var t in transactions) {
      await db.insert('transactions', t);
    }
  }

  // --- CRUD METHODS (SAMA SEPERTI SEBELUMNYA) ---
  Future<int> create(AssetModel asset) async {
    final db = await instance.database;
    return await db.insert('assets', asset.toMap());
  }

  Future<List<AssetModel>> readAllAssets() async {
    final db = await instance.database;
    final result = await db.query('assets', orderBy: 'date DESC');
    return result.map((json) => AssetModel.fromMap(json)).toList();
  }

  Future<int> update(AssetModel asset) async {
    final db = await instance.database;
    return db.update('assets', asset.toMap(), where: 'id = ?', whereArgs: [asset.id]);
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete('assets', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'date DESC, id DESC');
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}