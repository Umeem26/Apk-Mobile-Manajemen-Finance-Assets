import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database/database_helper.dart';
import 'asset_model.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import ini

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Color polbanBlue = const Color(0xFF1E549F);
  final Color polbanOrange = const Color(0xFFFA9C1B);

  bool _showFinance = true;
  bool _isLoading = true;
  String _ownerName = "Nama Peternak"; // Variabel Nama

  Map<String, double> _lr = {};
  Map<String, double> _nr = {};
  List<AssetModel> _operationalAssets = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    
    // 1. Ambil Nama
    final prefs = await SharedPreferences.getInstance();
    String name = prefs.getString('owner_name') ?? "Nama Peternak";

    // 2. Ambil Data
    final lr = await _dbHelper.getLabaRugiDetail();
    final nr = await _dbHelper.getNeracaDetail();
    final assets = await _dbHelper.readAllAssets();
    
    if (mounted) {
      setState(() {
        _ownerName = name;
        _lr = lr;
        _nr = nr;
        _operationalAssets = assets.where((a) => a.kategori == 'Operasional Habis Pakai').toList();
        _isLoading = false;
      });
    }
  }

  String _fmt(double? val) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(val ?? 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Pusat Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: polbanBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: polbanBlue))
        : Column(
            children: [
              Container(
                color: polbanBlue,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(50)),
                  child: Row(children: [_buildToggle("Laporan Keuangan", true), _buildToggle("Laporan Asset Tetap", false)]),
                ),
              ),
              Expanded(child: _showFinance ? _buildFinanceSection() : _buildAssetSection()),
            ],
          ),
    );
  }

  // ... (Widget _buildToggle & _buildFinanceSection SAMA SEPERTI SEBELUMNYA) ...
  // Agar kode tidak terlalu panjang, copy paste dari jawaban sebelumnya utk bagian ini.
  // Tapi GANTI bagian pemanggilan _excelHeader dan _pdfHeaderBox agar memakai _ownerName.
  
  // CONTOH UPDATE DI BAWAH INI (Timpa bagian Widget terkait):

  Widget _buildToggle(String text, bool isFinance) {
    bool active = _showFinance == isFinance;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _showFinance = isFinance),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(50)),
          child: Center(child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: active ? polbanBlue : Colors.white70))),
        ),
      ),
    );
  }

  Widget _buildFinanceSection() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: polbanBlue, unselectedLabelColor: Colors.grey, indicatorColor: polbanOrange, labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [Tab(text: "LABA RUGI"), Tab(text: "MODAL"), Tab(text: "NERACA")],
            ),
          ),
          Expanded(child: TabBarView(children: [_tabLabaRugi(), _tabModal(), _tabNeraca()]))
        ],
      ),
    );
  }

  Widget _tabLabaRugi() {
    return _excelScaffold(
      onPrint: _printLabaRugiPDF,
      title: "Laporan Laba Rugi",
      content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _excelHeader(_ownerName, "Laporan Laba Rugi"), // [UPDATE] Pakai _ownerName
        const SizedBox(height: 20),
        _boldText("A. Pendapatan"), _excelRow("Penjualan Ternak", _lr['revTernak']), _excelRow("Pendapatan Lain", _lr['revLain'], showUnderline: true), _excelTotalRow("Total Pendapatan", _lr['totalRev']),
        const SizedBox(height: 20),
        _boldText("B. Biaya Produksi"), _excelRow("Biaya DOC", _lr['expDOC']), _excelRow("Biaya Pakan", _lr['expPakan']), _excelRow("Biaya Obat", _lr['expObat']), _excelRow("Listrik & Air", _lr['expListrik']), _excelRow("Tenaga Kerja", _lr['expGaji']), _excelRow("Perawatan", _lr['expRawat']), _excelRow("Lain-lain", _lr['expLain'], showUnderline: true), _excelTotalRow("Total Biaya", _lr['totalExp']),
        const SizedBox(height: 30), _excelGrandTotal("LABA/RUGI", _lr['labaBersih']), const SizedBox(height: 80),
      ]),
    );
  }

  Widget _tabModal() {
    return _excelScaffold(
      onPrint: _printModalPDF,
      title: "Laporan Perubahan Modal",
      content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _excelHeader(_ownerName, "Laporan Perubahan Modal"), // [UPDATE]
        const SizedBox(height: 20),
        _boldText("A. Modal Awal"), _excelRow("Modal Awal Siklus", _nr['modalAwal']), _excelTotalRow("Total Modal Awal", _nr['modalAwal']),
        const SizedBox(height: 20),
        _boldText("B. Perubahan"), _excelRow("Laba/Rugi", _lr['labaBersih']), _excelRow("(-Ambil Prive)", _nr['prive'], showUnderline: true), _excelTotalRow("Total Penambahan", _lr['labaBersih']! - _nr['prive']!),
        const SizedBox(height: 30), _excelGrandTotal("MODAL AKHIR", _nr['modalAkhir']), const SizedBox(height: 80),
      ]),
    );
  }

  Widget _tabNeraca() {
    double totalAset = _nr['kas']! + _nr['bank']! + _nr['piutang']! + _nr['sediaPakan']! + _nr['sediaObat']! + _nr['sediaTernak']! + _nr['perlengkapan']! + _nr['peralatan']!;
    double totalPasiva = _nr['utang']! + _nr['modalAkhir']!;
    return _excelScaffold(
      onPrint: () => _printNeracaPDF(totalAset, totalPasiva),
      title: "Laporan Neraca",
      content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _excelHeader(_ownerName, "Laporan Neraca"), // [UPDATE]
        const SizedBox(height: 20),
        _boldText("ASET"), _neracaRow("1-1001", "Kas", _nr['kas']), _neracaRow("1-1003", "Piutang", _nr['piutang']), _neracaRow("1-1004", "Persediaan Pakan", _nr['sediaPakan']), _neracaRow("1-1007", "Persediaan Obat", _nr['sediaObat']), _neracaRow("1-1008", "Persediaan Ternak", _nr['sediaTernak']), _neracaRow("1-1009", "Perlengkapan", _nr['perlengkapan']), _neracaRow("1-2001", "Peralatan", _nr['peralatan']), const Divider(thickness: 2), _excelGrandTotal("TOTAL ASET", totalAset),
        const SizedBox(height: 30),
        _boldText("HUTANG & EKUITAS"), _neracaRow("2-1001", "Utang Usaha", _nr['utang']), _neracaRow("3-1001", "Modal Akhir", _nr['modalAkhir']), const Divider(thickness: 2), _excelGrandTotal("TOTAL PASIVA", totalPasiva), const SizedBox(height: 80),
      ]),
    );
  }

  // --- WIDGET HELPER ---
  Widget _excelScaffold({required String title, required Widget content, required VoidCallback onPrint}) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(onPressed: onPrint, label: const Text("Export PDF"), icon: const Icon(Icons.picture_as_pdf), backgroundColor: Colors.redAccent),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Container(padding: const EdgeInsets.all(25), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]), child: content)),
    );
  }

  Widget _excelHeader(String t1, String t2) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: Colors.black)),
      child: Column(children: [Text(t1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(t2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text("Periode: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
    );
  }
  
  // (Helper _boldText, _excelRow, _neracaRow, _excelTotalRow, _excelGrandTotal, _buildAssetSection SAMA)
  // Biar hemat tempat, silakan gunakan yang sudah ada di kode sebelumnya. 
  // Bagian ini tidak berubah logicnya, hanya dipanggil ulang.
  // ... Paste Helper Widgets di sini ...
  Widget _boldText(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)));
  Widget _excelRow(String label, double? val, {bool showUnderline = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Container(decoration: showUnderline ? const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black))) : null, child: Text(_fmt(val)))]));
  Widget _neracaRow(String code, String label, double? val) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [SizedBox(width: 60, child: Text(code, style: const TextStyle(fontSize: 12, color: Colors.grey))), Expanded(child: Text(label)), Text(_fmt(val))]));
  Widget _excelTotalRow(String label, double? val) => Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.bold)), Text(_fmt(val), style: const TextStyle(fontWeight: FontWeight.bold))]));
  Widget _excelGrandTotal(String label, double? val) => Container(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10), decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.black, width: 2), bottom: BorderSide(color: Colors.black, width: 2))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(_fmt(val), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]));
  Widget _buildAssetSection() {return Scaffold(body: _operationalAssets.isEmpty ? const Center(child: Text("Belum ada data", style: TextStyle(color: Colors.grey))) : ListView.builder(padding: const EdgeInsets.all(20), itemCount: _operationalAssets.length, itemBuilder: (context, index) { final item = _operationalAssets[index]; return Card(child: ListTile(leading: const Icon(Icons.inventory, color: Colors.orange), title: Text(item.nama, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("${item.jumlah} ${item.satuan}"))); },));}


  // --- PDF GENERATOR (Update Header) ---
  pw.Widget _pdfHeaderBox(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Column(children: [
        pw.Text(_ownerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)), // [UPDATE]
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.Text("Periode: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}", style: pw.TextStyle(fontSize: 12)),
      ]),
    );
  }

  // ... (Sisa fungsi PDF sama: _printLabaRugiPDF, _printModalPDF, _printNeracaPDF) ...
  // Pastikan panggil _pdfHeaderBox di dalamnya.
  Future<void> _printLabaRugiPDF() async { final pdf = pw.Document(); pdf.addPage(pw.Page(build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [_pdfHeaderBox("Laporan Laba Rugi"), pw.SizedBox(height: 20), _pdfBold("A. Pendapatan"), _pdfRow("Penjualan Ternak", _lr['revTernak']), _pdfRow("Pendapatan Lain", _lr['revLain'], underline: true), _pdfTotalRow("Total Pendapatan", _lr['totalRev']), pw.SizedBox(height: 15), _pdfBold("B. Biaya Produksi"), _pdfRow("Biaya DOC", _lr['expDOC']), _pdfRow("Biaya Pakan", _lr['expPakan']), _pdfRow("Biaya Obat", _lr['expObat']), _pdfRow("Listrik & Air", _lr['expListrik']), _pdfRow("Tenaga Kerja", _lr['expGaji']), _pdfRow("Perawatan", _lr['expRawat']), _pdfRow("Lain-lain", _lr['expLain'], underline: true), _pdfTotalRow("Total Biaya", _lr['totalExp']), pw.SizedBox(height: 20), _pdfGrandTotal("LABA/RUGI", _lr['labaBersih'])]))); await Printing.layoutPdf(onLayout: (format) async => pdf.save()); }
  Future<void> _printModalPDF() async { final pdf = pw.Document(); pdf.addPage(pw.Page(build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [_pdfHeaderBox("Laporan Perubahan Modal"), pw.SizedBox(height: 20), _pdfBold("A. Modal Awal"), _pdfRow("Modal Awal Siklus", _nr['modalAwal']), _pdfTotalRow("Total Modal Awal", _nr['modalAwal']), pw.SizedBox(height: 15), _pdfBold("B. Perubahan"), _pdfRow("Laba/Rugi", _lr['labaBersih']), _pdfRow("(-Prive)", _nr['prive'], underline: true), _pdfTotalRow("Total Penambahan", _lr['labaBersih']! - _nr['prive']!), pw.SizedBox(height: 20), _pdfGrandTotal("MODAL AKHIR", _nr['modalAkhir'])]))); await Printing.layoutPdf(onLayout: (format) async => pdf.save()); }
  Future<void> _printNeracaPDF(double totAset, double totPasiva) async { final pdf = pw.Document(); pdf.addPage(pw.Page(build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [_pdfHeaderBox("Laporan Posisi Keuangan"), pw.SizedBox(height: 20), _pdfBold("ASET"), _pdfRowCode("1-1001", "Kas", _nr['kas']), _pdfRowCode("1-1003", "Piutang", _nr['piutang']), _pdfRowCode("1-1004", "Persediaan Pakan", _nr['sediaPakan']), _pdfRowCode("1-1007", "Persediaan Obat", _nr['sediaObat']), _pdfRowCode("1-1008", "Persediaan Ternak", _nr['sediaTernak']), _pdfRowCode("1-1009", "Perlengkapan", _nr['perlengkapan']), _pdfRowCode("1-2001", "Peralatan", _nr['peralatan']), pw.Divider(), _pdfGrandTotal("TOTAL ASET", totAset), pw.SizedBox(height: 20), _pdfBold("HUTANG & EKUITAS"), _pdfRowCode("2-1001", "Utang Usaha", _nr['utang']), _pdfRowCode("3-1001", "Modal Akhir", _nr['modalAkhir']), pw.Divider(), _pdfGrandTotal("TOTAL PASIVA", totPasiva)]))); await Printing.layoutPdf(onLayout: (format) async => pdf.save()); }

  // PDF Widgets Helper
  pw.Widget _pdfBold(String t) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 5), child: pw.Text(t, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
  pw.Widget _pdfRow(String l, double? v, {bool underline = false}) { return pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 20), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(l), pw.Container(decoration: underline ? const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide())) : null, child: pw.Text(_fmt(v)))])); }
  pw.Widget _pdfRowCode(String c, String l, double? v) { return pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: pw.Row(children: [pw.SizedBox(width: 50, child: pw.Text(c, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey))), pw.Expanded(child: pw.Text(l)), pw.Text(_fmt(v))])); }
  pw.Widget _pdfTotalRow(String l, double? v) => pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 20), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(l, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text(_fmt(v), style: pw.TextStyle(fontWeight: pw.FontWeight.bold))]));
  pw.Widget _pdfGrandTotal(String l, double? v) => pw.Container(padding: const pw.EdgeInsets.symmetric(vertical: 5), decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 1), bottom: pw.BorderSide(width: 1))), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(l, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)), pw.Text(_fmt(v), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14))]));
}