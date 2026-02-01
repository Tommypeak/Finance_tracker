import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  int selectedIndex = 0;

  void setTab(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  late final ApiService _api = ApiService(_baseUrl());

  String _baseUrl() {
    if (kIsWeb) return 'http://localhost:8080';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  final List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);

  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  Future<void> loadFromDb() async {
    final kiris = await _api.getList('/kiris');
    final shygys = await _api.getList('/shygys');

    final income = kiris
        .map((e) => TransactionModel.fromBackendJson(
              e as Map<String, dynamic>,
              isIncome: true,
            ))
        .toList();

    final expense = shygys
        .map((e) => TransactionModel.fromBackendJson(
              e as Map<String, dynamic>,
              isIncome: false,
            ))
        .toList();

    _transactions
      ..clear()
      ..addAll([...income, ...expense]);

    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel tx) async {
    final payload = {
      'category': tx.category,
      'amount': tx.amount,
      'note': tx.note,
      'tx_date': tx.date.toIso8601String(),
    };

    final json = tx.type == TransactionType.income
        ? await _api.post('/kiris', payload)
        : await _api.post('/shygys', payload);

    final created = TransactionModel.fromBackendJson(
      json,
      isIncome: tx.type == TransactionType.income,
    );

    _transactions.insert(0, created);
    notifyListeners();
  }

  Future<void> deleteTransaction(TransactionModel tx) async {
    if (tx.type == TransactionType.income) {
      await _api.delete('/kiris/${tx.id}');
    } else {
      await _api.delete('/shygys/${tx.id}');
    }
    _transactions.removeWhere((t) => t.id == tx.id);
    notifyListeners();
  }

  // ✅ UPDATE → BACKEND → DB
  Future<void> updateTransaction(TransactionModel updated) async {
    final payload = {
      'category': updated.category,
      'amount': updated.amount,
      'note': updated.note,
      'tx_date': updated.date.toIso8601String(),
    };

    final json = updated.type == TransactionType.income
        ? await _api.put('/kiris/${updated.id}', payload)
        : await _api.put('/shygys/${updated.id}', payload);

    final fromDb = TransactionModel.fromBackendJson(
      json,
      isIncome: updated.type == TransactionType.income,
    );

    final index = _transactions.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      _transactions[index] = fromDb;
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    }
  }

  // Categories
  final List<String> _systemCategories = const [
    'Food',
    'Transport',
    'Study',
    'Home',
    'Health',
    'Entertainment',
    'Other',
  ];
  final List<String> _userCategories = [];

  List<String> get categories => List.unmodifiable([..._systemCategories, ..._userCategories]);

  void addCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final exists = categories.any((c) => c.toLowerCase() == trimmed.toLowerCase());
    if (exists) return;
    _userCategories.add(trimmed);
    notifyListeners();
  }

  bool isSystemCategory(String name) {
  return _systemCategories.contains(name);
}

  void removeUserCategory(String name) {
    _userCategories.removeWhere((c) => c.toLowerCase() == name.toLowerCase());
    notifyListeners();
  }
}
