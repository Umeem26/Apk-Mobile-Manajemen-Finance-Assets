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

  // Warna Polban
  final Color polbanBlue = const Color(0xFF1E549F);
  final Color polbanOrange = const Color(0xFFFA9C1B);

  // Data Statistik
  int _totalAset = 0;
  int _asetBiologis = 0;
  int _asetLogistik = 0;
  int _asetInfra = 0;
  
  int _kondisiSehat = 0;
  int _kondisiSakit = 0;

  double _totalUangMasuk = 0;
  double _totalUangKeluar = 0;
  double _saldoBersih = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  void _loadStatistics() async {
    final assets = await _dbHelper.readAllAssets();
    final trans = await _dbHelper.getTransactions();

    int bio = 0, log = 0, infra = 0;
    int sehat = 0, sakit = 0;
    
    // Hitung Aset
    for (var a in assets) {
      if (a.kategori == 'Aset Biologis') bio += a.jumlah;
      if (a.kategori == 'Logistik') log += a.jumlah;
      if (a.kategori == 'Infrastruktur') infra += a.jumlah;

      // Cek Kondisi (Case insensitive)
      String k = a.kondisi.toLowerCase();
      if (k.contains('sehat') || k.contains('baik')) {
        sehat += a.jumlah;
      } else {
        sakit += a.jumlah; // Sakit, Rusak, Mati, dll
      }
    }

    // Hitung Keuangan
    double masuk = 0, keluar = 0;
    for (var t in trans) {
      if (t.type == 'IN') masuk += t.amount;
      else keluar += t.amount;
    }

    if (mounted) {
      setState(() {
        _totalAset = bio + log + infra;
        _asetBiologis = bio;
        _asetLogistik = log;
        _asetInfra = infra;
        _kondisiSehat = sehat;
        _kondisiSakit = sakit;

        _totalUangMasuk = masuk;
        _totalUangKeluar = keluar;
        _saldoBersih = masuk - keluar;
        
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Laporan & Statistik', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: polbanBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: polbanBlue))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- BAGIAN 1: RINGKASAN ASET ---
                _buildSectionTitle("Ringkasan Aset Ternak"),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildStatCard("Total Stok", "$_totalAset Unit", Icons.inventory_2, polbanBlue)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildStatCard("Hewan Ternak", "$_asetBiologis Ekor", Icons.pets, polbanOrange)),
                  ],
                ),
                const SizedBox(height: 15),
                
                // Grafik Batang Sederhana (Kondisi)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Kondisi Kesehatan / Kelayakan", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      _buildProgressBar("Sehat / Baik", _kondisiSehat, _totalAset, Colors.green),
                      const SizedBox(height: 15),
                      _buildProgressBar("Sakit / Rusak", _kondisiSakit, _totalAset, Colors.redAccent),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // --- BAGIAN 2: RINGKASAN KEUANGAN ---
                _buildSectionTitle("Ringkasan Keuangan"),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [polbanBlue, const Color(0xFF4376C4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: polbanBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0,5))],
                  ),
                  child: Column(
                    children: [
                      const Text("Saldo Bersih Saat Ini", style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 5),
                      Text(_formatCurrency(_saldoBersih), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      const Divider(color: Colors.white24, height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Total Pemasukan", style: TextStyle(color: Colors.white70, fontSize: 12)),
                              Text(_formatCurrency(_totalUangMasuk), style: const TextStyle(color: Colors.lightGreenAccent, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text("Total Pengeluaran", style: TextStyle(color: Colors.white70, fontSize: 12)),
                              Text(_formatCurrency(_totalUangKeluar), style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title, 
      style: TextStyle(
        fontSize: 18, 
        fontWeight: FontWeight.bold, 
        color: Colors.grey[800],
        letterSpacing: 0.5
      )
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 5, offset: const Offset(0,3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int value, int total, Color color) {
    double percent = total == 0 ? 0 : value / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text("$value Item", style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.grey[200],
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}