import 'package:flutter/material.dart';
import 'package:madmet/models/wallet_model.dart';
import 'package:madmet/models/user_model.dart';
import 'package:madmet/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:madmet/theme/color.dart';
import 'package:madmet/utils/get_category_icons.dart';

import '../overlays/add_wallet.dart';
import '../overlays/update_wallet.dart';

class WalletsPage extends StatefulWidget {
  const WalletsPage({super.key});

  @override
  State<WalletsPage> createState() => _WalletsPageState();
}

class _WalletsPageState extends State<WalletsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your wallets')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Wallets',
          style: TextStyle(
            fontSize: 24,
            //fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Stream user data to get real-time total balance
          StreamBuilder<AppUser>(
            stream: _firestoreService.streamUserData(userId!),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              final totalBalance = userSnapshot.hasData
                  ? userSnapshot.data!.totalBalance
                  : 0.0;

              return Column(
                children: [
                  Text(
                    '\$${totalBalance.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Total Balance',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'My Wallets',
                          style: TextStyle(
                              fontSize: 20,
                              //fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.white,
                            builder: (context) => AddWalletOverlay(),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    // Stream wallets to get real-time updates
                    child: StreamBuilder<List<Wallet>>(
                      stream: _firestoreService.streamWallets(userId!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('No wallets found. Add your first wallet!'));
                        }

                        final wallets = snapshot.data!;

                        return GridView.builder(
                          itemCount: wallets.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                          ),
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            final wallet = wallets[index];
                            return GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.white,
                                  builder: (context) => UpdateWalletOverlay(wallet: wallet),
                                );
                              },
                              onLongPress: () {
                                _showDeleteWalletDialog(context, wallet);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: grey,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.grey.shade100,
                                      radius: 24,
                                      child: getCategoryIconWidget(wallet.type, isWallet: true),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      wallet.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '\$${wallet.value.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteWalletDialog(BuildContext context, Wallet wallet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Wallet'),
        content: Text('Are you sure you want to delete "${wallet.name}"? This will also delete all transactions associated with this wallet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestoreService.deleteWallet(userId!, wallet.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wallet deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete wallet: $e')),
                );
              }
            },
            child: const Text('DELETE'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}