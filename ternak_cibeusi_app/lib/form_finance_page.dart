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
  final Color polbanBlue = const Color(0xFF1E549F);

  // Controller
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  String _type = 'OUT'; // Default Pengeluaran
  DateTime _selectedDate = DateTime.now();

  // --- DAFTAR AKUN (CHART OF ACCOUNTS) ---
  // Inilah yang menghubungkan User dengan Sistem Akuntansi di belakang
  String? _selectedCategory;
  
  final List<String> _incomeCategories = [
    'Penjualan Hasil Ternak',
    'Penjualan Pupuk/Limbah',
    'Modal Awal',            // Masuk ke Equitas
    'Pendapatan Lainnya'
  ];

  final List<String> _expenseCategories = [
    'Biaya Pakan',
    'Biaya Obat & Vitamin',
    'Biaya Gaji Pegawai',
    'Biaya Listrik & Air',
    'Biaya Operasional Lain',
    'Pembelian Aset Tetap',  // Masuk ke Aset (Kandang/Alat)
    'Prive (Tarik Modal)'    // Mengurangi Equitas
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: polbanBlue)),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final newTransaction = TransactionModel(
        type: _type,
        amount: double.parse(_amountController.text),
        category: _selectedCategory!, // Ambil dari Dropdown
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
    // Tentukan list kategori berdasarkan tipe (Masuk/Keluar)
    List<String> currentCategories = _type == 'IN' ? _incomeCategories : _expenseCategories;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Catat Transaksi'),
        backgroundColor: polbanBlue,
        foregroundColor: Colors.white,
        elevation: 0,
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
                      onTap: () {
                        setState(() {
                          _type = 'OUT';
                          _selectedCategory = null; // Reset kategori saat ganti tipe
                        });
                      },
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
                            const SizedBox(height: 5),
                            Text("Pengeluaran", style: TextStyle(fontWeight: FontWeight.bold, color: _type == 'OUT' ? Colors.white : Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                         setState(() {
                          _type = 'IN';
                          _selectedCategory = null; 
                        });
                      },
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
                            const SizedBox(height: 5),
                            Text("Pemasukan", style: TextStyle(fontWeight: FontWeight.bold, color: _type == 'IN' ? Colors.white : Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // 2. Nominal
              _buildSectionTitle("Nominal Uang"),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(icon: Icons.attach_money, prefix: "Rp "),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 20),

              // 3. Kategori (DROPDOWN - KUNCI AKUNTANSI)
              _buildSectionTitle("Kategori Transaksi (Akun)"),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text("Pilih akun transaksi..."),
                decoration: _inputDecoration(icon: Icons.category),
                items: currentCategories.map((String category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (newValue) => setState(() => _selectedCategory = newValue),
                validator: (val) => val == null ? 'Wajib dipilih' : null,
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
              
              const SizedBox(height: 20),
              _buildSectionTitle("Catatan (Opsional)"),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: _inputDecoration(icon: Icons.note, hint: "Keterangan tambahan..."),
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
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: polbanBlue, width: 2)),
      filled: true,
      fillColor: Colors.grey[50],
      prefixIcon: icon != null ? Icon(icon, color: polbanBlue) : null,
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