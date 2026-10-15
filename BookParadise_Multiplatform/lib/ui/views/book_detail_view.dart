import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/book.dart';
import '../../data/services/reading_session_service.dart';
import '../view_models/library_view_model.dart';
import '../widgets/book_cover_widget.dart';
import 'reading_session_screen.dart';

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
              Share.share('Книга «${book.title}» (${book.author}) готова к отправке на Kindle.');
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
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Обновить прогресс'),
                          onPressed: () => _showProgressDialog(context, viewModel, book),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        icon: const Icon(Icons.timer_outlined, size: 16),
                        label: const Text('Сессия'),
                        onPressed: () {
                          sessionService.startSession(book.id, book.readPages);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ReadingSessionScreen(book: book)),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Паспорт книги (Чистые заголовки БЕЗ букв столбцов таблицы A, D, E)
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
}
