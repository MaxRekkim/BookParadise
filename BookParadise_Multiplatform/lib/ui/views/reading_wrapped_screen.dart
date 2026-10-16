import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/book.dart';
import '../../data/models/enums.dart';
import '../../data/services/reading_session_service.dart';
import '../../data/services/quotes_service.dart';
import '../view_models/library_view_model.dart';

class ReadingWrappedScreen extends StatelessWidget {
  const ReadingWrappedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryViewModel>();
    final sessionService = context.watch<ReadingSessionService>();
    final quotesService = context.watch<QuotesService>();
    final primaryAccent = Theme.of(context).colorScheme.primary;

    final completedBooks = lib.books.where((b) => b.status == ReadingStatus.completed).toList();
    final totalPagesRead = completedBooks.fold<int>(0, (sum, b) => sum + b.totalPages) +
        lib.books.where((b) => b.status == ReadingStatus.reading).fold<int>(0, (sum, b) => sum + b.pagesRead);

    final towerHeightCm = (totalPagesRead * 0.008) + (completedBooks.length * 0.4);
    final towerRounded = (towerHeightCm * 10).round() / 10.0;

    String comparisonText;
    if (towerRounded < 8) {
      comparisonText = 'Высота чашки эспрессо ☕️';
    } else if (towerRounded < 20) {
      comparisonText = 'Высота плюшевого медвежонка 🧸';
    } else if (towerRounded < 38) {
      comparisonText = 'Высота пушистого кота 🐈';
    } else if (towerRounded < 60) {
      comparisonText = 'Высота журнального столика 🛋️';
    } else {
      comparisonText = 'Настоящий книжный небоскрёб! 🗼';
    }

    final secs = sessionService.totalReadingSeconds;
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final timeStr = h > 0 ? '$h ч $m мин' : '$m мин';

    // Top Genre
    final genreCounts = <BookGenre, int>{};
    for (final b in completedBooks) {
      genreCounts[b.genre] = (genreCounts[b.genre] ?? 0) + 1;
    }
    BookGenre? topGenre;
    int maxG = 0;
    genreCounts.forEach((genre, count) {
      if (count > maxG) {
        maxG = count;
        topGenre = genre;
      }
    });
    final topGenrePct = completedBooks.isNotEmpty && topGenre != null
        ? ((maxG / completedBooks.length) * 100).round()
        : 0;

    final goldenQuote = quotesService.quotes.firstOrNull;

    final shareText = '''
📚 Мои книжные итоги в «Книжном Рае»:
• Прочитано страниц: $totalPagesRead
• Прочитано книг: ${completedBooks.length}
• Высота книжной башни: $towerRounded см ($comparisonText)
• Время в концентрации: $timeStr
• Самый активный день: ${sessionService.mostActiveWeekdayString}
${topGenre != null ? '• Любимый жанр: ${topGenre!.label} ($topGenrePct%)\n' : ''}${goldenQuote != null ? '\n«${goldenQuote.text}»\n' : ''}
#КнижныйРай #ReadingWrapped
''';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Wrapped'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'КНИЖНЫЙ РАЙ • WRAPPED',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: primaryAccent,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Ваш Литературный Путь',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(Icons.auto_awesome, color: primaryAccent, size: 28),
                      ],
                    ),
                    const Divider(height: 28),

                    // Книжная башня
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: primaryAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.shelves, size: 32, color: primaryAccent),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('КНИЖНАЯ БАШНЯ', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                              Text(
                                '$towerRounded см',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryAccent),
                              ),
                              Text(comparisonText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Метрики
                    Row(
                      children: [
                        _metricPill('Страниц', '$totalPagesRead', Icons.description, primaryAccent),
                        const SizedBox(width: 8),
                        _metricPill('Книг', '${completedBooks.length}', Icons.check_circle, primaryAccent),
                        const SizedBox(width: 8),
                        _metricPill('Времени', timeStr, Icons.timer, primaryAccent),
                      ],
                    ),
                    const Divider(height: 28),

                    // Темпоритм
                    _rowStat('Любимый день недели:', sessionService.mostActiveWeekdayString),
                    const SizedBox(height: 8),
                    if (topGenre != null) ...[
                      _rowStat('Главный жанр:', '${topGenre!.label} ($topGenrePct%)'),
                      const SizedBox(height: 8),
                    ],
                    _rowStat('Средняя скорость:', '${sessionService.averageSpeedPagesPerHour.round()} стр./час'),

                    if (goldenQuote != null) ...[
                      const Divider(height: 28),
                      const Text('ЗОЛОТАЯ ЦИТАТА', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryAccent.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '«${goldenQuote.text}»',
                          style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Скопировать и поделиться итогами'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: shareText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Книжные итоги скопированы в буфер обмена! Готово для отправки в Telegram или соцсети.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricPill(String title, String value, IconData icon, Color primary) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: primary),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _rowStat(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
