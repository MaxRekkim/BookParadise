import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/library_view_model.dart';
import '../../data/models/enums.dart';
import '../views/reading_challenge_view.dart';
import '../views/library_view.dart';

class ExecutiveQuotaRingAndMix extends StatelessWidget {
  const ExecutiveQuotaRingAndMix({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LibraryViewModel>();
    final stats = viewModel.stats;
    final annualGoal = viewModel.annualGoal;
    final readBooks = stats.readBooks;
    final goalPercent = annualGoal > 0 ? (readBooks / annualGoal).clamp(0.0, 1.0) : 0.0;
    final percentInt = (goalPercent * 100).toInt();

    // Расчет жанров / статусов
    final totalBooks = viewModel.books.length;
    final inProgressCount = viewModel.books.where((b) => b.readPages > 0 && !b.isFinished).length;
    final plannedCount = viewModel.books.where((b) => b.status == ReadingStatus.planned).length;
    final finishedCount = readBooks;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Левая карточка: Circular Glow Ring Gauge (Годовая цель)
          Expanded(
            flex: 4,
            child: Container(
              height: 190,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A2F), // Глубокий благородный изумруд как в референсе
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReadingChallengeView()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Цель года',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.north_east, size: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Center(
                        child: SizedBox(
                          width: 86,
                          height: 86,
                          child: CustomPaint(
                            painter: _RingGaugePainter(
                              progress: goalPercent,
                              ringColor: const Color(0xFFE5B83B), // Золотисто-желтый луч
                              trackColor: Colors.white.withOpacity(0.15),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$percentInt%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    '$readBooks / $annualGoal',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Center(
                        child: Text(
                          '2026 Challenge',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 2. Правая карточка: Library Mix Bar (Сегментированный спектр библиотеки)
          Expanded(
            flex: 6,
            child: Container(
              height: 190,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2024) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LibraryView()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Спектр библиотеки',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.north_east, size: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$totalBooks книг',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : const Color(0xFF1B1D21),
                        ),
                      ),
                      Text(
                        'в вашей коллекции',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                        ),
                      ),
                      const Spacer(),

                      // Мультисегментный прогресс-бар (как на скриншоте)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 16,
                          child: totalBooks == 0
                              ? Container(color: Colors.grey.withOpacity(0.2))
                              : Row(
                                  children: [
                                    if (finishedCount > 0)
                                      Expanded(
                                        flex: finishedCount,
                                        child: Container(color: const Color(0xFFE5B83B)), // Золотой
                                      ),
                                    if (inProgressCount > 0)
                                      Expanded(
                                        flex: inProgressCount,
                                        child: Container(color: const Color(0xFFD9532F)), // Терракотовый
                                      ),
                                    if (plannedCount > 0)
                                      Expanded(
                                        flex: plannedCount,
                                        child: Container(color: const Color(0xFF1E3A2F)), // Изумрудный
                                      ),
                                  ],
                                ),
                        ),
                      ),
                      const Spacer(),

                      // Чипы-легенда
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _legendChip(const Color(0xFFE5B83B), 'Прочитано', finishedCount),
                          _legendChip(const Color(0xFFD9532F), 'Читаю', inProgressCount),
                          _legendChip(const Color(0xFF1E3A2F), 'В планах', plannedCount),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendChip(Color color, String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label $count',
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ],
    );
  }
}

class _RingGaugePainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color trackColor;

  _RingGaugePainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;

    // Фоновый трек
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 7.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Акцентная дуга
    if (progress > 0) {
      final ringPaint = Paint()
        ..color = ringColor
        ..strokeWidth = 7.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        ringPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingGaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.ringColor != ringColor;
}
