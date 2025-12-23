import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'database/database_helper.dart';
import 'transaction_model.dart';

class FormFinancePage extends StatefulWidget {
  final TransactionModel? transaction; 
  const FormFinancePage({Key? key, this.transaction}) : super(key: key);

  @override
  State<FormFinancePage> createState() => _FormFinancePageState();
}

class _FormFinancePageState extends State<FormFinancePage> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String _selectedType = 'IN'; 
  String _selectedCategory = 'Jual Hasil Ternak Tunai'; 
  
  // --- KATEGORI (SESUAI EXCEL & LOGIKA DATABASE) ---
  
  // PEMASUKAN
  final List<String> _incomeCategories = [
    'Jual Hasil Ternak Tunai',    
    'Jual Hasil Ternak Kredit',   // Menambah Piutang
    'Terima Pelunasan Piutang',   // Mengurangi Piutang
    'Setor Modal Pribadi',        
    'Setor Modal Pinjaman',       // Menambah Utang
    'Pendapatan Lain-lain'        
  ];

  // PENGELUARAN
  final List<String> _expenseCategories = [
    // -- BELI ASET (Menambah Persediaan, Tidak Masuk Laba Rugi) --
    'Beli Ternak Tunai',          
    'Beli Ternak Kredit',         // Menambah Utang
    'Beli Pakan Tunai',           
    'Beli Pakan Kredit',          // Menambah Utang
    'Beli Obat & Vitamin',        
    'Beli Perlengkapan Kandang',
    'Beli Peralatan Kandang',  
    'Beli Mesin',                 
    
    // -- BIAYA OPERASIONAL (Masuk Laba Rugi) --
    'Bayar Listrik dan Air',      
    'Bayar Gaji / Upah',          
    'Bayar Perawatan Kandang',    
    'Sewa Lahan',                 
    'Biaya Lain-lain',            
    
    // -- PEMAKAIAN (Mengurangi Persediaan -> Menjadi Beban) --
    'Pemakaian Pakan',            
    'Pemakaian Obat & Vitamin',   
    'Pakai Perlengkapan Kandang', 
    'Biaya DOC (Saat Jual)',      // HPP Bibit Ayam
    
    // -- KEWAJIBAN & PRIVE --
    'Bayar Utang',                
    'Bayar Pinjaman Modal',       
    'Prive (Tarik Modal)',        
  ];

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _loadExistingData();
    } else {
      _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _selectedType = 'IN';
      _selectedCategory = _incomeCategories[0];
    }
  }

  void _loadExistingData() {
    final t = widget.transaction!;
    _selectedType = t.type;
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    _amountController.text = formatter.format(t.amount).trim(); 
    _selectedCategory = t.category;
    _descController.text = t.description;
    _dateController.text = t.date;
    
    if (_selectedType == 'IN' && !_incomeCategories.contains(_selectedCategory)) {
      _incomeCategories.add(_selectedCategory);
    } else if (_selectedType == 'OUT' && !_expenseCategories.contains(_selectedCategory)) {
      _expenseCategories.add(_selectedCategory);
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      String cleanAmount = _amountController.text.replaceAll('.', '').replaceAll(',', '').replaceAll('Rp', '').trim();
      final amount = double.tryParse(cleanAmount) ?? 0;
      
      final newTransaction = TransactionModel(
        id: widget.transaction?.id,
        type: _selectedType,
        amount: amount,
        category: _selectedCategory,
        description: _descController.text,
        date: _dateController.text,
      );

      if (widget.transaction == null) {
        await DatabaseHelper.instance.insertTransaction(newTransaction);
      } else {
        await DatabaseHelper.instance.updateTransaction(newTransaction);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.transaction != null;
    List<String> currentCategories = _selectedType == 'IN' ? _incomeCategories : _expenseCategories;

    if (!currentCategories.contains(_selectedCategory)) {
      _selectedCategory = currentCategories[0];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Data" : "Catat Transaksi"),
        backgroundColor: const Color(0xFF1E549F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SWITCH TYPE
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() { _selectedType = 'IN'; _selectedCategory = _incomeCategories[0]; }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: _selectedType == 'IN' ? Colors.green : Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: Text("PEMASUKAN", style: TextStyle(fontWeight: FontWeight.bold, color: _selectedType == 'IN' ? Colors.white : Colors.grey))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() { _selectedType = 'OUT'; _selectedCategory = _expenseCategories[0]; }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: _selectedType == 'OUT' ? Colors.red : Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: Text("PENGELUARAN", style: TextStyle(fontWeight: FontWeight.bold, color: _selectedType == 'OUT' ? Colors.white : Colors.grey))),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // NOMINAL
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                decoration: const InputDecoration(
                  labelText: "Nominal (Rp)",
                  border: OutlineInputBorder(),
                  prefixText: "Rp ",
                ),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 15),

              // KATEGORI
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                isExpanded: true,
                decoration: const InputDecoration(labelText: "Kategori Transaksi", border: OutlineInputBorder()),
                items: currentCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) { if (val != null) setState(() => _selectedCategory = val); },
              ),
              // HINT
              if (_selectedCategory.contains("Kredit") || _selectedCategory.contains("Pemakaian") || _selectedCategory.contains("Biaya DOC"))
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Info: Transaksi ini NON-TUNAI. Tidak mengurangi Kas di Dashboard, tapi tercatat di Laporan.",
                    style: TextStyle(color: Colors.orange[800], fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              const SizedBox(height: 15),

              // TANGGAL
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _selectDate,
                decoration: const InputDecoration(labelText: "Tanggal", border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
              ),
              const SizedBox(height: 15),

              // CATATAN
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Catatan (Opsional)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFA9C1B)),
                  onPressed: _saveTransaction,
                  child: Text(isEdit ? "SIMPAN PERUBAHAN" : "SIMPAN TRANSAKSI", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), ''); 
    double value = double.tryParse(cleanText) ?? 0;
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    String newText = formatter.format(value).trim();
    return newValue.copyWith(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}