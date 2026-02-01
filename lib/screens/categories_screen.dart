import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add(AppState state) {
    state.addCategory(_ctrl.text);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cats = state.categories;

    return Scaffold(
      appBar: AppBar(title: const Text('Категориялар')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      labelText: 'Жаңа категория',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _add(state),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () => _add(state),
                  child: const Text('Қосу'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.separated(
                itemCount: cats.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final c = cats[i];
                  final isSystem = state.isSystemCategory(c);

                  return ListTile(
                    title: Text(c),
                    subtitle: Text(isSystem ? 'System' : 'User'),
                    trailing: isSystem
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => state.removeUserCategory(c),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
