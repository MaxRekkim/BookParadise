import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/library_view_model.dart';
import '../widgets/book_cover_widget.dart';
import 'book_detail_view.dart';

class CyclesView extends StatelessWidget {
  const CyclesView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LibraryViewModel>();
    final cycles = viewModel.cycles;
    final primaryAccent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Книжные циклы (${cycles.length})'),
      ),
      body: cycles.isEmpty
          ? const Center(child: Text('Циклы не найдены'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: cycles.length,
              itemBuilder: (context, index) {
                final cycle = cycles[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: ExpansionTile(
                    shape: const Border(),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cycle.isCompleted
                            ? Colors.green.withOpacity(0.12)
                            : primaryAccent.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        cycle.isCompleted ? Icons.check_circle : Icons.bookmarks,
                        color: cycle.isCompleted ? Colors.green : primaryAccent,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      cycle.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: Text(
                      'Прочитано ${cycle.readBooks} из ${cycle.totalBooks} книг (${(cycle.progress * 100).toInt()}%)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    children: [
                      const Divider(height: 1),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cycle.books.length,
                        itemBuilder: (ctx, bIdx) {
                          final book = cycle.books[bIdx];
                          return ListTile(
                            leading: BookCoverWidget(
                              coverURL: book.cleanCoverURL,
                              title: book.title,
                              author: book.author,
                              width: 36,
                              height: 50,
                            ),
                            title: Text(book.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text('Книга #${book.cycleOrder ?? (bIdx + 1)} • ${book.readPages}/${book.totalPages} стр.'),
                            trailing: book.isFinished
                                ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                                : null,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => BookDetailView(book: book)),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
