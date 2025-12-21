import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'transaction_model.dart';
import 'database/database_helper.dart';

// --- CURRENCY FORMATTER (Agar Input jadi 1.000.000) ---
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;
    double value = double.parse(newValue.text.replaceAll('.', '').replaceAll(',', ''));
    final formatter = NumberFormat("#,###", "id_ID");
    String newText = formatter.format(value).replaceAll(',', '.');
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class FormFinancePage extends StatefulWidget {
  const FormFinancePage({Key? key}) : super(key: key);

  @override
  State<FormFinancePage> createState() => _FormFinancePageState();
}

class _FormFinancePageState extends State<FormFinancePage> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Color polbanBlue = const Color(0xFF1E549F);

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  String _type = 'OUT'; 
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;

  // --- DAFTAR TRANSAKSI SESUAI EXCEL (RHPP) ---
  // Kita sesuaikan dengan kolom "Keterangan" di Excel
  final List<String> _incomeTransactions = [
    'Setor Modal',
    'Jual Ayam Tunai',
    'Jual Ayam Kredit',
    'Terima Pelunasan Piutang',
    'Pendapatan Lain-lain'
  ];

  final List<String> _expenseTransactions = [
    'Beli Ayam Tunai',
    'Beli Ayam Kredit',
    'Beli Pakan Tunai Pre Starter',
    'Beli Pakan Tunai Starter',
    'Beli Pakan Tunai Finisher',
    'Beli Obat & Vitamin',
    'Beli Perlengkapan Kandang',
    'Bayar Listrik dan Air',
    'Bayar Gaji',
    'Bayar Perawatan Kandang',
    'Bayar Utang',
    'Biaya Lain-lain',
    'Prive (Tarik Modal)' 
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: polbanBlue)), child: child!),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      // Hilangkan titik sebelum simpan ke database (1.000.000 -> 1000000)
      String cleanAmount = _amountController.text.replaceAll('.', '');
      
      final newTransaction = TransactionModel(
        type: _type,
        amount: double.parse(cleanAmount),
        category: _selectedCategory!, // Simpan Jenis Transaksi
        description: _descController.text,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      );

      await _dbHelper.insertTransaction(newTransaction);
      if (!mounted) return;
      Navigator.pop(context, true); 
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> currentTransactions = _type == 'IN' ? _incomeTransactions : _expenseTransactions;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Catat Transaksi'),
        backgroundColor: polbanBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Pilihan Jenis (IN/OUT)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() { _type = 'OUT'; _selectedCategory = null; }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: _type == 'OUT' ? Colors.redAccent : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _type == 'OUT' ? Colors.red : Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.arrow_upward, color: _type == 'OUT' ? Colors.white : Colors.grey),
                            Text("Pengeluaran", style: TextStyle(fontWeight: FontWeight.bold, color: _type == 'OUT' ? Colors.white : Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() { _type = 'IN'; _selectedCategory = null; }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: _type == 'IN' ? Colors.green : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _type == 'IN' ? Colors.green[700]! : Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.arrow_downward, color: _type == 'IN' ? Colors.white : Colors.grey),
                            Text("Pemasukan", style: TextStyle(fontWeight: FontWeight.bold, color: _type == 'IN' ? Colors.white : Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // 2. Jenis Transaksi (DROPDOWN)
              _buildSectionTitle("Jenis Transaksi"),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text("Pilih transaksi (Cth: Jual Ayam Tunai)"),
                decoration: _inputDecoration(icon: Icons.receipt_long),
                items: currentTransactions.map((String val) {
                  return DropdownMenuItem(value: val, child: Text(val));
                }).toList(),
                onChanged: (newValue) => setState(() => _selectedCategory = newValue),
                validator: (val) => val == null ? 'Wajib dipilih' : null,
              ),
              const SizedBox(height: 20),

              // 3. Nominal (FORMATTER TITIK)
              _buildSectionTitle("Nominal Uang"),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                // PANGGIL FORMATTER DISINI
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                decoration: _inputDecoration(icon: Icons.attach_money, prefix: "Rp "),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 20),

              // 4. Tanggal
              _buildSectionTitle("Tanggal"),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: polbanBlue),
                      const SizedBox(width: 12),
                      Text(DateFormat('dd MMMM yyyy').format(_selectedDate), style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: polbanBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveTransaction,
                  child: const Text('SIMPAN TRANSAKSI', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({IconData? icon, String? prefix, String? hint}) {
    return InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[50],
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF1E549F)) : null,
      prefixText: prefix,
      hintText: hint,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
    );
  }
}