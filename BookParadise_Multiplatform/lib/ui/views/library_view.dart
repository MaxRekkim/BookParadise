import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/book.dart';
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
          // Layout mode switcher (Grid / List / Bookshelf)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SegmentedButton<LibraryLayoutMode>(
              segments: const [
                ButtonSegment(
                  value: LibraryLayoutMode.grid,
                  icon: Icon(Icons.grid_view, size: 16),
                  tooltip: 'Сетка',
                ),
                ButtonSegment(
                  value: LibraryLayoutMode.list,
                  icon: Icon(Icons.view_list, size: 16),
                  tooltip: 'Список',
                ),
                ButtonSegment(
                  value: LibraryLayoutMode.bookshelf,
                  icon: Icon(Icons.table_rows, size: 16),
                  tooltip: 'Книжная полка',
                ),
              ],
              selected: {viewModel.layoutMode},
              onSelectionChanged: (val) => viewModel.setLayoutMode(val.first),
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(width: 4),

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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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

          // Main View depending on layoutMode
          Expanded(
            child: books.isEmpty
                ? const Center(child: Text('Книги не найдены'))
                : _buildContent(context, viewModel, books),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, LibraryViewModel viewModel, List<Book> books) {
    switch (viewModel.layoutMode) {
      case LibraryLayoutMode.grid:
        return _buildGridView(context, books);
      case LibraryLayoutMode.list:
        return _buildListView(context, books);
      case LibraryLayoutMode.bookshelf:
        return _buildBookshelfView(context, books);
    }
  }

  // 1. Grid Mode
  Widget _buildGridView(BuildContext context, List<Book> books) {
    return LayoutBuilder(
      builder: (context, constraints) {
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
    );
  }

  // 2. List Mode
  Widget _buildListView(BuildContext context, List<Book> books) {
    final primaryAccent = Theme.of(context).colorScheme.primary;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: books.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final book = books[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 6.0),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 44,
              height: 64,
              child: BookCoverWidget(
                coverURL: book.cleanCoverURL,
                title: book.title,
                author: book.author,
                width: 44,
                cornerRadius: 6,
              ),
            ),
          ),
          title: Text(
            book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      book.genre.title,
                      style: TextStyle(fontSize: 10, color: primaryAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${book.readPages} / ${book.totalPages} стр.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          trailing: book.rating != null && book.rating!.isNotEmpty
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 2),
                    Text(
                      book.rating!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                )
              : Icon(Icons.chevron_right, color: Colors.grey.shade400),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BookDetailView(book: book)),
            );
          },
        );
      },
    );
  }

  // 3. Bookshelf Spine Mode
  Widget _buildBookshelfView(BuildContext context, List<Book> books) {
    final chunks = _chunkBooks(books, 10);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      itemCount: chunks.length,
      itemBuilder: (context, index) {
        final shelfBooks = chunks[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: shelfBooks.map((b) => _BookSpineWidget(book: b)).toList(),
              ),
            ),
            _woodenShelfBeam(),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _woodenShelfBeam() {
    return Container(
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFB07238),
            Color(0xFF7A481F),
            Color(0xFF4A2B11),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            offset: const Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }

  List<List<Book>> _chunkBooks(List<Book> list, int size) {
    final chunks = <List<Book>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, (i + size > list.length) ? list.length : i + size));
    }
    return chunks;
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

// MARK: - Book Spine Widget
class _BookSpineWidget extends StatelessWidget {
  final Book book;

  const _BookSpineWidget({required this.book});

  @override
  Widget build(BuildContext context) {
    final width = (book.totalPages / 25).clamp(28.0, 56.0);
    final height = 165.0 + (book.id % 5) * 4.0;
    final gradientColors = _spineColors(book.genre);
    final isTopRated = book.rating == '5';
    final isReading = book.status == ReadingStatus.inProgress;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BookDetailView(book: book)),
          );
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Silk bookmark ribbon hanging out bottom
            if (isReading)
              Positioned(
                bottom: -10,
                child: Container(
                  width: 6,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC0392B),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),

            // Main Spine Body
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    gradientColors[0].withOpacity(0.95),
                    gradientColors[1],
                    gradientColors[1].withOpacity(0.85),
                    gradientColors[0],
                  ],
                  stops: const [0.0, 0.25, 0.75, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    offset: const Offset(1, 0),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Gold foil embossed lines top & bottom
                  Positioned(
                    top: 14,
                    left: 0,
                    right: 0,
                    child: _giltLine(),
                  ),
                  Positioned(
                    top: 18,
                    left: 0,
                    right: 0,
                    child: _giltLine(),
                  ),
                  Positioned(
                    bottom: 14,
                    left: 0,
                    right: 0,
                    child: _giltLine(),
                  ),
                  Positioned(
                    bottom: 18,
                    left: 0,
                    right: 0,
                    child: _giltLine(),
                  ),

                  // Top Crown for 5-star books
                  if (isTopRated)
                    const Positioned(
                      top: 4,
                      child: Text('👑', style: TextStyle(fontSize: 10)),
                    ),

                  // Vertical embossed title & author
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              book.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${book.author}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              shadows: const [
                                Shadow(
                                  color: Colors.black45,
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _giltLine() {
    return Container(
      height: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD4AF37).withOpacity(0.3),
            const Color(0xFFFFE082),
            const Color(0xFFD4AF37),
            const Color(0xFFD4AF37).withOpacity(0.3),
          ],
        ),
      ),
    );
  }

  List<Color> _spineColors(BookGenre genre) {
    switch (genre) {
      case BookGenre.prose:
        return [const Color(0xFF5E1924), const Color(0xFF8B2635)];
      case BookGenre.detective:
        return [const Color(0xFF24272D), const Color(0xFF3E434D)];
      case BookGenre.thriller:
        return [const Color(0xFF4A141A), const Color(0xFF7A1B24)];
      case BookGenre.psychology:
        return [const Color(0xFF2E1C38), const Color(0xFF4E3060)];
      case BookGenre.fantasy:
        return [const Color(0xFF143828), const Color(0xFF245740)];
      case BookGenre.ya:
        return [const Color(0xFF5C2344), const Color(0xFF8A3B69)];
      case BookGenre.classic:
        return [const Color(0xFF4E2C14), const Color(0xFF7A4521)];
      case BookGenre.nonfiction:
        return [const Color(0xFF0F324C), const Color(0xFF1E5B82)];
      case BookGenre.comics:
        return [const Color(0xFF6B3E14), const Color(0xFF9E5C1E)];
    }
  }
}
