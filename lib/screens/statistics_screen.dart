import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../state/app_state.dart';
import '../state/settings_state.dart';
import '../models/transaction_model.dart';

enum StatsRange { week, month1, months3, months6, year1 }

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatsRange _range = StatsRange.month1;

  /// Любая дата внутри выбранного периода
  DateTime _anchor = DateTime.now();

  int? _touchedExpenseIndex;
  int? _touchedIncomeIndex;

  // -------------------- date helpers --------------------

  DateTime _startOfWeek(DateTime d) {
    final diff = d.weekday - DateTime.monday;
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: diff));
  }

  DateTime _startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  DateTime _addMonths(DateTime d, int months) {
    final y = d.year;
    final m = d.month + months;
    final newY = y + ((m - 1) ~/ 12);
    final newM = ((m - 1) % 12) + 1;
    return DateTime(newY, newM, 1);
  }

  int _monthSpan(StatsRange r) {
    switch (r) {
      case StatsRange.month1:
        return 1;
      case StatsRange.months3:
        return 3;
      case StatsRange.months6:
        return 6;
      case StatsRange.year1:
        return 12;
      case StatsRange.week:
        return 0;
    }
  }

  (DateTime from, DateTime to) _periodBounds() {
    if (_range == StatsRange.week) {
      final from = _startOfWeek(_anchor);
      final to = from.add(const Duration(days: 7));
      return (from, to);
    }

    final months = _monthSpan(_range);
    final from = _startOfMonth(_anchor);
    final to = _addMonths(from, months);
    return (from, to);
  }

  void _prevPeriod() {
    setState(() {
      _touchedExpenseIndex = null;
      _touchedIncomeIndex = null;

      if (_range == StatsRange.week) {
        _anchor = _anchor.subtract(const Duration(days: 7));
      } else {
        _anchor = _addMonths(_anchor, -_monthSpan(_range));
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      _touchedExpenseIndex = null;
      _touchedIncomeIndex = null;

      if (_range == StatsRange.week) {
        _anchor = _anchor.add(const Duration(days: 7));
      } else {
        _anchor = _addMonths(_anchor, _monthSpan(_range));
      }
    });
  }

  String _rangeLabel(StatsRange r) {
    switch (r) {
      case StatsRange.week:
        return 'Апта';
      case StatsRange.month1:
        return 'Ай';
      case StatsRange.months3:
        return '3 ай';
      case StatsRange.months6:
        return '6 ай';
      case StatsRange.year1:
        return '1 жыл';
    }
  }

  // -------------------- build --------------------

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final settings = context.watch<SettingsState>();

    final moneyFmt = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: settings.currencySymbol,
      decimalDigits: 0,
    );

    final dateFmt = DateFormat(settings.dateFormatPattern);

    final (from, to) = _periodBounds();
    final periodLabel = '${dateFmt.format(from)} — '
        '${dateFmt.format(to.subtract(const Duration(days: 1)))}';

    // =========================
    // EXPENSES (Шығыс)
    // =========================
    final expenses = state.transactions.where((t) {
      return t.type == TransactionType.expense &&
          !t.date.isBefore(from) &&
          t.date.isBefore(to);
    }).toList();

    final Map<String, double> expenseByCategory = {};
    for (final tx in expenses) {
      expenseByCategory[tx.category] =
          (expenseByCategory[tx.category] ?? 0) + tx.amount;
    }

    final expenseEntries = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final expenseTotal =
        expenseEntries.fold<double>(0, (sum, e) => sum + e.value);

    final expenseSliced = _slice(expenseEntries, maxSlices: 6);

    if (_touchedExpenseIndex != null &&
        (_touchedExpenseIndex! < 0 ||
            _touchedExpenseIndex! >= expenseSliced.length)) {
      _touchedExpenseIndex = null;
    }

    final expenseColors =
        _buildColors(context, expenseSliced.length, hueShift: 0);

    final selectedExpense = (_touchedExpenseIndex != null && expenseTotal > 0)
        ? expenseSliced[_touchedExpenseIndex!]
        : null;

    final selectedExpensePercent =
        (selectedExpense != null && expenseTotal > 0)
            ? (selectedExpense.value / expenseTotal) * 100
            : 0.0;

    // =========================
    // INCOME (Кіріс)
    // =========================
    final incomes = state.transactions.where((t) {
      return t.type == TransactionType.income &&
          !t.date.isBefore(from) &&
          t.date.isBefore(to);
    }).toList();

    final Map<String, double> incomeByCategory = {};
    for (final tx in incomes) {
      incomeByCategory[tx.category] =
          (incomeByCategory[tx.category] ?? 0) + tx.amount;
    }

    final incomeEntries = incomeByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final incomeTotal =
        incomeEntries.fold<double>(0, (sum, e) => sum + e.value);

    final incomeSliced = _slice(incomeEntries, maxSlices: 6);

    if (_touchedIncomeIndex != null &&
        (_touchedIncomeIndex! < 0 ||
            _touchedIncomeIndex! >= incomeSliced.length)) {
      _touchedIncomeIndex = null;
    }

    final incomeColors =
        _buildColors(context, incomeSliced.length, hueShift: 140);

    final selectedIncome = (_touchedIncomeIndex != null && incomeTotal > 0)
        ? incomeSliced[_touchedIncomeIndex!]
        : null;

    final selectedIncomePercent =
        (selectedIncome != null && incomeTotal > 0)
            ? (selectedIncome.value / incomeTotal) * 100
            : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Статистика')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Выбор диапазона
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: StatsRange.values.map((r) {
                final selected = r == _range;
                return ChoiceChip(
                  label: Text(_rangeLabel(r)),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _range = r;
                      _touchedExpenseIndex = null;
                      _touchedIncomeIndex = null;

                      if (_range == StatsRange.week) {
                        _anchor = _startOfWeek(_anchor);
                      } else {
                        _anchor = _startOfMonth(_anchor);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            // Навигация по периоду
            Row(
              children: [
                IconButton(
                  onPressed: _prevPeriod,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Алдыңғы',
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      periodLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _nextPeriod,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Келесі',
                ),
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // =======================
                    // ШЫҒЫС
                    // =======================
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Шығыс (диаграмма)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Жалпы: ${moneyFmt.format(expenseTotal)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (expenseTotal <= 0)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Text('Бұл кезеңде шығыс жоқ'),
                                ),
                              )
                            else ...[
                              _selectedInfoCard(
                                title:
                                    'Секторды басыңыз — шығыс туралы көрсетіледі.',
                                selected: selectedExpense,
                                selectedIndex: _touchedExpenseIndex,
                                colors: expenseColors,
                                moneyFmt: moneyFmt,
                                percent: selectedExpensePercent,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 270,
                                child: PieChart(
                                  PieChartData(
                                    centerSpaceRadius: 55,
                                    sectionsSpace: 2,
                                    pieTouchData: PieTouchData(
                                      touchCallback: (event, response) {
                                        if (response == null ||
                                            response.touchedSection == null) {
                                          if (event is FlTapUpEvent) {
                                            setState(() =>
                                                _touchedExpenseIndex = null);
                                          }
                                          return;
                                        }
                                        final idx = response.touchedSection!
                                            .touchedSectionIndex;
                                        if (event is FlTapUpEvent) {
                                          setState(() {
                                            _touchedExpenseIndex =
                                                (_touchedExpenseIndex == idx)
                                                    ? null
                                                    : idx;
                                          });
                                        }
                                      },
                                    ),
                                    sections: List.generate(expenseSliced.length,
                                        (i) {
                                      final e = expenseSliced[i];
                                      final percent =
                                          (e.value / expenseTotal) * 100;
                                      final isTouched =
                                          _touchedExpenseIndex == i;

                                      return PieChartSectionData(
                                        value: e.value,
                                        color: expenseColors[i],
                                        radius: isTouched ? 85 : 70,
                                        title: percent >= 8
                                            ? '${percent.toStringAsFixed(0)}%'
                                            : '',
                                        titleStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Легенда (түстер → категория)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ..._legendTiles(
                                sliced: expenseSliced,
                                colors: expenseColors,
                                total: expenseTotal,
                                moneyFmt: moneyFmt,
                                selectedIndex: _touchedExpenseIndex,
                                onTapIndex: (i) => setState(() {
                                  _touchedExpenseIndex =
                                      (_touchedExpenseIndex == i) ? null : i;
                                }),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // =======================
                    // КІРІС
                    // =======================
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Кіріс (диаграмма)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Жалпы: ${moneyFmt.format(incomeTotal)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (incomeTotal <= 0)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Text('Бұл кезеңде кіріс жоқ'),
                                ),
                              )
                            else ...[
                              _selectedInfoCard(
                                title:
                                    'Секторды басыңыз — кіріс туралы көрсетіледі.',
                                selected: selectedIncome,
                                selectedIndex: _touchedIncomeIndex,
                                colors: incomeColors,
                                moneyFmt: moneyFmt,
                                percent: selectedIncomePercent,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 270,
                                child: PieChart(
                                  PieChartData(
                                    centerSpaceRadius: 55,
                                    sectionsSpace: 2,
                                    pieTouchData: PieTouchData(
                                      touchCallback: (event, response) {
                                        if (response == null ||
                                            response.touchedSection == null) {
                                          if (event is FlTapUpEvent) {
                                            setState(() =>
                                                _touchedIncomeIndex = null);
                                          }
                                          return;
                                        }
                                        final idx = response.touchedSection!
                                            .touchedSectionIndex;
                                        if (event is FlTapUpEvent) {
                                          setState(() {
                                            _touchedIncomeIndex =
                                                (_touchedIncomeIndex == idx)
                                                    ? null
                                                    : idx;
                                          });
                                        }
                                      },
                                    ),
                                    sections: List.generate(incomeSliced.length,
                                        (i) {
                                      final e = incomeSliced[i];
                                      final percent =
                                          (e.value / incomeTotal) * 100;
                                      final isTouched =
                                          _touchedIncomeIndex == i;

                                      return PieChartSectionData(
                                        value: e.value,
                                        color: incomeColors[i],
                                        radius: isTouched ? 85 : 70,
                                        title: percent >= 8
                                            ? '${percent.toStringAsFixed(0)}%'
                                            : '',
                                        titleStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Легенда (түстер → категория)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ..._legendTiles(
                                sliced: incomeSliced,
                                colors: incomeColors,
                                total: incomeTotal,
                                moneyFmt: moneyFmt,
                                selectedIndex: _touchedIncomeIndex,
                                onTapIndex: (i) => setState(() {
                                  _touchedIncomeIndex =
                                      (_touchedIncomeIndex == i) ? null : i;
                                }),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    Text(
                      'Ескерту: категория көп болса, қосымша бөлігін "Other" біріктіреді.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- UI helpers ----------

  Widget _selectedInfoCard({
    required String title,
    required MapEntry<String, double>? selected,
    required int? selectedIndex,
    required List<Color> colors,
    required NumberFormat moneyFmt,
    required double percent,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: selected == null
          ? Card(
              key: const ValueKey('hint'),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(title),
              ),
            )
          : Card(
              key: const ValueKey('selected'),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[selectedIndex!],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        selected.key,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '${moneyFmt.format(selected.value)}  •  ${percent.toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _legendTiles({
    required List<MapEntry<String, double>> sliced,
    required List<Color> colors,
    required double total,
    required NumberFormat moneyFmt,
    required int? selectedIndex,
    required void Function(int i) onTapIndex,
  }) {
    return List.generate(sliced.length, (i) {
      final e = sliced[i];
      final percent = total > 0 ? (e.value / total) * 100 : 0.0;
      final isSelected = selectedIndex == i;

      return Card(
        elevation: isSelected ? 2 : 0,
        child: ListTile(
          onTap: () => onTapIndex(i),
          leading: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: colors[i],
              shape: BoxShape.circle,
            ),
          ),
          title: Text(
            e.key,
            style: TextStyle(fontWeight: isSelected ? FontWeight.bold : null),
          ),
          subtitle: Text('${percent.toStringAsFixed(1)}%'),
          trailing: Text(
            moneyFmt.format(e.value),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    });
  }

  // ---------- Data helpers ----------

  List<MapEntry<String, double>> _slice(
    List<MapEntry<String, double>> entries, {
    required int maxSlices,
  }) {
    final sliced = <MapEntry<String, double>>[];
    double otherSum = 0;

    for (var i = 0; i < entries.length; i++) {
      if (i < maxSlices) {
        sliced.add(entries[i]);
      } else {
        otherSum += entries[i].value;
      }
    }

    if (otherSum > 0) {
      sliced.add(MapEntry('Other', otherSum));
    }

    return sliced;
  }

  List<Color> _buildColors(
    BuildContext context,
    int n, {
    required double hueShift,
  }) {
    if (n <= 0) return const [];
    final base = Theme.of(context).colorScheme.primary;
    final baseHsl = HSLColor.fromColor(base);

    Color colorFor(int i) {
      final hue = (baseHsl.hue + hueShift + (360.0 / n) * i) % 360.0;
      return baseHsl
          .withHue(hue)
          .withSaturation(0.65)
          .withLightness(0.50)
          .toColor();
    }

    return List.generate(n, colorFor);
  }
}
