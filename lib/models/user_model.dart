import '../utils/to_double.dart';

class AppUser {
  final String uid;
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;

  AppUser({
    required this.uid,
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
  });

  Map<String, dynamic> toMap() => {
    'totalBalance': totalBalance,
    'totalIncome': totalIncome,
    'totalExpense': totalExpense,
  };

  // In AppUser class:
  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      totalBalance: toDouble(map['totalBalance']),
      totalIncome: toDouble(map['totalIncome']),
      totalExpense: toDouble(map['totalExpense']),
    );
  }
}
