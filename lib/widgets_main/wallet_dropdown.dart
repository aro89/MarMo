// widgets_authentication/wallet_dropdown.dart
import 'package:flutter/material.dart';
import '../models/wallet_model.dart';
import '../widgets_main/build_dropdown.dart';

class WalletDropdown extends StatelessWidget {
  final List<Wallet> wallets;
  final Wallet? selectedWallet;
  final void Function(Wallet) onWalletSelected;

  const WalletDropdown({
    Key? key,
    required this.wallets,
    required this.selectedWallet,
    required this.onWalletSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool showSearch = wallets.length > 5;

    return buildDropdown(
      value: selectedWallet?.name,
      items: wallets.map((w) => w.name).toList(),
      hint: 'Select wallet',
      onChanged: (val) {
        final wallet = wallets.firstWhere((w) => w.name == val, orElse: () => wallets.first);
        onWalletSelected(wallet);
      },
      icon: Icons.account_balance_wallet,
      showSearch: showSearch,
    );
  }
}
