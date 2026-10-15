import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/library_view_model.dart';
import '../../data/services/reading_session_service.dart';
import '../widgets/daily_motivation_banner.dart';
import '../widgets/book_cover_widget.dart';
import 'book_detail_view.dart';
import 'reading_session_screen.dart';
import 'reading_challenge_view.dart';
import 'quotes_view.dart';
import 'settings_dialog.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LibraryViewModel>();
    final sessionService = context.watch<ReadingSessionService>();
    final primaryAccent = Theme.of(context).colorScheme.primary;

    final inProgressBooks = viewModel.books.where((b) => b.readPages > 0 && !b.isFinished).toList();
    final stats = viewModel.stats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Книжный Рай'),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_quote),
            tooltip: 'Цитаты',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const QuotesView()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Настройки',
            onPressed: () {
              showDialog(context: context, builder: (_) => const SettingsDialog());
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          // 1. Мотивационный баннер цитаты дня и прогресса цели года
          const DailyMotivationBanner(),

          // 2. Блок «Читаю сейчас»
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Читаю сейчас',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${inProgressBooks.length} книг',
                  style: TextStyle(color: primaryAccent, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          if (inProgressBooks.isEmpty)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.bookmark_outline, size: 36, color: primaryAccent.withOpacity(0.5)),
                      const SizedBox(height: 8),
                      const Text('Сейчас нет книг в процессе чтения'),
                      const SizedBox(height: 4),
                      Text(
                        'Выберите книгу из библиотеки, чтобы начать читать',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: inProgressBooks.length,
                itemBuilder: (context, index) {
                  final book = inProgressBooks[index];
                  return Container(
                    width: 300,
                    margin: const EdgeInsets.only(right: 12.0),
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => BookDetailView(book: book)),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              BookCoverWidget(
                                coverURL: book.cleanCoverURL,
                                title: book.title,
                                author: book.author,
                                width: 80,
                                height: 120,
                                cornerRadius: 8,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      book.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      book.author,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: book.progressPercentage,
                                        minHeight: 6,
                                        backgroundColor: primaryAccent.withOpacity(0.12),
                                        valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${book.readPages} / ${book.totalPages} стр. (${(book.progressPercentage * 100).toInt()}%)',
                                      style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      height: 32,
                                      child: FilledButton.tonalIcon(
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                        ),
                                        icon: const Icon(Icons.timer_outlined, size: 14),
                                        label: const Text('Сессия', style: TextStyle(fontSize: 11)),
                                        onPressed: () {
                                          sessionService.startSession(book.id, book.readPages);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => ReadingSessionScreen(book: book)),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          // 3. Сводка 2x2
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.8,
              children: [
                _statCard(context, 'В библиотеке', '${stats.totalBooks}', Icons.shelves, Colors.blue),
                _statCard(context, 'Прочитано', '${stats.readBooks}', Icons.check_circle, Colors.green),
                _statCard(context, 'В очереди', '${stats.plannedBooks}', Icons.schedule, Colors.orange),
                _statCard(context, 'Прочитано стр.', '${stats.totalPagesRead}', Icons.auto_stories, primaryAccent),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
