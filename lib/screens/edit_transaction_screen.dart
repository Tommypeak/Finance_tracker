import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../state/app_state.dart';

class EditTransactionScreen extends StatefulWidget {
  final TransactionModel tx;

  const EditTransactionScreen({super.key, required this.tx});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;

  late DateTime _date;
  String? _category;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.tx.amount.toStringAsFixed(2));
    _noteCtrl = TextEditingController(text: widget.tx.note);
    _date = widget.tx.date;
    _category = widget.tx.category;
  }

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

  Future<void> _save() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok || _category == null) return;

    final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));

    final updated = TransactionModel(
      id: widget.tx.id,
      type: widget.tx.type, // тип не меняем
      amount: amount,
      category: _category!,
      date: _date,
      note: _noteCtrl.text,
    );

    await context.read<AppState>().updateTransaction(updated);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<AppState>().categories;
    final dateText = DateFormat('dd.MM.yyyy').format(_date);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Түзету'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Сома (₸)',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return 'Соманы енгізіңіз';
                    final p = double.tryParse(t.replaceAll(',', '.'));
                    if (p == null) return 'Дұрыс сан енгізіңіз';
                    if (p <= 0) return 'Сома 0-ден үлкен болсын';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Категория',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
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
                  onPressed: _save,
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
