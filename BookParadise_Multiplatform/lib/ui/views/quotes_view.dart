import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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

class _QuotePostcardSheet extends StatefulWidget {
  final BookQuote quote;
  final dynamic book;

  const _QuotePostcardSheet({required this.quote, required this.book});

  @override
  State<_QuotePostcardSheet> createState() => _QuotePostcardSheetState();
}

class _QuotePostcardSheetState extends State<_QuotePostcardSheet> {
  int _selectedThemeIndex = 0;
  late bool _showNote;

  final List<Map<String, dynamic>> _themes = const [
    {
      'title': 'Пергамент',
      'bg': Color(0xFFF7F4EC),
      'ink': Color(0xFF1C1814),
      'sub': Color(0xFF443834),
      'accent': Color(0xFFB45309),
      'noteBg': Color(0xFFECE6D8),
      'border': Color(0xFFDDD4C2),
    },
    {
      'title': 'Полночь',
      'bg': Color(0xFF151922),
      'ink': Color(0xFFF2F4F8),
      'sub': Color(0xFFB8C1D1),
      'accent': Color(0xFF60A5FA),
      'noteBg': Color(0xFF1F2636),
      'border': Color(0xFF2C364D),
    },
    {
      'title': 'Лаванда',
      'bg': Color(0xFFF5EFFB),
      'ink': Color(0xFF281838),
      'sub': Color(0xFF4A3561),
      'accent': Color(0xFF8B5CF6),
      'noteBg': Color(0xFFE8DEF4),
      'border': Color(0xFFD5C4EC),
    },
    {
      'title': 'Изумруд',
      'bg': Color(0xFFEDF5F0),
      'ink': Color(0xFF12261A),
      'sub': Color(0xFF244531),
      'accent': Color(0xFF10B981),
      'noteBg': Color(0xFFD9EBE0),
      'border': Color(0xFFC4DECE),
    },
    {
      'title': 'Кофе',
      'bg': Color(0xFFF3EBE1),
      'ink': Color(0xFF2C1E14),
      'sub': Color(0xFF4E382A),
      'accent': Color(0xFF92400E),
      'noteBg': Color(0xFFE4D7C8),
      'border': Color(0xFFD3BEA8),
    },
    {
      'title': 'Монохром',
      'bg': Color(0xFFFFFFFF),
      'ink': Color(0xFF111827),
      'sub': Color(0xFF374151),
      'accent': Color(0xFF4B5563),
      'noteBg': Color(0xFFF3F4F6),
      'border': Color(0xFFE5E7EB),
    },
  ];

  @override
  void initState() {
    super.initState();
    _showNote = widget.quote.note != null && widget.quote.note!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final curTheme = _themes[_selectedThemeIndex];
    final Color bgColor = curTheme['bg'] as Color;
    final Color inkColor = curTheme['ink'] as Color;
    final Color subColor = curTheme['sub'] as Color;
    final Color accentColor = curTheme['accent'] as Color;
    final Color noteBg = curTheme['noteBg'] as Color;
    final Color borderColor = curTheme['border'] as Color;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
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

            // High contrast physical literary postcard
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
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
                      Icon(Icons.format_quote, color: accentColor, size: 32),
                      if (widget.quote.pageNumber != null && widget.quote.pageNumber! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Стр. ${widget.quote.pageNumber}',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '«${widget.quote.text}»',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                      color: inkColor,
                    ),
                  ),
                  if (_showNote && widget.quote.note != null && widget.quote.note!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: noteBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.quote.note!,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: subColor,
                        ),
                      ),
                    ),
                  ],
                  Divider(height: 28, color: borderColor),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.book.author.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: subColor,
                              letterSpacing: 0.6,
                            ),
                          ),
                          Text(
                            widget.book.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: inkColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Книжный Рай',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Theme selector chips
            const Text(
              'ТЕМА ОФОРМЛЕНИЯ',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _themes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final t = _themes[index];
                  final isSelected = _selectedThemeIndex == index;
                  return ChoiceChip(
                    label: Text(t['title'] as String),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedThemeIndex = index);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Note toggle
            if (widget.quote.note != null && widget.quote.note!.isNotEmpty) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Показывать заметку на открытке', style: TextStyle(fontSize: 13)),
                value: _showNote,
                onChanged: (val) => setState(() => _showNote = val),
              ),
            ],

            const SizedBox(height: 14),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Поделиться'),
                    onPressed: () {
                      String text = '«${widget.quote.text}» — ${widget.book.author}, «${widget.book.title}»';
                      if (_showNote && widget.quote.note != null && widget.quote.note!.isNotEmpty) {
                        text += '\nЗаметка: ${widget.quote.note}';
                      }
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Текст цитаты скопирован для отправки')),
                      );
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
                        text: '«${widget.quote.text}» — ${widget.book.author}, «${widget.book.title}»',
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
