import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database/database_helper.dart';
import 'asset_model.dart';
import 'transaction_model.dart';

// Import Paket PDF
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

  // --- STATE TAMPILAN ---
  bool _showFinance = true; 

  // --- DATA KEUANGAN ---
  double _pendapatanJualAyam = 0;
  double _pendapatanLain = 0;
  double _biayaDOC = 0;
  double _biayaPakan = 0;
  double _biayaObat = 0;
  double _biayaListrik = 0;
  double _biayaTenagaKerja = 0;
  double _biayaPerawatan = 0;
  double _biayaLain = 0;
  double _modalAwalSiklus = 0;
  double _prive = 0;
  double _kas = 0;
  double _bank = 0;
  double _piutang = 0;
  double _persediaanPakanPre = 0;
  double _persediaanPakanStar = 0;
  double _persediaanPakanFin = 0;
  double _persediaanObat = 0;
  double _persediaanAyam = 0;
  double _perlengkapanKandang = 0;
  double _peralatanKandang = 0;
  double _utangUsaha = 0;

  // --- DATA OPERASIONAL (Fixed: Mengambil data Operasional Habis Pakai) ---
  List<AssetModel> _operationalAssets = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateAllData();
  }

  void _calculateAllData() async {
    final trans = await _dbHelper.getTransactions();
    final assets = await _dbHelper.readAllAssets();

    // 1. FILTER DATA (PERBAIKAN LOGIKA DISINI)
    // Kita ambil kategori 'Operasional Habis Pakai' sesuai request data yang sudah diinput
    List<AssetModel> opsAssets = assets.where((a) => a.kategori == 'Operasional Habis Pakai').toList();

    // 2. HITUNG KEUANGAN
    double revAyam = 0, revLain = 0;
    double expDOC = 0, expPakan = 0, expObat = 0, expListrik = 0, expGaji = 0, expRawat = 0, expLain = 0;
    double modAwal = 0, tarikPrive = 0;
    double kas = 0, bank = 0, piutang = 0, utang = 0;
    double sPakanPre = 0, sPakanStar = 0, sPakanFin = 0, sObat = 0, sAyam = 0, sPerleng = 0, sPeralatan = 0;

    for (var t in trans) {
      double val = t.amount;
      switch (t.category) {
        case 'Setor Modal': kas += val; modAwal += val; break;
        case 'Prive (Tarik Modal)': kas -= val; tarikPrive += val; break;
        case 'Jual Ayam Tunai': kas += val; revAyam += val; break;
        case 'Jual Ayam Kredit': piutang += val; revAyam += val; break;
        case 'Pendapatan Lain-lain': kas += val; revLain += val; break;
        case 'Terima Pelunasan Piutang': kas += val; piutang -= val; break;
        case 'Beli Ayam Tunai': sAyam += val; kas -= val; break;
        case 'Beli Ayam Kredit': sAyam += val; utang += val; break;
        case 'Beli Pakan Tunai Pre Starter': sPakanPre += val; kas -= val; break;
        case 'Beli Pakan Tunai Starter': sPakanStar += val; kas -= val; break;
        case 'Beli Pakan Tunai Finisher': sPakanFin += val; kas -= val; break;
        case 'Beli Obat & Vitamin': sObat += val; kas -= val; break;
        case 'Beli Perlengkapan Kandang': sPerleng += val; kas -= val; break;
        case 'Bayar Listrik dan Air': expListrik += val; kas -= val; break;
        case 'Bayar Gaji': expGaji += val; kas -= val; break;
        case 'Bayar Perawatan Kandang': expRawat += val; kas -= val; break;
        case 'Biaya Lain-lain': expLain += val; kas -= val; break;
        case 'Bayar Utang': utang -= val; kas -= val; break;
      }
    }

    if (mounted) {
      setState(() {
        _operationalAssets = opsAssets;
        
        _pendapatanJualAyam = revAyam; _pendapatanLain = revLain;
        _biayaDOC = expDOC; _biayaPakan = expPakan; _biayaObat = expObat;
        _biayaListrik = expListrik; _biayaTenagaKerja = expGaji; _biayaPerawatan = expRawat; _biayaLain = expLain;
        _modalAwalSiklus = modAwal; _prive = tarikPrive;
        _kas = kas; _bank = bank; _piutang = piutang;
        _persediaanPakanPre = sPakanPre; _persediaanPakanStar = sPakanStar; _persediaanPakanFin = sPakanFin;
        _persediaanObat = sObat; _persediaanAyam = sAyam;
        _perlengkapanKandang = sPerleng; _peralatanKandang = sPeralatan;
        _utangUsaha = utang;

        _isLoading = false;
      });
    }
  }

  String _fmt(double amount) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
              // --- TOGGLE SWITCH ---
              Container(
                color: polbanBlue,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(50)),
                  child: Row(
                    children: [
                      _buildToggleButton("Laporan Keuangan", true),
                      // JUDUL BUTTON DISESUAIKAN DENGAN ISI
                      _buildToggleButton("Laporan Asset Tetap", false),
                    ],
                  ),
                ),
              ),

              // --- KONTEN UTAMA ---
              Expanded(
                child: _showFinance 
                    ? _buildFinanceSection() 
                    : _buildAssetSection(),
              ),
            ],
          ),
    );
  }

  Widget _buildToggleButton(String text, bool isFinance) {
    bool isActive = _showFinance == isFinance;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _showFinance = isFinance),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? polbanBlue : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BAGIAN 1: LAPORAN KEUANGAN (Tetap Aman)
  // ===========================================================================
  Widget _buildFinanceSection() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: polbanBlue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: polbanOrange,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "LABA RUGI"),
                Tab(text: "MODAL"),
                Tab(text: "NERACA"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildLabaRugiTab(),
                _buildModalTab(),
                _buildNeracaTab(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLabaRugiTab() {
    double totalPendapatan = _pendapatanJualAyam + _pendapatanLain;
    double totalBiaya = _biayaDOC + _biayaPakan + _biayaObat + _biayaListrik + _biayaTenagaKerja + _biayaPerawatan + _biayaLain;
    double labaRugi = totalPendapatan - totalBiaya;
    return _reportScaffold(
      onPrint: () => _printLabaRugi(totalPendapatan, totalBiaya, labaRugi),
      content: [
        _header("Laporan Laba Rugi"), const SizedBox(height: 20),
        _subHeader("A. Pendapatan"), _row("Penjualan Ayam", _pendapatanJualAyam), _row("Pendapatan Lain", _pendapatanLain), const Divider(), _rowBold("Total Pendapatan", totalPendapatan),
        const SizedBox(height: 20), _subHeader("B. Biaya Produksi"), _row("Biaya DOC", _biayaDOC), _row("Biaya Pakan", _biayaPakan), _row("Biaya Obat", _biayaObat), _row("Biaya Listrik", _biayaListrik), _row("Biaya Gaji", _biayaTenagaKerja), _row("Biaya Perawatan", _biayaPerawatan), _row("Biaya Lain", _biayaLain), const Divider(), _rowBold("Total Biaya", totalBiaya),
        const SizedBox(height: 30), _highlightBox("LABA/RUGI", labaRugi),
      ]
    );
  }

  Widget _buildModalTab() {
    double labaRugi = (_pendapatanJualAyam + _pendapatanLain) - (_biayaDOC + _biayaPakan + _biayaObat + _biayaListrik + _biayaTenagaKerja + _biayaPerawatan + _biayaLain);
    double penambahan = labaRugi - _prive;
    double modalAkhir = _modalAwalSiklus + penambahan;
    return _reportScaffold(
      onPrint: () => _printModal(labaRugi, penambahan, modalAkhir),
      content: [
        _header("Laporan Perubahan Modal"), const SizedBox(height: 20),
        _subHeader("A. Modal Awal"), _row("Modal Awal Siklus", _modalAwalSiklus),
        const SizedBox(height: 20), _subHeader("B. Perubahan"), _row("Laba/Rugi", labaRugi), _row("Prive", _prive), const Divider(), _rowBold("Total Penambahan", penambahan),
        const SizedBox(height: 30), _highlightBox("MODAL AKHIR", modalAkhir),
      ]
    );
  }

  Widget _buildNeracaTab() {
    double totalAset = _kas + _bank + _piutang + _persediaanPakanPre + _persediaanPakanStar + _persediaanPakanFin + _persediaanObat + _persediaanAyam + _perlengkapanKandang + _peralatanKandang;
    double labaRugi = (_pendapatanJualAyam + _pendapatanLain) - (_biayaDOC + _biayaPakan + _biayaObat + _biayaListrik + _biayaTenagaKerja + _biayaPerawatan + _biayaLain);
    double modalAkhir = _modalAwalSiklus + labaRugi - _prive;
    double totalPasiva = _utangUsaha + modalAkhir;
    return _reportScaffold(
      onPrint: () => _printNeraca(totalAset, modalAkhir, totalPasiva),
      content: [
        _header("Laporan Posisi Keuangan (Neraca)"), const SizedBox(height: 20),
        _subHeader("ASET"), _row("Kas", _kas), _row("Bank", _bank), _row("Piutang", _piutang), _row("Persediaan Pakan Pre", _persediaanPakanPre), _row("Persediaan Pakan Star", _persediaanPakanStar), _row("Persediaan Pakan Fin", _persediaanPakanFin), _row("Persediaan Obat", _persediaanObat), _row("Persediaan Ayam", _persediaanAyam), _row("Perlengkapan", _perlengkapanKandang), const Divider(), _rowBold("TOTAL ASET", totalAset),
        const SizedBox(height: 30), _subHeader("HUTANG & EKUITAS"), _row("Utang Usaha", _utangUsaha), _row("Modal Akhir", modalAkhir), const Divider(), _rowBold("TOTAL HUTANG & EKUITAS", totalPasiva),
      ]
    );
  }

  // ===========================================================================
  // BAGIAN 2: LAPORAN ASET (DATA OPERASIONAL)
  // ===========================================================================
  Widget _buildAssetSection() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _printAssetReport, 
        label: const Text("Export PDF"),
        icon: const Icon(Icons.picture_as_pdf),
        backgroundColor: Colors.redAccent,
      ),
      body: _operationalAssets.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text("Belum ada data Operasional Habis Pakai", style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _operationalAssets.length,
            itemBuilder: (context, index) {
              final item = _operationalAssets[index];
              bool hasImage = item.imagePath.isNotEmpty && File(item.imagePath).existsSync();

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: _boxDecor(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // GAMBAR ALAT
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), bottomLeft: Radius.circular(5)),
                        image: hasImage ? DecorationImage(image: FileImage(File(item.imagePath)), fit: BoxFit.cover) : null,
                      ),
                      child: !hasImage ? const Icon(Icons.image_not_supported, color: Colors.grey) : null,
                    ),
                    // DETAIL
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.nama, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: polbanBlue)),
                            const SizedBox(height: 5),
                            // Tampilkan Satuan
                            Text("Stok: ${item.jumlah} ${item.satuan}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 8),
                            Text(item.deskripsi.isEmpty ? "-" : item.deskripsi, style: TextStyle(fontSize: 12, color: Colors.grey[700]), maxLines: 3, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
    );
  }

  // ===========================================================================
  // PDF GENERATOR (JUDUL BARU)
  // ===========================================================================
  Future<void> _printAssetReport() async {
    final pdf = pw.Document();
    final List<List<dynamic>> tableData = [];
    
    // Header Tabel
    tableData.add(['Nama Barang', 'Gambar', 'Fungsi / Deskripsi']);

    for (var item in _operationalAssets) {
      pw.Widget imageWidget = pw.Container(width: 50, height: 50, color: PdfColors.grey200);
      
      if (item.imagePath.isNotEmpty && File(item.imagePath).existsSync()) {
        final imageBytes = File(item.imagePath).readAsBytesSync();
        imageWidget = pw.Image(pw.MemoryImage(imageBytes), width: 80, height: 60, fit: pw.BoxFit.cover);
      }

      tableData.add([
        item.nama + "\n(${item.jumlah} ${item.satuan})", 
        imageWidget, 
        item.deskripsi.isEmpty ? "-" : item.deskripsi 
      ]);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // JUDUL PDF SUDAH DISESUAIKAN
              pw.Text("LAPORAN OPERASIONAL HABIS PAKAI", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
              pw.SizedBox(height: 10),
              pw.Text("Periode: ${DateFormat('MMMM yyyy').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(4),
                },
                children: tableData.map((row) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: row[0] is String ? pw.Text(row[0]) : row[0]),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: row[1] is pw.Widget ? row[1] : pw.Text(row[1])),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: row[2] is String ? pw.Text(row[2]) : row[2]),
                    ],
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // --- HELPER PDF KEUANGAN (Tetap Sama) ---
  Future<void> _printLabaRugi(double totPend, double totBiaya, double laba) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (ctx) => pw.Column(children: [
      _pdfHeader("Laporan Laba Rugi"), pw.SizedBox(height: 20),
      _pdfSub("A. Pendapatan"), _pdfRow("Penjualan Ayam", _pendapatanJualAyam), _pdfRow("Lain-lain", _pendapatanLain), pw.Divider(), _pdfRowBold("Total Pendapatan", totPend),
      pw.SizedBox(height: 15), _pdfSub("B. Biaya Produksi"), _pdfRow("Biaya DOC", _biayaDOC), _pdfRow("Pakan", _biayaPakan), _pdfRow("Obat", _biayaObat), _pdfRow("Listrik", _biayaListrik), _pdfRow("Gaji", _biayaTenagaKerja), pw.Divider(), _pdfRowBold("Total Biaya", totBiaya),
      pw.SizedBox(height: 20), _pdfRowBold("LABA/RUGI", laba),
    ])));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _printModal(double laba, double tambah, double akhir) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (ctx) => pw.Column(children: [
      _pdfHeader("Laporan Perubahan Modal"), pw.SizedBox(height: 20),
      _pdfSub("A. Modal Awal"), _pdfRow("Modal Awal", _modalAwalSiklus), pw.Divider(),
      _pdfSub("B. Perubahan"), _pdfRow("Laba/Rugi", laba), _pdfRow("Prive", _prive), pw.Divider(), _pdfRowBold("Total Perubahan", tambah),
      pw.SizedBox(height: 20), _pdfRowBold("MODAL AKHIR", akhir),
    ])));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _printNeraca(double totAset, double modAkhir, double totPasiva) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (ctx) => pw.Column(children: [
      _pdfHeader("Neraca Keuangan"), pw.SizedBox(height: 20),
      _pdfSub("ASET"), _pdfRow("Kas", _kas), _pdfRow("Persediaan Pakan Star", _persediaanPakanStar), _pdfRow("Persediaan Ayam", _persediaanAyam), pw.Divider(), _pdfRowBold("TOTAL ASET", totAset),
      pw.SizedBox(height: 20), _pdfSub("HUTANG & EKUITAS"), _pdfRow("Utang", _utangUsaha), _pdfRow("Modal Akhir", modAkhir), pw.Divider(), _pdfRowBold("TOTAL HUTANG & EKUITAS", totPasiva),
    ])));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // --- WIDGET HELPER UI ---
  Widget _reportScaffold({required VoidCallback onPrint, required List<Widget> content}) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onPrint, label: const Text("Export PDF"), icon: const Icon(Icons.picture_as_pdf), backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Container(padding: const EdgeInsets.all(16), decoration: _boxDecor(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: content))),
    );
  }
  BoxDecoration _boxDecor() => BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)]);
  Widget _header(String t) => Center(child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)));
  Widget _subHeader(String t) => Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15));
  Widget _row(String l, double v) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l), Text(_fmt(v))]));
  Widget _rowBold(String l, double v) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: const TextStyle(fontWeight: FontWeight.bold)), Text(_fmt(v), style: const TextStyle(fontWeight: FontWeight.bold))]));
  Widget _highlightBox(String l, double v) => Container(padding: const EdgeInsets.all(10), color: Colors.grey[200], child: _rowBold(l, v));
  
  // --- PDF HELPER ---
  pw.Widget _pdfHeader(String t) => pw.Center(child: pw.Text(t, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)));
  pw.Widget _pdfSub(String t) => pw.Text(t, style: pw.TextStyle(fontWeight: pw.FontWeight.bold));
  pw.Widget _pdfRow(String l, double v) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(l), pw.Text(_fmt(v))]);
  pw.Widget _pdfRowBold(String l, double v) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(l, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text(_fmt(v), style: pw.TextStyle(fontWeight: pw.FontWeight.bold))]);
}