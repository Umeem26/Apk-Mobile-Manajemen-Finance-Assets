import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database/database_helper.dart';
import 'transaction_model.dart';
import 'form_finance_page.dart';

class ListFinancePage extends StatefulWidget {
  const ListFinancePage({Key? key}) : super(key: key);

  @override
  State<ListFinancePage> createState() => _ListFinancePageState();
}

class _ListFinancePageState extends State<ListFinancePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;

  double _totalSaldo = 0;
  double _pemasukan = 0;
  double _pengeluaran = 0;
  
  final Color polbanBlue = const Color(0xFF1E549F);
  final Color polbanDarkBlue = const Color(0xFF153E75);
  final Color polbanOrange = const Color(0xFFFA9C1B);

  @override
  void initState() {
    super.initState();
    _refreshTransactions();
  }

  void _refreshTransactions() async {
    setState(() => _isLoading = true);
    final data = await _dbHelper.getTransactions();
    final cashflow = await _dbHelper.getSaldoCashflow();

    if (mounted) {
      setState(() {
        _transactions = data;
        _pemasukan = cashflow['in']!;
        _pengeluaran = cashflow['out']!;
        _totalSaldo = cashflow['total']!;
        _isLoading = false;
      });
    }
  }

  String _fmtUang(double amount) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  
  String _fmtTanggal(String dateStr) {
    try {
      DateTime dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  void _showDeleteDialog(TransactionModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Transaksi?"),
        content: Text("Yakin ingin menghapus ${item.category}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _dbHelper.deleteTransaction(item.id!);
              Navigator.pop(ctx);
              _refreshTransactions();
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Keuangan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: polbanBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // HEADER MODERN
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [polbanBlue, polbanDarkBlue]),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              boxShadow: [BoxShadow(color: polbanBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                const Text("Total Kas Saat Ini", style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(_fmtUang(_totalSaldo), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      _summaryItem(Icons.arrow_downward, Colors.lightGreenAccent, "Pemasukan", _pemasukan),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _summaryItem(Icons.arrow_upward, Colors.redAccent, "Pengeluaran", _pengeluaran),
                    ],
                  ),
                )
              ],
            ),
          ),

          // LIST TRANSAKSI (Modern Card dengan Fix Typo sebelumnya)
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: polbanBlue))
                : _transactions.isEmpty
                    ? const Center(child: Text("Belum ada transaksi", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final item = _transactions[index];
                          bool isMasuk = item.type == 'IN';
                          bool isNonTunai = item.category.contains("Kredit") || item.category.contains("Pemakaian") || item.category.contains("Biaya DOC");

                          return Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))]),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                children: [
                                  Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 5, color: isNonTunai ? Colors.orange : (isMasuk ? Colors.green : Colors.redAccent))),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(color: isNonTunai ? Colors.orange.withOpacity(0.1) : (isMasuk ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1)), shape: BoxShape.circle),
                                          child: Icon(isNonTunai ? Icons.history_edu : (isMasuk ? Icons.arrow_downward : Icons.arrow_upward), color: isNonTunai ? Colors.orange : (isMasuk ? Colors.green : Colors.red), size: 24),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(item.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3436))),
                                              const SizedBox(height: 4),
                                              Text(_fmtTanggal(item.date), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                              if(isNonTunai) Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(4)), child: Text("Non-Tunai", style: TextStyle(fontSize: 10, color: Colors.orange[800]))),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text("${isMasuk ? '+' : '-'} ${_fmtUang(item.amount).replaceAll('Rp ', '')}", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isNonTunai ? Colors.grey : (isMasuk ? Colors.green : Colors.redAccent))),
                                            const SizedBox(height: 8),
                                            Row(children: [
                                              GestureDetector(onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => FormFinancePage(transaction: item))); _refreshTransactions(); }, child: const Icon(Icons.edit, size: 18, color: Colors.blueGrey)),
                                              const SizedBox(width: 10),
                                              GestureDetector(onTap: () => _showDeleteDialog(item), child: Icon(Icons.delete, size: 18, color: Colors.red[200])),
                                            ])
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: polbanOrange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Catat Transaksi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const FormFinancePage()));
          _refreshTransactions();
        },
      ),
    );
  }

  Widget _summaryItem(IconData icon, Color color, String label, double value) {
    return Expanded(
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)), Text(_fmtUang(value), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))])),
        ],
      ),
    );
  }
}