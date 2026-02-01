import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../state/settings_state.dart';
import '../models/transaction_model.dart';
import 'edit_transaction_screen.dart';
import 'settings_screen.dart';

enum TxFilter { all, income, expense }
enum TxSort { dateDesc, dateAsc, amountDesc, amountAsc }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  TxFilter _filter = TxFilter.all;
  TxSort _sort = TxSort.dateDesc;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<TransactionModel> _apply(List<TransactionModel> input) {
    final q = _searchCtrl.text.trim().toLowerCase();
    Iterable<TransactionModel> out = input;

    if (_filter == TxFilter.income) {
      out = out.where((t) => t.type == TransactionType.income);
    } else if (_filter == TxFilter.expense) {
      out = out.where((t) => t.type == TransactionType.expense);
    }

    if (q.isNotEmpty) {
      out = out.where((t) =>
          t.category.toLowerCase().contains(q) ||
          t.note.toLowerCase().contains(q));
    }

    final list = out.toList();
    switch (_sort) {
      case TxSort.dateDesc:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case TxSort.dateAsc:
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case TxSort.amountDesc:
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case TxSort.amountAsc:
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final settings = context.watch<SettingsState>();
    final cur = settings.currencySymbol;

    final txs = _apply(app.transactions);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Басты бет'),
        actions: [
          _IconBox(
            icon: Icons.settings,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () => context.read<AppState>().loadFromDb(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
          children: [
            // Баланс + счётчики
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Баланс',
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${app.balance.toStringAsFixed(0)} $cur',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                            title: 'Кіріс',
                            value:
                                '${app.totalIncome.toStringAsFixed(0)} $cur',
                            icon: Icons.trending_up,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatBox(
                            title: 'Шығыс',
                            value:
                                '${app.totalExpense.toStringAsFixed(0)} $cur',
                            icon: Icons.trending_down,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Поиск
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Іздеу',
                prefixIcon: const _IconBox.small(icon: Icons.search),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : _IconBox.small(
                        icon: Icons.close,
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      ),
              ),
            ),

            const SizedBox(height: 10),

            // Фильтры
            Wrap(
              spacing: 8,
              children: [
                _FilterChip(
                  text: 'Барлығы',
                  selected: _filter == TxFilter.all,
                  onTap: () => setState(() => _filter = TxFilter.all),
                ),
                _FilterChip(
                  text: 'Кіріс',
                  selected: _filter == TxFilter.income,
                  onTap: () => setState(() => _filter = TxFilter.income),
                ),
                _FilterChip(
                  text: 'Шығыс',
                  selected: _filter == TxFilter.expense,
                  onTap: () => setState(() => _filter = TxFilter.expense),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (txs.isEmpty)
              const _EmptyState()
            else
              ...txs.map(
                (tx) => _DismissibleTxTile(
                  tx: tx,
                  currency: cur,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/* -------------------- UI HELPERS -------------------- */

class _DismissibleTxTile extends StatelessWidget {
  final TransactionModel tx;
  final String currency;

  const _DismissibleTxTile({
    required this.tx,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.red;
    final sign = isIncome ? '+' : '-';

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 18),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Жою керек пе?'),
            content: const Text('Бұл транзакцияны қайтару мүмкін емес'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Жоқ'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Иә'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        context.read<AppState>().deleteTransaction(tx);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EditTransactionScreen(tx: tx),
              ),
            );
          },
          leading: _IconBox(
            icon: isIncome ? Icons.trending_up : Icons.trending_down,
          ),
          title: Text(
            tx.category,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(tx.note.isEmpty ? '—' : tx.note),
          trailing: Text(
            '$sign${tx.amount.toStringAsFixed(0)} $currency',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  const _IconBox({
    required this.icon,
    this.onTap,
    this.size = 40,
  });

  const _IconBox.small({
    required this.icon,
    this.onTap,
  }) : size = 36;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: scheme.primary),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _IconBox(icon: icon, size: 42),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w900)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.18)
              : scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: const [
            _IconBox(icon: Icons.receipt_long),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Транзакция табылмады',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
