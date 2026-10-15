import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/enums.dart';
import '../view_models/library_view_model.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LibraryViewModel>();
    final criteria = viewModel.filterCriteria;
    final matchCount = viewModel.filteredBooks.length;
    final primaryAccent = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    criteria.reset();
                  });
                },
                child: const Text('Сбросить'),
              ),
              const Text('Фильтры', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),

          Expanded(
            child: ListView(
              children: [
                // 1. Статус чтения
                _sectionTitle('СТАТУС ЧТЕНИЯ'),
                Wrap(
                  spacing: 8,
                  children: ReadingStatus.values.map((s) {
                    final selected = criteria.status == s;
                    return ChoiceChip(
                      label: Text(s.title),
                      selected: selected,
                      onSelected: (val) {
                        setState(() {
                          criteria.status = val ? s : null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // 2. Формат
                _sectionTitle('ФОРМАТ И ФАЙЛЫ'),
                Wrap(
                  spacing: 8,
                  children: BookFormat.values.map((f) {
                    final selected = criteria.format == f;
                    return ChoiceChip(
                      label: Text(f.title),
                      selected: selected,
                      onSelected: (val) {
                        setState(() {
                          criteria.format = val ? f : null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Только с файлом (Kindle / Оффлайн)', style: TextStyle(fontSize: 14)),
                  value: criteria.onlyWithKindleFile,
                  onChanged: (val) {
                    setState(() {
                      criteria.onlyWithKindleFile = val;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // 3. Жанры
                _sectionTitle('ЖАНРЫ'),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: BookGenre.values.map((g) {
                    final selected = criteria.genres.contains(g);
                    return FilterChip(
                      label: Text(g.title),
                      selected: selected,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            criteria.genres.add(g);
                          } else {
                            criteria.genres.remove(g);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // 4. Оценка
                _sectionTitle('ОЦЕНКА'),
                Wrap(
                  spacing: 8,
                  children: [5, 4, 3, 2, 1].map((r) {
                    final selected = criteria.rating == r;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('$r'),
                        ],
                      ),
                      selected: selected,
                      onSelected: (val) {
                        setState(() {
                          criteria.rating = val ? r : null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // 5. Циклы
                _sectionTitle('ЦИКЛЫ'),
                Wrap(
                  spacing: 8,
                  children: CycleFilterMode.values.map((m) {
                    final selected = criteria.cycleMode == m;
                    return ChoiceChip(
                      label: Text(m.title),
                      selected: selected,
                      onSelected: (val) {
                        setState(() {
                          criteria.cycleMode = val ? m : CycleFilterMode.all;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // 6. Объём страниц
                _sectionTitle('ОБЪЁМ СТРАНИЦ'),
                Wrap(
                  spacing: 8,
                  children: PageRangeFilter.values.map((p) {
                    final selected = criteria.pageRange == p;
                    return ChoiceChip(
                      label: Text(p.title),
                      selected: selected,
                      onSelected: (val) {
                        setState(() {
                          criteria.pageRange = val ? p : PageRangeFilter.all;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Bottom live counter button
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Показать $matchCount книг',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
