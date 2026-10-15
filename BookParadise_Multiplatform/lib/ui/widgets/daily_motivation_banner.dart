import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/services/quotes_service.dart';
import '../view_models/library_view_model.dart';
import '../views/reading_challenge_view.dart';
import '../views/quotes_view.dart';

class DailyMotivationBanner extends StatelessWidget {
  const DailyMotivationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final quotesService = context.watch<QuotesService>();
    final libraryVM = context.watch<LibraryViewModel>();
    final currentQuote = quotesService.currentQuote;
    final primaryAccent = Theme.of(context).colorScheme.primary;

    final readCount = libraryVM.stats.readBooks;
    final goal = libraryVM.annualGoal;
    final progress = goal > 0 ? (readCount / goal).clamp(0.0, 1.0) : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quote Header & All Quotes button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.format_quote, color: primaryAccent, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'ЦИТАТА ДНЯ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: primaryAccent,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QuotesView()),
                    );
                  },
                  child: Row(
                    children: [
                      Text(
                        'Все цитаты',
                        style: TextStyle(fontSize: 12, color: primaryAccent, fontWeight: FontWeight.w600),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: primaryAccent),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tap to rotate quote
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                HapticFeedback.lightImpact();
                quotesService.rotateQuote();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentQuote != null ? '«${currentQuote.text}»' : '«Книги — это корабли мысли, странствующие по волнам времени.»',
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                      ),
                    ),
                    if (currentQuote?.note != null && currentQuote!.note!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '— ${currentQuote.note}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const Divider(height: 24),

            // Reading Challenge Goal Bar (Clickable)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReadingChallengeView()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.emoji_events_outlined, size: 16, color: primaryAccent),
                            const SizedBox(width: 6),
                            const Text(
                              'Цель на 2026 год',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Text(
                          '$readCount из $goal книг',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: primaryAccent.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
