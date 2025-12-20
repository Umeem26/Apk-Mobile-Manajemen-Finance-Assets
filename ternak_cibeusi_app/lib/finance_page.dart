import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'database/database_helper.dart'; // Import Database
import 'transaction_model.dart'; // Import Model
import 'form_finance_page.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({Key? key}) : super(key: key);

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  // FIX: Gunakan .instance, bukan ()
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  List<TransactionModel> _transactions = [];
  double _totalSaldo = 0;
  double _pemasukan = 0;
  double _pengeluaran = 0;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() async {
    final data = await _dbHelper.getTransactions();
    setState(() {
      _transactions = data;
      _pemasukan = 0;
      _pengeluaran = 0;
      
      for (var item in data) {
        if (item.type == 'IN') {
          _pemasukan += item.amount;
        } else {
          _pengeluaran += item.amount;
        }
      }
      _totalSaldo = _pemasukan - _pengeluaran;
    });
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  void _deleteData(int id) async {
    await _dbHelper.deleteTransaction(id);
    _refreshData(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Keuangan'),
        backgroundColor: Colors.teal, 
        elevation: 0,
      ),
      body: Column(
        children: [
          // KARTU SALDO
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Text('Total Saldo Saat Ini', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                Text(
                  _formatCurrency(_totalSaldo),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.arrow_downward, color: Colors.lightGreenAccent),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pemasukan', style: TextStyle(color: Colors.white70)),
                            Text(_formatCurrency(_pemasukan),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.arrow_upward, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pengeluaran', style: TextStyle(color: Colors.white70)),
                            Text(_formatCurrency(_pengeluaran),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),

          // LIST RIWAYAT
          Expanded(
            child: _transactions.isEmpty
                ? const Center(child: Text('Belum ada transaksi'))
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final item = _transactions[index];
                      final isMasuk = item.type == 'IN';
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMasuk ? Colors.green[50] : Colors.red[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isMasuk ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isMasuk ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(item.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(item.date),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                (isMasuk ? '+ ' : '- ') + _formatCurrency(item.amount),
                                style: TextStyle(
                                  color: isMasuk ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.grey),
                                onPressed: () => _deleteData(item.id!),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
        onPressed: () async {
          // Navigasi ke FormFinancePage
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FormFinancePage()),
          );

          // Jika kembali membawa data "berhasil" (true), refresh halaman
          if (result == true) {
            _refreshData();
          }
        },
      ),
    );
  }
}