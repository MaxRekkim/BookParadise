import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/library_view_model.dart';
import '../../data/models/enums.dart';
import '../../data/services/reading_session_service.dart';
import '../../data/services/lending_service.dart';
import '../widgets/daily_motivation_banner.dart';
import '../widgets/book_cover_widget.dart';
import 'book_detail_view.dart';
import 'reading_session_screen.dart';
import 'reading_challenge_view.dart';
import 'library_view.dart';
import 'quotes_view.dart';
import 'settings_dialog.dart';
import 'lending_list_screen.dart';
import 'achievements_screen.dart';
import 'book_oracle_screen.dart';
import 'reading_wrapped_screen.dart';
import '../widgets/time_capsule_card.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LibraryViewModel>();
    final sessionService = context.watch<ReadingSessionService>();
    final lendingService = context.watch<LendingService>();
    final primaryAccent = Theme.of(context).colorScheme.primary;

    final inProgressBooks = viewModel.books.where((b) => b.readPages > 0 && !b.isFinished).toList();
    final stats = viewModel.stats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Книжный Рай'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.purple),
            tooltip: 'Книжный Оракул-Сомелье',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BookOracleScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined, color: Colors.amber),
            tooltip: 'Трофеи и стрики',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsScreen()));
            },
          ),
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

          // 1.2. Капсула Времени (Литературные воспоминания)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: TimeCapsuleCard(),
          ),

          // 1.3. Баннер Книжного Оракула-Сомелье
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Card(
              color: Colors.purple.withOpacity(0.06),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.purple.withOpacity(0.2)),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.purple, size: 20),
                ),
                title: const Row(
                  children: [
                    Text('Книжный Оракул-Сомелье', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(width: 6),
                    Badge(label: Text('NEW', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
                  ],
                ),
                subtitle: const Text('Подбор книги по времени и настроению или жребий', style: TextStyle(fontSize: 12, color: Colors.grey)),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BookOracleScreen()));
                },
              ),
            ),
          ),

          // 1.5. Баннер книг у друзей (если есть активные записи)
          if (lendingService.activeRecords.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                color: Colors.orange.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.orange.withOpacity(0.3)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.people_alt, color: Colors.orange),
                  title: Text(
                    'Книги у друзей: ${lendingService.activeRecords.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    lendingService.overdueRecords.isNotEmpty
                        ? '⚠️ Просрочено к возврату: ${lendingService.overdueRecords.length}'
                        : 'Все одолженные книги под контролем',
                    style: TextStyle(
                      fontSize: 12,
                      color: lendingService.overdueRecords.isNotEmpty ? Colors.red : Colors.grey,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LendingListScreen()),
                    );
                  },
                ),
              ),
            ),

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
                                      '${book.readPages} / ${book.totalPages} стр. • ${sessionService.formatEstimatedTime(book.remainingPages)}',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
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
                _statCard(
                  context,
                  'В библиотеке',
                  '${stats.totalBooks}',
                  Icons.shelves,
                  Colors.blue,
                  () {
                    viewModel.clearFilters();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LibraryView()),
                    );
                  },
                ),
                _statCard(
                  context,
                  'Прочитано',
                  '${stats.readBooks}',
                  Icons.check_circle,
                  Colors.green,
                  () {
                    viewModel.setStatusFilter(ReadingStatus.completed);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LibraryView()),
                    );
                  },
                ),
                _statCard(
                  context,
                  'В очереди',
                  '${stats.plannedBooks}',
                  Icons.schedule,
                  Colors.orange,
                  () {
                    viewModel.setStatusFilter(ReadingStatus.planned);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LibraryView()),
                    );
                  },
                ),
                _statCard(
                  context,
                  'Темп чтения',
                  '${stats.totalPagesRead} стр.',
                  Icons.bolt,
                  primaryAccent,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReadingChallengeView()),
                    );
                  },
                ),
              ],
            ),
          ),

          // 4. Баннер Reading Wrapped
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Card(
              color: Colors.orange.withOpacity(0.06),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.orange.withOpacity(0.2)),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shelves, color: Colors.orange, size: 20),
                ),
                title: const Text('Reading Wrapped • Книжные итоги', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Высота книжной башни, темпоритм и открытка для соцсетей', style: TextStyle(fontSize: 12, color: Colors.grey)),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ReadingWrappedScreen()));
                },
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
