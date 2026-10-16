import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/quotes_service.dart';
import '../view_models/library_view_model.dart';
import '../views/book_detail_view.dart';

class TimeCapsuleCard extends StatelessWidget {
  const TimeCapsuleCard({super.key});

  @override
  Widget build(BuildContext context) {
    final quotesService = context.watch<QuotesService>();
    final libraryVM = context.watch<LibraryViewModel>();
    final primaryAccent = Theme.of(context).colorScheme.primary;

    if (quotesService.quotes.isEmpty) {
      return const SizedBox.shrink();
    }

    // Ищем подходящее воспоминание
    final now = DateTime.now();
    var match = quotesService.quotes.where((q) => q.date.month == now.month && q.date.day == now.day).firstOrNull;
    match ??= quotesService.quotes.first;

    final book = libraryVM.books.firstWhere((b) => b.id == match!.bookId, orElse: () => libraryVM.books.first);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, size: 18, color: primaryAccent),
                const SizedBox(width: 6),
                Text(
                  'КАПСУЛА ВРЕМЕНИ • ВОСПОМИНАНИЕ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: primaryAccent,
                  ),
                ),
                const Spacer(),
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BookDetailView(book: book)),
                    );
                  },
                  child: const Text('К книге', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '«${match.text}»',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              '${book.title} — ${book.author}${match.pageNumber != null ? ' • стр. ${match.pageNumber}' : ''}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
