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
    // GANTI NAMA DB BIAR FRESH
    _database = await _initDB('ternak_cibeusi_equity_test_v1.db'); 
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
      condition TEXT NOT NULL,
      unit TEXT,
      expired_date TEXT,
      usage_ternak INTEGER,
      usage_days INTEGER
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

    // SEED DATA SAAT PERTAMA INSTALL
    await _seedDummyData(db);
  }

  // --- DATA DUMMY LENGKAP UNTUK CEK RUMUS MODAL ---
  Future<void> _seedDummyData(Database db) async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String lastMonth = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 30)));

    // A. DATA ASET
    List<Map<String, dynamic>> assets = [
      {
        'name': 'Kambing Etawa',
        'category': 'Ternak',
        'description': 'Kambing perah indukan',
        'quantity': 20,
        'imagePath': '',
        'date': lastMonth,
        'condition': 'Sehat',
        'unit': 'Ekor',
        'expired_date': null,
        'usage_ternak': 0,
        'usage_days': 0
      },
      {
        'name': 'Pakan Konsentrat',
        'category': 'Operasional Habis Pakai',
        'description': 'Stok pakan gudang',
        'quantity': 50,
        'imagePath': '',
        'date': today,
        'condition': 'Baik',
        'unit': 'Sak',
        'expired_date': '31/12/2025',
        'usage_ternak': 20,
        'usage_days': 30
      },
    ];

    for (var a in assets) {
      await db.insert('assets', a);
    }

    // B. TRANSAKSI (Skenario Laba Rugi)
    List<Map<String, dynamic>> transactions = [
      // 1. MODAL AWAL (250 Juta)
      {
        'type': 'IN',
        'amount': 250000000.0,
        'category': 'Setor Modal', 
        'description': 'Modal Awal Usaha',
        'date': '2024-01-01'
      },
      
      // 2. BELI ASET (Harta Bertambah, Kas Berkurang -> TAPI MODAL TETAP)
      {
        'type': 'OUT',
        'amount': 60000000.0,
        'category': 'Beli Ayam Tunai',
        'description': 'Beli 20 Ekor Kambing',
        'date': '2024-01-05'
      },
      {
        'type': 'OUT',
        'amount': 15000000.0,
        'category': 'Beli Perlengkapan Kandang',
        'description': 'Bangun Kandang',
        'date': '2024-01-10'
      },

      // 3. PENDAPATAN (Menambah Laba -> Menambah Modal)
      {
        'type': 'IN',
        'amount': 48000000.0,
        'category': 'Jual Ayam Tunai',
        'description': 'Total Penjualan Susu & Anakan',
        'date': '2024-06-01'
      },
      // Jual Kredit (Piutang) juga dihitung Pendapatan dalam Akrual/Ekuitas
      {
        'type': 'IN',
        'amount': 10000000.0,
        'category': 'Jual Ayam Kredit', 
        'description': 'Piutang Penjualan ke Koperasi',
        'date': '2024-06-05'
      },

      // 4. BEBAN (Mengurangi Laba -> Mengurangi Modal)
      {
        'type': 'OUT',
        'amount': 4000000.0,
        'category': 'Bayar Gaji',
        'description': 'Gaji ABK',
        'date': '2024-06-25'
      },
      {
        'type': 'OUT',
        'amount': 500000.0,
        'category': 'Bayar Listrik dan Air',
        'description': 'Listrik Farm',
        'date': '2024-06-26'
      },

      // 5. PRIVE (Mengurangi Modal Langsung)
      {
        'type': 'OUT',
        'amount': 2000000.0,
        'category': 'Prive (Tarik Modal)',
        'description': 'Keperluan Pribadi',
        'date': '2024-06-30'
      },
    ];

    for (var t in transactions) {
      await db.insert('transactions', t);
    }
  }

  // --- CRUD METHODS ---
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

  // --- LOGIKA TUTUP BUKU (METODE EKUITAS/MODAL) ---
  // Rumus: Modal Baru = Modal Awal + Laba Bersih - Prive
  Future<void> closeBookAndReset() async {
    final db = await instance.database;
    final allTrans = await getTransactions();

    double modalAwal = 0;
    double prive = 0;
    double pendapatan = 0;
    double beban = 0;

    for (var t in allTrans) {
      double val = t.amount;

      if (t.category == 'Setor Modal') {
        modalAwal += val;
      } else if (t.category == 'Prive (Tarik Modal)') {
        prive += val;
      } else if (t.category == 'Jual Ayam Tunai' || 
                 t.category == 'Jual Ayam Kredit' || 
                 t.category == 'Pendapatan Lain-lain') {
        pendapatan += val;
      } else if (t.category == 'Bayar Listrik dan Air' || 
                 t.category == 'Bayar Gaji' || 
                 t.category == 'Bayar Perawatan Kandang' || 
                 t.category == 'Biaya Lain-lain') {
        beban += val;
      }
    }

    // HITUNG MODAL AKHIR
    // Contoh Data Dummy di atas:
    // Modal Awal: 250.000.000
    // Pendapatan: 48.000.000 (Tunai) + 10.000.000 (Kredit) = 58.000.000
    // Beban: 4.000.000 + 500.000 = 4.500.000
    // Prive: 2.000.000
    //
    // Laba Bersih = 58.000.000 - 4.500.000 = 53.500.000
    // Modal Akhir = 250.000.000 + 53.500.000 - 2.000.000 = 301.500.000
    
    double labaBersih = pendapatan - beban;
    double modalAkhir = modalAwal + labaBersih - prive;

    // Hapus Data & Masukkan Saldo Baru
    await db.delete('transactions');

    if (modalAkhir != 0) {
      final newModal = TransactionModel(
        type: 'IN',
        amount: modalAkhir,
        category: 'Setor Modal',
        description: 'Saldo Modal Akhir periode lalu (Metode Ekuitas)',
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );
      await db.insert('transactions', newModal.toMap());
    }
  }

  // --- LOGIKA RESET TOTAL (HAPUS & ISI ULANG) ---
  Future<void> nukeDatabase() async {
    final db = await instance.database;
    await db.delete('assets');
    await db.delete('transactions');
    await _seedDummyData(db); // Panggil fungsi isi data
  }
}