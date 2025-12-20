import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'transaction_model.dart';
import 'database/database_helper.dart';

class FormFinancePage extends StatefulWidget {
  const FormFinancePage({Key? key}) : super(key: key);

  @override
  State<FormFinancePage> createState() => _FormFinancePageState();
}

class _FormFinancePageState extends State<FormFinancePage> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Controller untuk input text
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  // Default nilai awal
  String _type = 'OUT'; // Default Pengeluaran
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // Fungsi pilih tanggal
  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // Fungsi simpan data
  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final newTransaction = TransactionModel(
        type: _type,
        amount: double.parse(_amountController.text),
        category: _categoryController.text,
        description: _descController.text,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      );

      await _dbHelper.insertTransaction(newTransaction);

      if (!mounted) return;
      Navigator.pop(context, true); // Kembali & kasih sinyal berhasil
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Keuangan'),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Pilihan Jenis (Masuk/Keluar)
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Pengeluaran', style: TextStyle(fontSize: 14)),
                      value: 'OUT',
                      groupValue: _type,
                      activeColor: Colors.red,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _type = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Pemasukan', style: TextStyle(fontSize: 14)),
                      value: 'IN',
                      groupValue: _type,
                      activeColor: Colors.green,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _type = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 2. Input Nominal
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal (Rp)',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 15),

              // 3. Input Kategori
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Kategori (Cth: Makan, Gaji)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 15),

              // 4. Pilih Tanggal
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tanggal Transaksi'),
                subtitle: Text(DateFormat('dd MMMM yyyy').format(_selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                trailing: const Icon(Icons.calendar_today, color: Colors.teal),
                onTap: _pickDate,
              ),
              const Divider(),
              const SizedBox(height: 10),

              // 5. Deskripsi (Opsional)
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                  ),
                  onPressed: _saveTransaction,
                  child: const Text('SIMPAN TRANSAKSI', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}