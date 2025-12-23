import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
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
    _database = await _initDB('sikaya_platinum_v6.db'); // Versi Final Platinum
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE assets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      description TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      imagePath TEXT NOT NULL,
      date TEXT NOT NULL,
      condition TEXT NOT NULL,
      unit TEXT,
      expired_date TEXT,
      usage_ternak INTEGER,
      usage_days INTEGER
    )
    ''');

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
  }

  // --- CRUD ---
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'date DESC, id DESC');
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.update('transactions', transaction.toMap(), where: 'id = ?', whereArgs: [transaction.id]);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // --- LOGIKA LAPORAN DETAIL (UTK FORMAT BARU) ---
  
  // 1. SALDO KAS REAL
  Future<Map<String, double>> getSaldoCashflow() async {
    final all = await getTransactions();
    double pemasukan = 0;
    double pengeluaran = 0;

    for (var t in all) {
      if (t.category.contains("Kredit") || t.category.contains("Pemakaian") || t.category.contains("Biaya DOC")) {
        continue; 
      }
      if (t.type == 'IN') pemasukan += t.amount;
      else if (t.type == 'OUT') pengeluaran += t.amount;
    }
    return {'in': pemasukan, 'out': pengeluaran, 'total': pemasukan - pengeluaran};
  }

  // 2. LABA RUGI DETAIL
  Future<Map<String, double>> getLabaRugiDetail() async {
    final all = await getTransactions();
    double revTernak = 0, revLain = 0;
    double expDOC = 0, expPakan = 0, expObat = 0, expListrik = 0, expGaji = 0, expRawat = 0, expLain = 0;

    for (var t in all) {
      String cat = t.category;
      double val = t.amount;

      if (t.type == 'IN') {
        if (cat.contains("Jual")) revTernak += val;
        else if (cat.contains("Pendapatan")) revLain += val;
      } 
      else if (t.type == 'OUT') {
        if (cat.contains("Biaya DOC")) expDOC += val;
        else if (cat.contains("Biaya Pakan") || cat.contains("Pemakaian Pakan")) expPakan += val;
        else if (cat.contains("Biaya Obat") || cat.contains("Pemakaian Obat")) expObat += val;
        else if (cat.contains("Listrik")) expListrik += val;
        else if (cat.contains("Gaji") || cat.contains("Upah")) expGaji += val;
        else if (cat.contains("Perawatan") || cat.contains("Kandang")) expRawat += val; // Perbaikan kandang
        else if (cat.contains("Biaya Lain") || cat.contains("Sewa") || cat.contains("Pakai Perlengkapan")) expLain += val;
      }
    }
    
    double totalRev = revTernak + revLain;
    double totalExp = expDOC + expPakan + expObat + expListrik + expGaji + expRawat + expLain;

    return {
      'revTernak': revTernak, 'revLain': revLain, 'totalRev': totalRev,
      'expDOC': expDOC, 'expPakan': expPakan, 'expObat': expObat, 'expListrik': expListrik,
      'expGaji': expGaji, 'expRawat': expRawat, 'expLain': expLain, 'totalExp': totalExp,
      'labaBersih': totalRev - totalExp
    };
  }

  // 3. NERACA DETAIL
  Future<Map<String, double>> getNeracaDetail() async {
    final all = await getTransactions();
    
    double kas = (await getSaldoCashflow())['total']!;
    double bank = 0; // Kalau mau dipisah nanti bisa, skrg gabung kas dulu
    double piutang = 0;
    double sediaPakan = 0, sediaObat = 0, sediaTernak = 0;
    double perlengkapan = 0, peralatan = 0;
    double utang = 0, modalAwal = 0, prive = 0;

    for (var t in all) {
      String cat = t.category;
      double val = t.amount;

      // Piutang
      if (cat.contains("Jual") && cat.contains("Kredit")) piutang += val;
      if (cat.contains("Terima Pelunasan")) piutang -= val;

      // Persediaan
      if (cat.contains("Beli Pakan")) sediaPakan += val;
      if (cat.contains("Pemakaian Pakan")) sediaPakan -= val;

      if (cat.contains("Beli Obat")) sediaObat += val;
      if (cat.contains("Pemakaian Obat")) sediaObat -= val;

      if (cat.contains("Beli Ternak")) sediaTernak += val;
      // Opsional: Kurangi stok ternak jika ada logika HPP/Jual, sementara akumulasi nilai beli.

      // Aset Tetap
      if (cat.contains("Perlengkapan")) {
        if (cat.contains("Beli")) perlengkapan += val;
        if (cat.contains("Pakai")) perlengkapan -= val;
      }
      if (cat.contains("Peralatan") || cat.contains("Mesin")) {
        if (cat.contains("Beli")) peralatan += val;
      }

      // Utang & Modal
      if (cat.contains("Pinjaman") || (cat.contains("Beli") && cat.contains("Kredit"))) utang += val;
      if (cat.contains("Bayar Utang") || cat.contains("Bayar Pinjaman")) utang -= val;

      if (cat.contains("Setor Modal")) modalAwal += val;
      if (cat.contains("Prive")) prive += val;
    }

    double labaBersih = (await getLabaRugiDetail())['labaBersih']!;
    double modalAkhir = modalAwal + labaBersih - prive;

    return {
      'kas': kas, 'bank': bank, 'piutang': piutang,
      'sediaPakan': sediaPakan, 'sediaObat': sediaObat, 'sediaTernak': sediaTernak,
      'perlengkapan': perlengkapan, 'peralatan': peralatan,
      'utang': utang, 'modalAwal': modalAwal, 'prive': prive, 'modalAkhir': modalAkhir
    };
  }

  // --- REST (Tutup Buku & Helper Asset) ---
  Future<void> closeBookAndReset() async {
    final db = await instance.database;
    final neraca = await getNeracaDetail();
    double modalAkhir = neraca['modalAkhir']!;
    await db.delete('transactions');
    if (modalAkhir != 0) {
      final newModal = TransactionModel(
        type: 'IN', amount: modalAkhir, category: 'Setor Modal Pribadi', 
        description: 'Saldo Awal Periode Baru', date: DateFormat('yyyy-MM-dd').format(DateTime.now()));
      await db.insert('transactions', newModal.toMap());
    }
  }
  Future<void> nukeDatabase() async {
    final db = await instance.database;
    await db.delete('assets');
    await db.delete('transactions');
  }
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
  Future<int> getTotalTernak() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT SUM(quantity) as total FROM assets WHERE category LIKE '%Ternak%'");
    if (result.isNotEmpty && result.first['total'] != null) return (result.first['total'] as num).toInt();
    return 0;
  }
}