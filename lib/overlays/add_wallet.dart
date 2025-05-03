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

class AddWalletOverlay extends StatefulWidget {
  const AddWalletOverlay({Key? key}) : super(key: key);

  @override
  State<AddWalletOverlay> createState() => _AddWalletOverlayState();
}

class _AddWalletOverlayState extends State<AddWalletOverlay> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController valueController = TextEditingController();
  String? selectedWalletType;
  bool _isLoading = false;

  final FirestoreService _firestoreService = FirestoreService();

  String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';

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
    if (!_formKey.currentState!.validate() || selectedWalletType == null) {
      _showErrorSnackBar('Please fill all required fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newWallet = Wallet(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameController.text.trim(),
        value: double.tryParse(
          toNumericString(valueController.text.trim(), allowPeriod: true),
        ) ??
            0.0,
        type: selectedWalletType!,
      );

      await _firestoreService.addWallet(userId, newWallet);

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error adding wallet: $e');
    }
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
              'New Wallet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            centerTitle: true,
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
              // Wallet Name
              buildLabel('Wallet Name'),
              buildTextField(
                controller: nameController,
                hintText: 'Enter wallet name',
                prefixIcon: const Icon(Icons.account_balance_wallet, size: 20),
              ),
              const SizedBox(height: 24),

              // Wallet Type
              buildLabel('Wallet Type'),
              buildDropdown(
                value: selectedWalletType,
                items: walletTypes,
                hint: 'Select wallet type',
                onChanged: (val) => setState(() => selectedWalletType = val),
                icon: Icons.category,
              ),
              const SizedBox(height: 24),

              // Wallet Value
              buildLabel('Amount'),
              buildTextField(
                controller: valueController,
                hintText: 'Enter wallet value',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.attach_money, size: 20),
                inputFormatters: [
                  CurrencyInputFormatter(
                    useSymbolPadding: true,
                    mantissaLength: 2,
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Submit Button
              SubmitButton(
                onPressed: _handleSubmit,
                label: 'Add Wallet',
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }


}