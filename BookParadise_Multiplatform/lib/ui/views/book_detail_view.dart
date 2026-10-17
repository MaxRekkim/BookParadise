import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/book.dart';
import '../../data/models/quote.dart';
import '../../data/services/reading_session_service.dart';
import '../../data/services/quotes_service.dart';
import '../../data/services/markdown_export_service.dart';
import '../../data/services/notes_service.dart';
import '../../data/models/reading_note.dart';
import '../view_models/library_view_model.dart';
import '../widgets/book_cover_widget.dart';
import 'reading_session_screen.dart';
import 'quotes_view.dart';
import 'markdown_editor_view.dart';

class BookDetailView extends StatefulWidget {
  final Book book;

  const BookDetailView({super.key, required this.book});

  @override
  State<BookDetailView> createState() => _BookDetailViewState();
}

class _BookDetailViewState extends State<BookDetailView> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LibraryViewModel>();
    final sessionService = context.watch<ReadingSessionService>();
    final book = viewModel.books.firstWhere((b) => b.id == widget.book.id, orElse: () => widget.book);
    final primaryAccent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        actions: [
          // Отправить на Kindle
          IconButton(
            icon: const Icon(Icons.send_to_mobile),
            tooltip: 'Отправить на Kindle',
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: 'Книга «${book.title}» (${book.author})',
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Данные книги скопированы для отправки на Kindle')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. Верхний блок: обложка и основная информация
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCoverWidget(
                coverURL: book.cleanCoverURL,
                title: book.title,
                author: book.author,
                width: 110,
                height: 160,
                cornerRadius: 12,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Chip(
                          label: Text(book.genre.title),
                          backgroundColor: book.genre.accentColor.withOpacity(0.12),
                          labelStyle: TextStyle(color: book.genre.accentColor, fontSize: 11),
                        ),
                        Chip(
                          label: Text(book.status.title),
                          backgroundColor: book.status.color.withOpacity(0.12),
                          labelStyle: TextStyle(color: book.status.color, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Прогресс чтения
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Прогресс чтения', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '${book.readPages} из ${book.totalPages} стр. (${(book.progressPercentage * 100).toInt()}%)',
                        style: TextStyle(fontWeight: FontWeight.bold, color: primaryAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: book.progressPercentage,
                      minHeight: 10,
                      backgroundColor: primaryAccent.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
                    ),
                  ),
                  if (!book.isFinished && book.remainingPages > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.hourglass_bottom, size: 15, color: Colors.orange),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'До финала: ${sessionService.formatEstimatedTime(book.remainingPages)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.orange),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Большая кнопка «Сессия чтения»
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.timer_outlined, size: 18),
                      label: const Text(
                        'Начать сессию чтения (Секундомер)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        sessionService.startSession(book.id, book.readPages);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ReadingSessionScreen(book: book)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Кнопки «Изменить страницы» и «В план бинго» СТРОГО ОДИНАКОВОГО размера
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text(
                              'Изменить страницы',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _showProgressDialog(context, viewModel, book),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_month, size: 16),
                            label: const Text(
                              'В план бинго',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _showPlanBingoDialog(context, viewModel, book),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Паспорт книги
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Паспорт книги', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (book.cycle != null && book.cycle!.isNotEmpty)
                    _passportRow('Цикл / Серия', '${book.cycle!} (книга ${book.cycleOrder ?? 1} из ${book.cycleTotal ?? 1})'),
                  _passportRow('Формат', book.format.title),
                  _passportRow('Размещение', book.shelfLocation.title),
                  if (book.rating != null && book.rating!.isNotEmpty)
                    _passportRow('Оценка', '★ ${book.rating!}'),
                  if (book.publisher != null && book.publisher!.isNotEmpty)
                    _passportRow('Издательство', book.publisher!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Впечатления и рецензия
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Мой отзыв и рецензия', style: TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.edit_note, size: 20),
                        onPressed: () => _showReviewDialog(context, viewModel, book),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (book.review != null && book.review!.trim().isNotEmpty)
                    Text(
                      book.review!,
                      style: const TextStyle(fontSize: 14, height: 1.4, fontStyle: FontStyle.italic),
                    )
                  else
                    Text(
                      'Вы ещё не оставили рецензию. Нажмите на иконку карандаша, чтобы записать впечатления о прочитанном.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4.5. Цитаты и заметки из книги (с персонализацией и карточками)
          _buildQuotesSection(context, book),
          const SizedBox(height: 16),

          // 4.6. Заметки и конспекты Markdown
          _buildNotesSection(context, book),
          const SizedBox(height: 16),

          // 6. Экспорт в Markdown (Obsidian / Notion)
          _buildMarkdownExportSection(context, book),
        ],
      ),
    );
  }

  Widget _passportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  void _showProgressDialog(BuildContext context, LibraryViewModel vm, Book book) {
    final controller = TextEditingController(text: '${book.readPages}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Обновить прогресс'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Прочитано страниц',
            suffixText: 'из ${book.totalPages}',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              final pages = int.tryParse(controller.text) ?? book.readPages;
              vm.updateProgress(book.id, pages);
              Navigator.pop(ctx);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showPlanBingoDialog(BuildContext context, LibraryViewModel vm, Book book) {
    const months = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    String selectedMonth = book.planMonth ?? months[DateTime.now().month - 1];
    final daysController = TextEditingController(text: '${book.planDays ?? 21}');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('В план чтения (Бинго)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Месяц для прочтения:', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedMonth,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedMonth = val);
                },
              ),
              const SizedBox(height: 14),
              const Text('Планируемый срок (дней):', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 6),
              TextField(
                controller: daysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixText: 'дн.',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                final days = int.tryParse(daysController.text) ?? 21;
                final updated = book.copyWith(
                  planMonth: selectedMonth,
                  planDays: days,
                );
                vm.updateBook(updated);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Книга «${book.title}» добавлена в план на $selectedMonth!')),
                );
              },
              child: const Text('В план'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewDialog(BuildContext context, LibraryViewModel vm, Book book) {
    final controller = TextEditingController(text: book.review ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Впечатления и рецензия'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Опишите ваши мысли о книге...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              vm.updateReview(book.id, controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  // MARK: - Секция Цитат и заметок
  Widget _buildQuotesSection(BuildContext context, Book book) {
    final quotesService = context.watch<QuotesService>();
    final bookQuotes = quotesService.quotes.where((q) => q.bookId == book.id).toList();
    final primaryAccent = Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.format_quote, color: primaryAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Цитаты и заметки (${bookQuotes.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Добавить', style: TextStyle(fontSize: 12)),
                  onPressed: () => _showAddQuoteDialog(context, book),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (bookQuotes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.edit_note, size: 36, color: Colors.grey.shade400),
                      const SizedBox(height: 6),
                      Text(
                        'Цитат из этой книги пока нет.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Нажмите «Добавить», чтобы сохранить понравившийся фрагмент или мысль.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bookQuotes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final q = bookQuotes[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => QuotePostcardSheet(quote: q, book: book),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (q.pageNumber != null && q.pageNumber! > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: primaryAccent.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Стр. ${q.pageNumber}',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryAccent),
                                  ),
                                ),
                              const Spacer(),
                              Icon(Icons.style_outlined, size: 14, color: Colors.grey.shade500),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '«${q.text}»',
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontStyle: FontStyle.italic,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                          if (q.note != null && q.note!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.sticky_note_2_outlined, size: 13, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    q.note!,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, Book book) {
    final notesService = context.watch<NotesService>();
    final bookNotes = notesService.notesForBook(book.id);
    final primaryAccent = Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit_note_rounded, color: primaryAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Заметки и конспекты (${bookNotes.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Создать', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MarkdownEditorView(initialBookId: book.id),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (bookNotes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.description_outlined, size: 36, color: Colors.grey.shade400),
                      const SizedBox(height: 6),
                      Text(
                        'Заметок по этой книге пока нет.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Создайте конспект, мысли по главам или цитатник в Markdown редакторе.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bookNotes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final note = bookNotes[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MarkdownEditorView(note: note),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  note.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (note.isPinned) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.push_pin, size: 14, color: Colors.amber),
                              ],
                              const SizedBox(width: 8),
                              Text(
                                '${note.wordCount} сл. · ~${note.readingTimeMinutes} мин',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            note.excerpt,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (note.tags.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: note.tags.map((t) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#$t',
                                  style: TextStyle(fontSize: 10, color: primaryAccent, fontWeight: FontWeight.w600),
                                ),
                              )).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAddQuoteDialog(BuildContext context, Book book) {
    final quotesService = context.read<QuotesService>();
    final textController = TextEditingController();
    final pageController = TextEditingController();
    final noteController = TextEditingController();
    bool hasNoteField = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Новая цитата'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Текст цитаты *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: textController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Введите цитату из книги...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Номер страницы:', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: pageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '42',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Возможность убирать/добавлять поле с заметкой
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Добавить личную заметку', style: TextStyle(fontSize: 13)),
                  value: hasNoteField,
                  onChanged: (val) {
                    setDialogState(() {
                      hasNoteField = val ?? false;
                      if (!hasNoteField) noteController.clear();
                    });
                  },
                ),
                if (hasNoteField) ...[
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Ваша личная мысль к цитате...',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        tooltip: 'Убрать поле заметки',
                        onPressed: () {
                          setDialogState(() {
                            hasNoteField = false;
                            noteController.clear();
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () async {
                final txt = textController.text.trim();
                if (txt.isEmpty) return;
                final page = int.tryParse(pageController.text.trim());
                final note = hasNoteField ? noteController.text.trim() : null;

                final quote = BookQuote(
                  id: 'quote_${DateTime.now().millisecondsSinceEpoch}',
                  bookId: book.id,
                  text: txt,
                  pageNumber: page,
                  note: (note != null && note.isNotEmpty) ? note : null,
                );

                await quotesService.addQuote(quote);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Цитата успешно добавлена!')),
                  );
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildMarkdownExportSection(BuildContext context, Book book) {
    final primaryAccent = Theme.of(context).colorScheme.primary;
    final quotesService = context.watch<QuotesService>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: primaryAccent, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Экспорт для заметок (Obsidian / Notion)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Создаёт готовую Markdown-заметку с YAML frontmatter, оценкой, статусом и сохраненными цитатами книги.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Скопировать Markdown (.md)'),
              onPressed: () {
                final md = MarkdownExportService.instance.exportBookToMarkdown(book, quotesService.quotes);
                Clipboard.setData(ClipboardData(text: md));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Markdown для Obsidian скопирован в буфер обмена!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
