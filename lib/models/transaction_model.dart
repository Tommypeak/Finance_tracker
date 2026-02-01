enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final TransactionType type;
  final double amount;
  final String category;
  final DateTime date;
  final String note;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    required this.note,
  });

  // 🔥 FIX ДЛЯ POSTGRESQL (NUMERIC → String)
  factory TransactionModel.fromBackendJson(
    Map<String, dynamic> json, {
    required bool isIncome,
  }) {
    return TransactionModel(
      id: json['id'].toString(),
      type: isIncome
          ? TransactionType.income
          : TransactionType.expense,

      // ✅ ВАЖНОЕ МЕСТО
      amount: json['amount'] is num
          ? (json['amount'] as num).toDouble()
          : double.parse(json['amount'].toString()),

      category: json['category'] ?? '',
      note: json['note'] ?? '',
      date: DateTime.parse(json['tx_date']),
    );
  }
}
