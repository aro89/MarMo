import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:madmet/firestore_service.dart';
import 'package:madmet/models/wallet_model.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import '../misc/category_list.dart';
import '../theme/color.dart';
import '../widgets_main/build_label.dart';
import '../widgets_main/build_text_field.dart';
import '../widgets_main/build_dropdown.dart';
import '../widgets_main/submit_button.dart';

class UpdateWalletOverlay extends StatefulWidget {
  final Wallet wallet;

  const UpdateWalletOverlay({Key? key, required this.wallet}) : super(key: key);

  @override
  State<UpdateWalletOverlay> createState() => _UpdateWalletOverlayState();
}

class _UpdateWalletOverlayState extends State<UpdateWalletOverlay> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController valueController;
  String? selectedWalletType;
  bool _isLoading = false;

  final FirestoreService _firestoreService = FirestoreService();

  String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.wallet.name);
    valueController = TextEditingController(
      text: toCurrencyString(
        widget.wallet.value.toStringAsFixed(2),
        leadingSymbol: '\$',
      ),
    );
    selectedWalletType = widget.wallet.type;
  }

  @override
  void dispose() {
    nameController.dispose();
    valueController.dispose();
    super.dispose();
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


  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please fill all required fields');
      return;
    }

    setState(() => _isLoading = true);

    final updatedWallet = widget.wallet.copyWith(
      name: nameController.text.trim(),
      value: double.tryParse(toNumericString(valueController.text.trim(), allowPeriod: true)) ?? 0.0,
      type: selectedWalletType ?? widget.wallet.type,
    );

    try {
      await _firestoreService.updateWallet(userId, updatedWallet);
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error updating wallet: $e');
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this wallet?"),
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
                    try {
                      await _firestoreService.deleteWallet(userId, widget.wallet.id);
                      Navigator.pop(context); // close dialog
                      Navigator.pop(context); // close overlay
                    } catch (e) {
                      _showErrorSnackBar('Failed to delete wallet: $e');
                    }
                  },
                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
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
              'Edit Wallet',
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
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: _showDeleteDialog,
                  ),
                ),
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildForm(),
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
              buildLabel('Wallet Name'),
              buildTextField(
                controller: nameController,
                hintText: 'Enter wallet name',
                prefixIcon: const Icon(Icons.account_balance_wallet, size: 20),
              ),
              const SizedBox(height: 24),

              buildLabel('Wallet Type'),
              buildDropdown(
                value: selectedWalletType,
                items: walletTypes,
                hint: 'Select wallet type',
                onChanged: (val) => setState(() => selectedWalletType = val),
                icon: Icons.category,
              ),
              const SizedBox(height: 24),

              buildLabel('Amount'),
              buildTextField(
                controller: valueController,
                hintText: 'Enter wallet value',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.attach_money, size: 20),
                inputFormatters: [
                  CurrencyInputFormatter(
                    leadingSymbol: '\$',
                    useSymbolPadding: true,
                    mantissaLength: 2,
                  ),
                ],
              ),
              const SizedBox(height: 40),

              SubmitButton(
                onPressed: _handleSubmit,
                label: 'Update Wallet',
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
