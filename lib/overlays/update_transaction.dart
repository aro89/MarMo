import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:madmet/firestore_service.dart';
import 'package:madmet/models/transaction_model.dart';
import 'package:madmet/models/wallet_model.dart';
import '../theme/color.dart';
import '../misc/category_list.dart';
import '../widgets_main/build_label.dart';
import '../widgets_main/build_text_field.dart';
import '../widgets_main/build_dropdown.dart';
import '../widgets_main/submit_button.dart';
import '../widgets_main/transaction_type_selector.dart';
import '../widgets_main/wallet_dropdown.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

class UpdateTransactionOverlay extends StatefulWidget {
  final TransactionModel transaction;

  const UpdateTransactionOverlay({Key? key, required this.transaction}) : super(key: key);

  @override
  _UpdateTransactionOverlayState createState() => _UpdateTransactionOverlayState();
}

class _UpdateTransactionOverlayState extends State<UpdateTransactionOverlay> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController amountController;
  late TextEditingController descriptionController;
  late TextEditingController dateController;

  String? selectedType;
  Wallet? selectedWallet;
  String? selectedCategory;
  DateTime? selectedDate;

  final FirestoreService _firestoreService = FirestoreService();
  List<Wallet> wallets = [];
  bool _isLoading = false;

  String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _fetchWallets();
    final txn = widget.transaction;
    amountController = TextEditingController(text: txn.amount.toStringAsFixed(2));
    descriptionController = TextEditingController(text: txn.description);
    selectedType = txn.type;
    selectedCategory = txn.category;
    selectedDate = txn.date;
    dateController = TextEditingController(text: "${txn.date.toLocal()}".split(' ')[0]);
  }

  Future<void> _fetchWallets() async {
    setState(() => _isLoading = true);
    try {
      final fetchedWallets = await _firestoreService.getWallets(userId);
      setState(() {
        wallets = fetchedWallets;
        selectedWallet = wallets.firstWhere(
              (w) => w.id == widget.transaction.walletId,
          orElse: () => wallets.first,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading wallets: $e');
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() != true ||
        selectedWallet == null ||
        selectedType == null ||
        selectedCategory == null ||
        selectedDate == null) {
      _showErrorSnackBar('Please fill all required fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedTxn = TransactionModel(
        id: widget.transaction.id,
        type: selectedType!,
        walletId: selectedWallet!.id,
        category: selectedCategory!,
        date: selectedDate!,
        amount: double.parse(
          toNumericString(amountController.text.trim(), allowPeriod: true),
        ),
        description: descriptionController.text.trim(),
      );

      await _firestoreService.updateTransaction(userId, updatedTxn);

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error updating transaction: $e');
    }
  }

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this transaction?"),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    setState(() => _isLoading = true);
                    try {
                      await _firestoreService.deleteTransaction(userId, widget.transaction.id);
                      if (mounted) {
                        setState(() => _isLoading = false);
                        _showDeleteSuccessAndPop();
                      }
                    } catch (e) {
                      setState(() => _isLoading = false);
                      _showErrorSnackBar('Failed to delete transaction: $e');
                    }
                  },
                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteSuccessAndPop() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 70),
              SizedBox(height: 20),
              Text('Transaction Deleted', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      Navigator.of(context).pop(); // Close dialog
      Navigator.pop(context, true);
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.90,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            title: const Text(
              'Edit Transaction',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade900,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                    onPressed: _handleDelete,
                  ),
                ),
              ),
            ],
          ),
          body: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildLabel('Transaction Type'),
              TransactionTypeSelector(
                selectedType: selectedType,
                onTypeSelected: (type) {
                  setState(() {
                    selectedType = type;
                    selectedCategory = null;
                  });
                },
              ),
              const SizedBox(height: 24),

              buildLabel('Wallet'),
              WalletDropdown(
                wallets: wallets,
                selectedWallet: selectedWallet,
                onWalletSelected: (wallet) {
                  setState(() => selectedWallet = wallet);
                },
              ),
              const SizedBox(height: 24),

              if (selectedType != null) ...[
                buildLabel('Category'),
                buildDropdown(
                  value: selectedCategory,
                  items: selectedType == 'Income' ? walletTypes : expenseCategories,
                  hint: 'Select category',
                  onChanged: (val) => setState(() => selectedCategory = val),
                  icon: Icons.category,
                ),
                const SizedBox(height: 24),
              ],

              buildLabel('Date'),
              buildTextField(
                controller: dateController,
                hintText: 'Pick a date',
                readOnly: true,
                onTap: _pickDate,
                prefixIcon: const Icon(Icons.calendar_today, size: 20),
              ),
              const SizedBox(height: 24),

              buildLabel('Amount'),
              buildTextField(
                controller: amountController,
                hintText: 'Enter amount',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.attach_money, size: 20),
                inputFormatters: [
                  CurrencyInputFormatter(mantissaLength: 2),
                ],
              ),
              const SizedBox(height: 24),

              buildLabel('Description (Optional)'),
              buildTextField(
                controller: descriptionController,
                hintText: 'What is this transaction for?',
                required: false,
                prefixIcon: const Icon(Icons.description, size: 20),
                maxLines: 2,
              ),
              const SizedBox(height: 40),

              SubmitButton(
                onPressed: _handleSubmit,
                label: 'Update Transaction',
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
