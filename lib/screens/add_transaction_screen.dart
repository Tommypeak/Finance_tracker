import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../models/transaction_model.dart';

enum TxType { expense, income }

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  TxType _type = TxType.expense;
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  String? _category;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _date = picked);
  }

  // 🔥 ВАЖНО: async + await
  Future<void> _submit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok || _category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Категорияны таңдаңыз')),
      );
      return;
    }

    final amount =
        double.parse(_amountCtrl.text.replaceAll(',', '.'));

    final tx = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _type == TxType.income
          ? TransactionType.income
          : TransactionType.expense,
      amount: amount,
      category: _category!,
      date: _date,
      note: _noteCtrl.text,
    );

    try {
      // ⏳ ЖДЁМ сохранения в БД
      await context.read<AppState>().addTransaction(tx);

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<AppState>().categories;
    final dateText = DateFormat('dd.MM.yyyy').format(_date);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Транзакция қосу'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: SegmentedButton<TxType>(
                      segments: const [
                        ButtonSegment(
                          value: TxType.expense,
                          label: Text('Шығыс'),
                          icon: Icon(Icons.trending_down),
                        ),
                        ButtonSegment(
                          value: TxType.income,
                          label: Text('Кіріс'),
                          icon: Icon(Icons.trending_up),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (s) =>
                          setState(() => _type = s.first),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Сома (₸)',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return 'Соманы енгізіңіз';
                    final p =
                        double.tryParse(t.replaceAll(',', '.'));
                    if (p == null) return 'Дұрыс сан енгізіңіз';
                    if (p <= 0) return 'Сома 0-ден үлкен болсын';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: 'Категория',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v),
                ),
                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month),
                  label: Text('Күні: $dateText'),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Түсініктеме (қалауынша)',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check),
                  label: const Text('Сақтау'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
