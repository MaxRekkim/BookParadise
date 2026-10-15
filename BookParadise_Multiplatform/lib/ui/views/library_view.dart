import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/enums.dart';
import '../view_models/library_view_model.dart';
import '../widgets/book_cover_widget.dart';
import 'book_detail_view.dart';
import 'filter_bottom_sheet.dart';

class LibraryView extends StatelessWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LibraryViewModel>();
    final primaryAccent = Theme.of(context).colorScheme.primary;
    final books = viewModel.filteredBooks;

    return Scaffold(
      appBar: AppBar(
        title: Text('Библиотека (${books.length})'),
        actions: [
          // Filter Funnel Button with count badge
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Фильтры',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const FilterBottomSheet(),
                  );
                },
              ),
              if (viewModel.filterCriteria.isActive)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: primaryAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${viewModel.filterCriteria.activeCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: SearchBar(
              hintText: 'Поиск по названию, автору или циклу...',
              leading: const Icon(Icons.search),
              onChanged: (val) => viewModel.setSearchQuery(val),
            ),
          ),

          // Genre chips row
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: const Text('Все'),
                    selected: viewModel.selectedGenre == null,
                    onSelected: (_) => viewModel.setGenreFilter(null),
                  ),
                ),
                ...BookGenre.values.map((genre) {
                  final isSelected = viewModel.selectedGenre == genre;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(genre.title),
                      selected: isSelected,
                      onSelected: (_) => viewModel.setGenreFilter(isSelected ? null : genre),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Removable active filter tags
          if (viewModel.filterCriteria.isActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    InputChip(
                      label: const Text('Сбросить все'),
                      avatar: const Icon(Icons.refresh, size: 16),
                      onPressed: () {
                        viewModel.filterCriteria.reset();
                        // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
                        viewModel.notifyListeners();
                      },
                    ),
                    const SizedBox(width: 8),
                    if (viewModel.filterCriteria.status != null)
                      _filterPill(viewModel.filterCriteria.status!.title, () {
                        viewModel.filterCriteria.status = null;
                        // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
                        viewModel.notifyListeners();
                      }),
                    if (viewModel.filterCriteria.format != null)
                      _filterPill(viewModel.filterCriteria.format!.title, () {
                        viewModel.filterCriteria.format = null;
                        // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
                        viewModel.notifyListeners();
                      }),
                    if (viewModel.filterCriteria.onlyWithKindleFile)
                      _filterPill('Только с файлом', () {
                        viewModel.filterCriteria.onlyWithKindleFile = false;
                        // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
                        viewModel.notifyListeners();
                      }),
                  ],
                ),
              ),
            ),

          // Adaptive Responsive Grid
          Expanded(
            child: books.isEmpty
                ? const Center(child: Text('Книги не найдены'))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // 3 columns on mobile, 4-6 on desktop
                      final cols = constraints.maxWidth > 900
                          ? 6
                          : constraints.maxWidth > 600
                              ? 4
                              : 3;

                      return GridView.builder(
                        padding: const EdgeInsets.all(16.0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          childAspectRatio: 0.60,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final book = books[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => BookDetailView(book: book)),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: BookCoverWidget(
                                    coverURL: book.cleanCoverURL,
                                    title: book.title,
                                    author: book.author,
                                    width: double.infinity,
                                    cornerRadius: 10,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  book.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  book.author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterPill(String label, VoidCallback onDeleted) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        deleteIcon: const Icon(Icons.close, size: 14),
        onDeleted: onDeleted,
      ),
    );
  }
}
