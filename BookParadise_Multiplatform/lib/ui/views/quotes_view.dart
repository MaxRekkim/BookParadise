import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/quote.dart';
import '../../data/services/quotes_service.dart';
import '../view_models/library_view_model.dart';
import '../widgets/book_cover_widget.dart';

class QuotesView extends StatefulWidget {
  const QuotesView({super.key});

  @override
  State<QuotesView> createState() => _QuotesViewState();
}

class _QuotesViewState extends State<QuotesView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final quotesService = context.watch<QuotesService>();
    final libraryVM = context.watch<LibraryViewModel>();

    var filtered = quotesService.quotes;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      filtered = filtered.where((item) =>
          item.text.toLowerCase().contains(q) ||
          (item.note?.toLowerCase().contains(q) ?? false)).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Цитаты и заметки (${quotesService.quotes.length})'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SearchBar(
              hintText: 'Поиск по цитатам...',
              leading: const Icon(Icons.search),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Цитат пока нет'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final quote = filtered[index];
                      final book = libraryVM.books.firstWhere(
                        (b) => b.id == quote.bookId,
                        orElse: () => libraryVM.books.first,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _openQuotePostcard(context, quote, book),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    BookCoverWidget(
                                      coverURL: book.cleanCoverURL,
                                      title: book.title,
                                      author: book.author,
                                      width: 36,
                                      height: 50,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            book.title,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Text(
                                            book.author,
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20),
                                      onPressed: () => quotesService.deleteQuote(quote.id),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Text(
                                  '«${quote.text}»',
                                  style: const TextStyle(
                                    fontFamily: 'serif',
                                    fontStyle: FontStyle.italic,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                                if (quote.note != null && quote.note!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_note, size: 16, color: Theme.of(context).colorScheme.secondary),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            quote.note!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                              color: Theme.of(context).textTheme.bodySmall?.color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
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

  void _openQuotePostcard(BuildContext context, BookQuote quote, dynamic book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _QuotePostcardSheet(quote: quote, book: book),
    );
  }
}

class _QuotePostcardSheet extends StatelessWidget {
  final BookQuote quote;
  final dynamic book;

  const _QuotePostcardSheet({required this.quote, required this.book});

  @override
  Widget build(BuildContext context) {
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
          // Single reliable top-right "Готово" button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Цитата из книги',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Готово', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // High contrast physical literary postcard (Dark ink on light parchment)
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2), // Light cream parchment
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: primaryAccent.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.format_quote, color: primaryAccent, size: 32),
                    if (quote.pageNumber != null && quote.pageNumber! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Стр. ${quote.pageNumber}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // Deep typographical dark ink
                Text(
                  '«${quote.text}»',
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                    color: Color(0xFF231F1D), // Dark ink
                  ),
                ),
                if (quote.note != null && quote.note!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFECE6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      quote.note!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF4A4441),
                      ),
                    ),
                  ),
                ],
                const Divider(height: 28, color: Color(0xFFDED9D2)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.author.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF756D68),
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          book.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF231F1D),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Книжный Рай',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: primaryAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Поделиться'),
                  onPressed: () {
                    Share.share('«${quote.text}» — ${book.author}, «${book.title}»');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Копировать текст'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                      text: '«${quote.text}» — ${book.author}, «${book.title}»',
                    ));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Цитата скопирована в буфер')),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
