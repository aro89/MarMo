import '../utils/to_double.dart';

class Wallet {
  final String id;
  final String name;
  final double value;
  final String type;

  Wallet({
    required this.id,
    required this.name,
    required this.value,
    required this.type,
  });

  // In Wallet class:
  factory Wallet.fromMap(String id, Map<String, dynamic> data) {
    return Wallet(
      id: id,
      name: data['name'] ?? '',
      value: toDouble(data['value']),
      type: data['type'] ?? 'other',
    );
  }

  // Method to convert Wallet to a Map (Firestore document)
  Map<String, dynamic> toMap() {
    return {
      //'userId': userId,
      'name': name,
      'value': value,
      'type': type,
    };
  }

  // Updated copyWith method to include userId
  Wallet copyWith({
    String? name,
    double? value,
    String? type,
    String? userId,
  }) {
    return Wallet(
      id: this.id,
      name: name ?? this.name,
      value: value ?? this.value,
      type: type ?? this.type,
    );
  }
}
