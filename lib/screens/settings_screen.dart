import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../state/settings_state.dart';
import '../services/export_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _exportCsv(BuildContext context) async {
    final app = context.read<AppState>();
    final settings = context.read<SettingsState>();

    try {
      await ExportService.exportCsv(
        transactions: app.transactions,
        datePattern: settings.dateFormatPattern,
        filePrefix: 'finance_report',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Экспорт CSV выполнен')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Экспорт қате: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // THEME
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Тема',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<ThemeMode>(
                      initialValue: settings.themeMode,
                      decoration: const InputDecoration(labelText: 'Режим'),
                      items: const [
                        DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                        DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                        DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                      ],
                      onChanged: (v) {
                        if (v != null) settings.setThemeMode(v);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // CURRENCY
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Валюта',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: settings.currencySymbol,
                      decoration: const InputDecoration(labelText: 'Символ'),
                      items: const [
                        DropdownMenuItem(value: '₸', child: Text('₸  (KZT)')),
                        DropdownMenuItem(value: '\$', child: Text('\$  (USD)')),
                        DropdownMenuItem(value: '€', child: Text('€  (EUR)')),
                        DropdownMenuItem(value: '₽', child: Text('₽  (RUB)')),
                      ],
                      onChanged: (v) {
                        if (v != null) settings.setCurrencySymbol(v);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // DATE FORMAT
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Формат даты',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<DateFormatType>(
                      initialValue: settings.dateFormat,
                      decoration: const InputDecoration(labelText: 'Формат'),
                      items: const [
                        DropdownMenuItem(
                          value: DateFormatType.ddMMyyyy,
                          child: Text('dd.MM.yyyy'),
                        ),
                        DropdownMenuItem(
                          value: DateFormatType.yyyyMMdd,
                          child: Text('yyyy-MM-dd'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) settings.setDateFormat(v);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // EXPORT
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Экспорт',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _exportCsv(context),
                        icon: const Icon(Icons.download),
                        label: const Text('Экспортировать CSV'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'CSV файл: date,type,category,amount,note',
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
}
