import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ternak_cibeusi.db');
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
    // 1. Tabel Master Akun (Chart of Accounts)
    await db.execute('''
    CREATE TABLE chart_of_accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      kode_akun TEXT UNIQUE,
      nama_akun TEXT,
      nama_lokal TEXT,
      kategori TEXT,
      posisi_normal TEXT
    )
    ''');

    // 2. Tabel Transaksi Header (Apa yang diinput user)
    await db.execute('''
    CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tanggal TEXT,
      keterangan TEXT,
      total_rupiah INTEGER,
      tipe TEXT, 
      foto_bukti TEXT
    )
    ''');

    // 3. Tabel Jurnal Detail (Debit/Kredit untuk hitungan Akuntansi)
    await db.execute('''
    CREATE TABLE journal_entries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      transaction_id INTEGER,
      account_id INTEGER,
      debit INTEGER DEFAULT 0,
      kredit INTEGER DEFAULT 0,
      FOREIGN KEY (transaction_id) REFERENCES transactions (id),
      FOREIGN KEY (account_id) REFERENCES chart_of_accounts (id)
    )
    ''');

    // 4. Tabel Aset (Inventory Barang)
    await db.execute('''
    CREATE TABLE assets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nama_aset TEXT,
      kategori TEXT,
      kondisi INTEGER, -- 1: Baik, 0: Rusak
      merk_tipe TEXT,
      material TEXT,
      keterangan TEXT,
      foto_path TEXT,
      tanggal_input TEXT
    )
    ''');

    // SEEDING DATA (Isi otomatis akun-akun saat pertama install)
    await _seedAccounts(db);
  }

  // Fungsi untuk mengisi Data Akun Awal (Hardcode sesuai Sheet)
  Future _seedAccounts(Database db) async {
    List<Map<String, dynamic>> accounts = [
      // ASET
      {'kode': '1-1001', 'nama': 'Kas', 'lokal': 'Uang Kertas (Tunai)', 'kat': 'ASET', 'pos': 'DEBIT'},
      {'kode': '1-1002', 'nama': 'Bank', 'lokal': 'Bank / Transfer', 'kat': 'ASET', 'pos': 'DEBIT'},
      {'kode': '1-1003', 'nama': 'Piutang', 'lokal': 'Uang Belum Dibayar', 'kat': 'ASET', 'pos': 'DEBIT'},
      {'kode': '1-1004', 'nama': 'Persediaan Pakan', 'lokal': 'Stok Pakan (Gudang)', 'kat': 'ASET', 'pos': 'DEBIT'},
      {'kode': '1-1005', 'nama': 'Persediaan Obat', 'lokal': 'Stok Obat/Vaksin', 'kat': 'ASET', 'pos': 'DEBIT'},
      {'kode': '1-1006', 'nama': 'Persediaan Ayam', 'lokal': 'Ayam di Kandang', 'kat': 'ASET', 'pos': 'DEBIT'},
      {'kode': '1-1007', 'nama': 'Perlengkapan', 'lokal': 'Alat Kecil (Ember/Sekop)', 'kat': 'ASET', 'pos': 'DEBIT'},
      {'kode': '1-2001', 'nama': 'Peralatan Kandang', 'lokal': 'Mesin/Kandang Utama', 'kat': 'ASET', 'pos': 'DEBIT'},
      
      // LIABILITAS (Hutang)
      {'kode': '2-1001', 'nama': 'Utang Usaha', 'lokal': 'Hutang ke Toko', 'kat': 'LIABILITAS', 'pos': 'KREDIT'},
      
      // EKUITAS (Modal)
      {'kode': '3-1001', 'nama': 'Modal Peternak', 'lokal': 'Modal Awal', 'kat': 'EKUITAS', 'pos': 'KREDIT'},
      {'kode': '3-1002', 'nama': 'Prive', 'lokal': 'Ambil Uang Pribadi', 'kat': 'EKUITAS', 'pos': 'DEBIT'},
      
      // PENDAPATAN
      {'kode': '4-1001', 'nama': 'Penjualan Ayam', 'lokal': 'Hasil Panen', 'kat': 'PENDAPATAN', 'pos': 'KREDIT'},
      {'kode': '4-1002', 'nama': 'Pendapatan Lain', 'lokal': 'Jual Karung/Kotoran', 'kat': 'PENDAPATAN', 'pos': 'KREDIT'},
      
      // BEBAN
      {'kode': '5-1001', 'nama': 'Biaya DOC', 'lokal': 'Beli Bibit Ayam', 'kat': 'BEBAN', 'pos': 'DEBIT'},
      {'kode': '5-1002', 'nama': 'Beban Pakan', 'lokal': 'Pakan Terpakai', 'kat': 'BEBAN', 'pos': 'DEBIT'},
      {'kode': '5-1003', 'nama': 'Beban Operasional', 'lokal': 'Listrik/Air/Gaji', 'kat': 'BEBAN', 'pos': 'DEBIT'},
      {'kode': '5-1004', 'nama': 'Beban Perawatan', 'lokal': 'Perbaikan Kandang', 'kat': 'BEBAN', 'pos': 'DEBIT'},
      {'kode': '5-1005', 'nama': 'Beban Lain-lain', 'lokal': 'Pengeluaran Lain', 'kat': 'BEBAN', 'pos': 'DEBIT'},
    ];

    Batch batch = db.batch();
    for (var acc in accounts) {
      batch.insert('chart_of_accounts', {
        'kode_akun': acc['kode'],
        'nama_akun': acc['nama'],
        'nama_lokal': acc['lokal'],
        'kategori': acc['kat'],
        'posisi_normal': acc['pos']
      });
    }
    await batch.commit();
  }
}