import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/book.dart';
import '../../data/services/reading_session_service.dart';
import '../views/book_detail_view.dart';
import '../views/reading_session_screen.dart';
import 'book_cover_widget.dart';

class HotReadsBentoGrid extends StatelessWidget {
  final List<Book> books;

  const HotReadsBentoGrid({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return const SizedBox.shrink();

    final sessionService = context.watch<ReadingSessionService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text(
                    'Книги в фокусе (Hot Reads)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.local_fire_department, size: 18, color: Color(0xFFD9532F)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9532F).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${books.length} в процессе',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD9532F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Горизонтальный список Bento-карточек
          SizedBox(
            height: 184,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: books.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final book = books[index];
                // Чередуем стили карточек как в референсе (Charcoal и Terracotta)
                final isTerracotta = index % 3 == 1;
                final isEmerald = index % 3 == 2;
                final bgColor = isTerracotta
                    ? const Color(0xFFC44E28)
                    : isEmerald
                        ? const Color(0xFF1E4639)
                        : (isDark ? const Color(0xFF18191D) : const Color(0xFF22242A));

                final percent = (book.progressPercentage * 100).toInt();
                final remainingTime = sessionService.formatEstimatedTime(book.remainingPages);

                return Container(
                  width: 250,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BookDetailView(book: book)),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Верхняя плашка дедлайна и статус
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.timer_outlined, size: 11, color: Colors.white70),
                                    const SizedBox(width: 4),
                                    Text(
                                      remainingTime,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_forward, size: 12, color: Colors.white70),
                              ),
                            ],
                          ),
                          const Spacer(),

                          // Название и автор
                          Text(
                            book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            book.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.70),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Прогресс бар и процент
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: book.progressPercentage,
                                    minHeight: 5,
                                    backgroundColor: Colors.white.withOpacity(0.20),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$percent%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Кнопка Быстрый старт сессии
                          SizedBox(
                            width: double.infinity,
                            height: 28,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.play_arrow, size: 14),
                              label: const Text('Продолжить', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.22),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
