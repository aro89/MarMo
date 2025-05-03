import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/user_model.dart';
import 'models/wallet_model.dart';
import 'models/transaction_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // GETTER METHODS FOR USER TOTALS

  // Get user data with all totals
  Future<AppUser> getUserData(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return AppUser.fromMap(userId, userDoc.data() ?? {});
      } else {
        throw Exception("User not found");
      }
    } catch (e) {
      throw Exception("Failed to get user data: $e");
    }
  }

  // Stream user data with all totals - useful for real-time UI updates
  Stream<AppUser> streamUserData(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromMap(userId, doc.data() ?? {}) :
    AppUser(uid: userId, totalBalance: 0, totalIncome: 0, totalExpense: 0));
  }

  // USER OPERATIONS

  // Create or update user
  Future<void> createUser(AppUser user) async {
    try {
      await _db.collection('users').doc(user.uid).set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception("Failed to create/update user: $e");
    }
  }

  // HELPER METHODS FOR CONSISTENT USER TOTAL UPDATES

  // Calculate and update user totals based on all wallets
  Future<void> recalculateUserTotals(String userId) async {
    try {
      // Get all wallets
      final walletDocs = await _db.collection('users').doc(userId).collection('wallets').get();
      final wallets = walletDocs.docs.map((doc) => Wallet.fromMap(doc.id, doc.data())).toList();

      // Calculate total balance from wallets
      double totalBalance = wallets.fold(0, (sum, wallet) => sum + wallet.value);

      // Get all transactions to calculate income and expense totals
      final txnDocs = await _db.collection('users').doc(userId).collection('transactions').get();
      final transactions = txnDocs.docs.map((doc) => TransactionModel.fromMap(doc.id, doc.data())).toList();

      double totalIncome = transactions
          .where((txn) => txn.type == 'Income')
          .fold(0, (sum, txn) => sum + txn.amount);

      double totalExpense = transactions
          .where((txn) => txn.type == 'Expense')
          .fold(0, (sum, txn) => sum + txn.amount);

      // Update user document
      await _db.collection('users').doc(userId).update({
        'totalBalance': totalBalance,
        'totalIncome': totalIncome,
        'totalExpense': totalExpense
      });
    } catch (e) {
      throw Exception("Failed to recalculate user totals: $e");
    }
  }

  // WALLET OPERATIONS

  // Add a new wallet and update total balance
  Future<void> addWallet(String userId, Wallet wallet) async {
    try {
      final batch = _db.batch();

      // Add wallet
      final walletRef = _db.collection('users').doc(userId).collection('wallets').doc(wallet.id);
      batch.set(walletRef, wallet.toMap());

      // Update user's total balance
      final userRef = _db.collection('users').doc(userId);
      final userSnap = await userRef.get();
      double totalBalance = (userSnap.data()?['totalBalance'] as num?)?.toDouble() ?? 0.0;

      double newTotalBalance = totalBalance + wallet.value;
      batch.update(userRef, {'totalBalance': newTotalBalance});

      await batch.commit();
    } catch (e) {
      throw Exception("Failed to add wallet: $e");
    }
  }

  // Update a wallet and update total balance
  Future<void> updateWallet(String userId, Wallet wallet) async {
    try {
      final batch = _db.batch();

      final userRef = _db.collection('users').doc(userId);
      final walletRef = _db.collection('users').doc(userId).collection('wallets').doc(wallet.id);

      final walletSnap = await walletRef.get();
      if (!walletSnap.exists) {
        throw Exception("Wallet not found");
      }

      final oldValue = (walletSnap.data()?['value'] as num?)?.toDouble() ?? 0.0;
      batch.update(walletRef, wallet.toMap());

      // Update user's total balance based on wallet value change
      final userSnap = await userRef.get();
      double totalBalance = (userSnap.data()?['totalBalance'] as num?)?.toDouble() ?? 0.0;

      double newTotalBalance = totalBalance - oldValue + wallet.value;
      batch.update(userRef, {'totalBalance': newTotalBalance});

      await batch.commit();
    } catch (e) {
      throw Exception("Failed to update wallet: $e");
    }
  }

  // Delete a wallet and update total balance
  Future<void> deleteWallet(String userId, String walletId) async {
    try {
      final batch = _db.batch();

      final userRef = _db.collection('users').doc(userId);
      final walletRef = _db.collection('users').doc(userId).collection('wallets').doc(walletId);

      final walletSnap = await walletRef.get();
      if (!walletSnap.exists) {
        throw Exception("Wallet not found");
      }

      final walletValue = (walletSnap.data()?['value'] as num?)?.toDouble() ?? 0.0;
      batch.delete(walletRef);

      // Update user's total balance
      final userSnap = await userRef.get();
      double totalBalance = (userSnap.data()?['totalBalance'] as num?)?.toDouble() ?? 0.0;

      double newTotalBalance = totalBalance - walletValue;
      batch.update(userRef, {'totalBalance': newTotalBalance});

      // Also delete all transactions associated with this wallet
      final txnQuery = await _db.collection('users').doc(userId)
          .collection('transactions')
          .where('walletId', isEqualTo: walletId)
          .get();

      // Note: need to recalculate income/expense after deleting these transactions
      for (final doc in txnQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Recalculate income and expense totals since we deleted transactions
      await recalculateUserTotals(userId);
    } catch (e) {
      throw Exception("Failed to delete wallet: $e");
    }
  }

  // Fetch a specific wallet by its ID
  Future<Wallet> getWallet(String userId, String walletId) async {
    try {
      final walletDoc = await _db.collection('users').doc(userId).collection('wallets').doc(walletId).get();
      if (walletDoc.exists) {
        return Wallet.fromMap(walletDoc.id, walletDoc.data() ?? {});
      } else {
        throw Exception("Wallet not found");
      }
    } catch (e) {
      throw Exception("Failed to fetch wallet: $e");
    }
  }

  // Get all wallets
  Future<List<Wallet>> getWallets(String userId) async {
    try {
      final snapshot = await _db.collection('users').doc(userId).collection('wallets').get();
      return snapshot.docs.map((doc) => Wallet.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      throw Exception("Failed to fetch wallets: $e");
    }
  }

  // Stream all wallets
  Stream<List<Wallet>> streamWallets(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Wallet.fromMap(doc.id, doc.data())).toList());
  }

  // TRANSACTION OPERATIONS

  // Add transaction and update wallet and user balances
  Future<void> addTransaction(String userId, TransactionModel txn) async {
    final batch = _db.batch();
    final walletRef = _db.collection('users').doc(userId).collection('wallets').doc(txn.walletId);
    final userRef = _db.collection('users').doc(userId);
    final txnRef = txn.id.isEmpty
        ? _db.collection('users').doc(userId).collection('transactions').doc() // auto-ID
        : _db.collection('users').doc(userId).collection('transactions').doc(txn.id);

    // Using a transaction to ensure all updates are atomic
    await _db.runTransaction((transaction) async {
      final walletSnap = await transaction.get(walletRef);
      final userSnap = await transaction.get(userRef);

      if (!walletSnap.exists) {
        throw Exception("Wallet not found");
      }

      double walletValue = (walletSnap.data()?['value'] as num?)?.toDouble() ?? 0.0;
      double totalBalance = (userSnap.data()?['totalBalance'] as num?)?.toDouble() ?? 0.0;
      double totalIncome = (userSnap.data()?['totalIncome'] as num?)?.toDouble() ?? 0.0;
      double totalExpense = (userSnap.data()?['totalExpense'] as num?)?.toDouble() ?? 0.0;

      // Calculate new values
      double newWalletValue = txn.type == 'Expense' ? walletValue - txn.amount : walletValue + txn.amount;
      double newTotalBalance = txn.type == 'Expense' ? totalBalance - txn.amount : totalBalance + txn.amount;
      double newTotalIncome = txn.type == 'Income' ? totalIncome + txn.amount : totalIncome;
      double newTotalExpense = txn.type == 'Expense' ? totalExpense + txn.amount : totalExpense;

      // Update wallet
      transaction.update(walletRef, {'value': newWalletValue});

      // Update user totals
      transaction.update(userRef, {
        'totalBalance': newTotalBalance,
        'totalIncome': newTotalIncome,
        'totalExpense': newTotalExpense
      });

      // Add the transaction
      final newTxn = txn.id.isEmpty ? txn.copyWith(id: txnRef.id) : txn;
      transaction.set(txnRef, newTxn.toMap());
    });
  }

  // Update a transaction and update balances
  Future<void> updateTransaction(String userId, TransactionModel txn) async {
    if (txn.id.isEmpty) {
      throw Exception("Transaction ID cannot be empty for update operation");
    }

    try {
      final userRef = _db.collection('users').doc(userId);
      final walletRef = _db.collection('users').doc(userId).collection('wallets').doc(txn.walletId);
      final txnRef = _db.collection('users').doc(userId).collection('transactions').doc(txn.id);

      await _db.runTransaction((transaction) async {
        final txnSnap = await transaction.get(txnRef);
        final walletSnap = await transaction.get(walletRef);
        final userSnap = await transaction.get(userRef);

        if (!txnSnap.exists) {
          throw Exception("Transaction not found");
        }

        if (!walletSnap.exists) {
          throw Exception("Wallet not found");
        }

        // Get old transaction details
        final oldTxn = TransactionModel.fromMap(txnSnap.id, txnSnap.data() ?? {});

        // Get current values
        double walletValue = (walletSnap.data()?['value'] as num?)?.toDouble() ?? 0.0;
        double totalBalance = (userSnap.data()?['totalBalance'] as num?)?.toDouble() ?? 0.0;
        double totalIncome = (userSnap.data()?['totalIncome'] as num?)?.toDouble() ?? 0.0;
        double totalExpense = (userSnap.data()?['totalExpense'] as num?)?.toDouble() ?? 0.0;

        // First revert the old transaction effect
        if (oldTxn.type == 'Expense') {
          walletValue += oldTxn.amount; // Add back the expense
          totalBalance += oldTxn.amount; // Add back to total balance
          totalExpense -= oldTxn.amount; // Remove from total expense
        } else { // income
          walletValue -= oldTxn.amount; // Remove the income
          totalBalance -= oldTxn.amount; // Remove from total balance
          totalIncome -= oldTxn.amount; // Remove from total income
        }

        // Then apply the new transaction effect
        if (txn.type == 'Expense') {
          walletValue -= txn.amount; // Subtract the expense
          totalBalance -= txn.amount; // Subtract from total balance
          totalExpense += txn.amount; // Add to total expense
        } else { // income
          walletValue += txn.amount; // Add the income
          totalBalance += txn.amount; // Add to total balance
          totalIncome += txn.amount; // Add to total income
        }

        // Update the wallet
        transaction.update(walletRef, {'value': walletValue});

        // Update user totals
        transaction.update(userRef, {
          'totalBalance': totalBalance,
          'totalIncome': totalIncome,
          'totalExpense': totalExpense
        });

        // Update the transaction
        transaction.update(txnRef, txn.toMap());
      });
    } catch (e) {
      throw Exception("Failed to update transaction: $e");
    }
  }

  // Delete a transaction and update balances
  Future<void> deleteTransaction(String userId, String txnId) async {
    try {
      final txnRef = _db.collection('users').doc(userId).collection('transactions').doc(txnId);
      final userRef = _db.collection('users').doc(userId);

      await _db.runTransaction((transaction) async {
        final txnSnap = await transaction.get(txnRef);

        if (!txnSnap.exists) {
          throw Exception("Transaction not found");
        }

        final txn = TransactionModel.fromMap(txnSnap.id, txnSnap.data() ?? {});
        final walletRef = _db.collection('users').doc(userId).collection('wallets').doc(txn.walletId);

        final walletSnap = await transaction.get(walletRef);
        final userSnap = await transaction.get(userRef);

        if (!walletSnap.exists) {
          throw Exception("Wallet not found");
        }

        // Get current values
        double walletValue = (walletSnap.data()?['value'] as num?)?.toDouble() ?? 0.0;
        double totalBalance = (userSnap.data()?['totalBalance'] as num?)?.toDouble() ?? 0.0;
        double totalIncome = (userSnap.data()?['totalIncome'] as num?)?.toDouble() ?? 0.0;
        double totalExpense = (userSnap.data()?['totalExpense'] as num?)?.toDouble() ?? 0.0;

        // Revert the transaction effect
        if (txn.type == 'Expense') {
          walletValue += txn.amount; // Add back the expense amount to wallet
          totalBalance += txn.amount; // Add back to total balance
          totalExpense -= txn.amount; // Remove from total expense
        } else { // income
          walletValue -= txn.amount; // Remove the income from wallet
          totalBalance -= txn.amount; // Remove from total balance
          totalIncome -= txn.amount; // Remove from total income
        }

        // Update the wallet
        transaction.update(walletRef, {'value': walletValue});

        // Update user totals
        transaction.update(userRef, {
          'totalBalance': totalBalance,
          'totalIncome': totalIncome,
          'totalExpense': totalExpense
        });

        // Delete the transaction
        transaction.delete(txnRef);
      });
    } catch (e) {
      throw Exception("Failed to delete transaction: $e");
    }
  }

  // Get all transactions
  Future<List<TransactionModel>> getTransactions(String userId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .get();
      return snapshot.docs.map((doc) => TransactionModel.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      throw Exception("Failed to fetch transactions: $e");
    }
  }

  // Stream all transactions
  Stream<List<TransactionModel>> streamTransactions(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TransactionModel.fromMap(doc.id, doc.data())).toList());
  }

  // Get transactions by wallet
  Future<List<TransactionModel>> getTransactionsByWallet(String userId, String walletId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('walletId', isEqualTo: walletId)
          .orderBy('date', descending: true)
          .get();
      return snapshot.docs.map((doc) => TransactionModel.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      throw Exception("Failed to fetch wallet transactions: $e");
    }
  }

  // Stream transactions by wallet
  Stream<List<TransactionModel>> streamTransactionsByWallet(String userId, String walletId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .where('walletId', isEqualTo: walletId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TransactionModel.fromMap(doc.id, doc.data())).toList());
  }

  // Batch delete documents under a subcollection
  Future<void> batchDeleteDocuments(
      String userId,
      String subcollection,
      List<String> docIds, {
        bool parallel = false,
      }) async {
    const int batchSize = 500;
    final firestore = FirebaseFirestore.instance;

    if (parallel) {
      // PARALLEL VERSION
      final List<Future<void>> commitFutures = [];

      for (var i = 0; i < docIds.length; i += batchSize) {
        final batch = firestore.batch();
        final end = (i + batchSize < docIds.length) ? i + batchSize : docIds.length;
        final batchDocIds = docIds.sublist(i, end);

        for (final docId in batchDocIds) {
          final docRef = firestore.collection('users').doc(userId).collection(subcollection).doc(docId);
          batch.delete(docRef);
        }

        commitFutures.add(batch.commit());
      }

      await Future.wait(commitFutures);
      //print('All batch deletions completed in PARALLEL for $subcollection');

    } else {
      // SEQUENTIAL VERSION
      for (var i = 0; i < docIds.length; i += batchSize) {
        final batch = firestore.batch();
        final end = (i + batchSize < docIds.length) ? i + batchSize : docIds.length;
        final batchDocIds = docIds.sublist(i, end);

        for (final docId in batchDocIds) {
          final docRef = firestore.collection('users').doc(userId).collection(subcollection).doc(docId);
          batch.delete(docRef);
        }

        await batch.commit(); // Wait for each batch one by one
      }
      //print('All batch deletions completed SEQUENTIALLY for $subcollection');
    }
  }
}