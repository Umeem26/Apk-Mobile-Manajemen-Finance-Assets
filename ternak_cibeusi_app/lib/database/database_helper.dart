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
    // GANTI KE V4 AGAR KOLOM KONDISI TERBENTUK OTOMATIS
    _database = await _initDB('ternak_polban_v4.db'); 
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
    // 1. Tabel Asset (Tambah kolom condition)
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

    // 3. ISI DATA DUMMY (Updated dengan Kondisi)
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    await db.insert('assets', {
      'name': 'Ayam - Petelur',
      'category': 'Aset Biologis',
      'description': 'Ayam sehat siap produksi telur grade A',
      'quantity': 50,
      'imagePath': '',
      'date': today,
      'condition': 'Sehat'
    });

    await db.insert('assets', {
      'name': 'Lele - Anakan/Bibit',
      'category': 'Aset Biologis',
      'description': 'Bibit lele sangkuriang kolam 2',
      'quantity': 1000,
      'imagePath': '',
      'date': today,
      'condition': 'Sehat'
    });

    await db.insert('assets', {
      'name': 'Pakan Konsentrat 511',
      'category': 'Logistik',
      'description': 'Stok gudang utama',
      'quantity': 20,
      'imagePath': '',
      'date': today,
      'condition': 'Baik'
    });

    await db.insert('assets', {
      'name': 'Cangkul',
      'category': 'Infrastruktur',
      'description': 'Alat kebersihan kandang',
      'quantity': 5,
      'imagePath': '',
      'date': today,
      'condition': 'Rusak Ringan'
    });
  }

  // --- CRUD OPERATONS ---
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