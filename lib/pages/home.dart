import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:madmet/overlays/update_transaction.dart';
import 'package:madmet/theme/color.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../firestore_service.dart';
import '../overlays/search_transaction.dart';
import '../utils/get_category_icons.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService _firestoreService = FirestoreService();

  // Get current user's ID from Firebase Auth
  String get userId {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Home',
              style: TextStyle(
                fontSize: 24,
                //fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              iconSize: 30,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchTransactionsOverlay()));
              },
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Balance card
          StreamBuilder<AppUser>(
            stream: _firestoreService.streamUserData(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                );
              }

              if (!snapshot.hasData || snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('Error loading user data'),
                );
              }

              final user = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  //height: MediaQuery.of(context).size.height * 0.30,
                  height: 260,
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.black54,
                            Colors.black87,
                            Colors.black,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
                        child: Column(
                          children: [
                            const Text('Total Balance', style: TextStyle(fontSize: 20, color: white)),
                            const SizedBox(height: 10),
                            Text(
                              '\$${user.totalBalance.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                color: white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSummary('Income', user.totalIncome, Icons.arrow_upward, Colors.green),
                                _buildSummary('Expense', user.totalExpense, Icons.arrow_downward, Colors.red),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Recent Transactions label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Row(
              children: const [
                Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 20,
                      //fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),

          // Scrollable list of transactions
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: _firestoreService.streamTransactions(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.hasError) {
                  return const Center(child: Text('Error loading transactions'));
                }

                final transactions = snapshot.data!.take(20).toList();

                if (transactions.isEmpty) {
                  return const Center(child: Text('No transactions yet'));
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 10),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final txn = transactions[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: getCategoryIconWidget(txn.category),
                            title: Text(
                              txn.category,
                              style: const TextStyle( fontSize: 16,
                                  //fontWeight: FontWeight.bold
                              ),
                            ),
                            onTap: () => _showUpdateTransactionOverlay(context, txn),
                            subtitle: Text(
                              (txn.description.isEmpty)
                                  ? 'No description'
                                  : txn.description.length > 20
                                    ? '${txn.description.substring(0, 20)}...'
                                    : txn.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  txn.type == 'Expense'
                                      ? '-\$${txn.amount.toStringAsFixed(2)}'
                                      : '+\$${txn.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: txn.type == 'Expense' ? Colors.red : Colors.green,
                                    //fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  DateFormat.yMMMd().format(txn.date),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

void _showUpdateTransactionOverlay(BuildContext context, TransactionModel txn) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (BuildContext context) {
      return UpdateTransactionOverlay(transaction: txn);  // This will be the modal content
    },
  );
}

Widget _buildSummary(String label, double amount, IconData icon, Color color) {
  return Row(
    children: [
      CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey.withOpacity(0.5),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: white)),
          //const SizedBox(height: 5),
          Text(
            '${label == 'Expense' ? '-' : '+'} \$${amount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    ],
  );
}
