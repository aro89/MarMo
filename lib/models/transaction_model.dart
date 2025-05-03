import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/to_double.dart';

class TransactionModel {
  final String id;
  final String type; // 'income' or 'expense'
  final String walletId;
  final String category;
  final DateTime date;
  final double amount;
  final String description;

  TransactionModel({
    required this.id,
    required this.type,
    required this.walletId,
    required this.category,
    required this.date,
    required this.amount,
    required this.description,
  });

  Map<String, dynamic> toMap() => {
    'type': type,
    'walletId': walletId,
    'category': category,
    'date': Timestamp.fromDate(date),
    'amount': amount,
    'description': description,
  };

  // In TransactionModel class:
  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    final rawDate = map['date'];

    return TransactionModel(
      id: id,
      type: map['type'],
      walletId: map['walletId'],
      category: map['category'],
      date: rawDate is Timestamp ? rawDate.toDate() : DateTime.now(),
      amount: toDouble(map['amount']),
      description: map['description'],
    );
  }

  // ✅ copyWith method
  TransactionModel copyWith({
    String? id,
    String? type,
    String? walletId,
    String? category,
    DateTime? date,
    double? amount,
    String? description,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      walletId: walletId ?? this.walletId,
      category: category ?? this.category,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      description: description ?? this.description,
    );
  }
}
