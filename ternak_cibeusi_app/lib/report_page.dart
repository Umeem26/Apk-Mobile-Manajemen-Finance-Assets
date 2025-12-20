import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database/database_helper.dart';
import 'asset_model.dart';
import 'transaction_model.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Color polbanBlue = const Color(0xFF1E549F);
  final Color polbanOrange = const Color(0xFFFA9C1B);

  // --- VARIABEL AKUNTANSI ---
  double _modalAwal = 0;
  double _totalPendapatan = 0;
  double _totalBeban = 0;
  double _totalPrive = 0;
  double _labaBersih = 0;
  double _modalAkhir = 0;
  double _kasDiTangan = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateAccounting();
  }

  // --- LOGIKA "SISTEM BERMAIN DI BELAKANG" ---
  void _calculateAccounting() async {
    final trans = await _dbHelper.getTransactions();

    double modal = 0;
    double pendapatan = 0;
    double beban = 0;
    double prive = 0;
    double kasMasuk = 0;
    double kasKeluar = 0;

    for (var t in trans) {
      // 1. HITUNG ARUS KAS (Untuk Neraca sisi Aset)
      if (t.type == 'IN') kasMasuk += t.amount;
      if (t.type == 'OUT') kasKeluar += t.amount;

      // 2. PEMETAAN JURNAL (MAPPING)
      // Sistem membaca kategori string dan memasukkannya ke pos akuntansi yg benar
      
      if (t.category == 'Modal Awal') {
        modal += t.amount;
      } 
      else if (t.category.contains('Penjualan') || t.category.contains('Pendapatan')) {
        pendapatan += t.amount;
      }
      else if (t.category.contains('Biaya')) {
        beban += t.amount;
      }
      else if (t.category.contains('Prive')) {
        prive += t.amount;
      }
      // Note: "Pembelian Aset Tetap" mengurangi Kas tapi tidak masuk Beban (masuk Aset di Neraca)
    }

    // RUMUS DASAR AKUNTANSI
    double laba = pendapatan - beban;
    double modAkhir = modal + laba - prive;
    double sisaKas = kasMasuk - kasKeluar;

    if (mounted) {
      setState(() {
        _modalAwal = modal;
        _totalPendapatan = pendapatan;
        _totalBeban = beban;
        _totalPrive = prive;
        _labaBersih = laba;
        _modalAkhir = modAkhir;
        _kasDiTangan = sisaKas;
        _isLoading = false;
      });
    }
  }

  String _fmt(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Laporan Keuangan', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: polbanBlue,
          foregroundColor: Colors.white,
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Color(0xFFFA9C1B),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: "LABA RUGI"),
              Tab(text: "PERUBAHAN MODAL"),
              Tab(text: "NERACA"),
            ],
          ),
        ),
        body: _isLoading 
            ? Center(child: CircularProgressIndicator(color: polbanBlue))
            : TabBarView(
                children: [
                  _buildLabaRugiTab(),
                  _buildPerubahanModalTab(),
                  _buildNeracaTab(),
                ],
              ),
      ),
    );
  }

  // TAB 1: LAPORAN LABA RUGI
  Widget _buildLabaRugiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildReportCard("Pendapatan Usaha", _totalPendapatan, Colors.green),
          const SizedBox(height: 10),
          const Icon(Icons.remove_circle_outline, color: Colors.grey),
          const SizedBox(height: 10),
          _buildReportCard("Beban Operasional", _totalBeban, Colors.redAccent),
          const Divider(height: 40, thickness: 2),
          _buildReportCard("LABA / RUGI BERSIH", _labaBersih, _labaBersih >= 0 ? polbanBlue : Colors.red, isTotal: true),
        ],
      ),
    );
  }

  // TAB 2: LAPORAN PERUBAHAN MODAL
  Widget _buildPerubahanModalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildReportCard("Modal Awal", _modalAwal, Colors.blueGrey),
          const SizedBox(height: 5),
          _buildRowItem("Ditambah: Laba Bersih", _labaBersih, Colors.green),
          const SizedBox(height: 5),
          _buildRowItem("Dikurangi: Prive (Tarik)", _totalPrive, Colors.red),
          const Divider(height: 40, thickness: 2),
          _buildReportCard("MODAL AKHIR", _modalAkhir, polbanOrange, isTotal: true),
        ],
      ),
    );
  }

  // TAB 3: NERACA (BALANCE SHEET)
  Widget _buildNeracaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("AKTIVA (ASET)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          _buildReportCard("Kas di Tangan", _kasDiTangan, polbanBlue),
          // Disini bisa ditambah nilai Inventory Aset jika mau, tapi kita fokus ke Kas dulu
          
          const SizedBox(height: 30),
          const Text("PASIVA (KEWAJIBAN & EKUITAS)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          _buildReportCard("Modal Pemilik", _modalAkhir, polbanBlue),
          
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 10),
                Expanded(child: Text("Neraca Seimbang (Balance) jika Kas = Modal Akhir (dalam sistem sederhana ini).")),
              ],
            ),
          )
        ],
      ),
    );
  }

  // WIDGET HELPER
  Widget _buildReportCard(String title, double value, Color color, {bool isTotal = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: isTotal ? Border.all(color: color, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: isTotal ? 18 : 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(_fmt(value), style: TextStyle(fontSize: isTotal ? 18 : 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildRowItem(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(_fmt(value), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}