import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/library_view_model.dart';
import '../widgets/book_cover_widget.dart';
import 'book_detail_view.dart';

class BingoView extends StatefulWidget {
  const BingoView({super.key});

  @override
  State<BingoView> createState() => _BingoViewState();
}

class _BingoViewState extends State<BingoView> {
  static const months = [
    'ИЮНЬ', 'ИЮЛЬ', 'АВГУСТ', 'СЕНТЯБРЬ', 'ОКТЯБРЬ', 'НОЯБРЬ',
    'ДЕКАБРЬ', 'ЯНВАРЬ', 'ФЕВРАЛЬ', 'МАРТ', 'АПРЕЛЬ', 'МАЙ', 'ЗАБРОШЕНО'
  ];

  String _selectedMonth = 'ОКТЯБРЬ';

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LibraryViewModel>();
    final items = viewModel.bingoItems.where((i) => i.planMonth.toUpperCase() == _selectedMonth).toList();
    final primaryAccent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Планы и Бинго'),
      ),
      body: Column(
        children: [
          // Month picker chips
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: months.length,
              itemBuilder: (context, index) {
                final m = months[index];
                final isSelected = m == _selectedMonth;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(m),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedMonth = m),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 48, color: primaryAccent.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text('В плане на $_selectedMonth нет книг'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final book = viewModel.books.firstWhere((b) => b.id == item.id, orElse: () => viewModel.books.first);

                      return Dismissible(
                        key: Key('bingo_${item.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => viewModel.removeFromBingo(item),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          child: ListTile(
                            leading: BookCoverWidget(
                              coverURL: item.coverURL,
                              title: item.title,
                              author: item.author,
                              width: 40,
                              height: 56,
                            ),
                            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text('${item.author} • ${item.readPages}/${item.totalPages} стр.'),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                              tooltip: 'Удалить из плана',
                              onPressed: () => viewModel.removeFromBingo(item),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => BookDetailView(book: book)),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
