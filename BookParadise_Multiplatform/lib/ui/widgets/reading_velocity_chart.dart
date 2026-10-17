import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/library_view_model.dart';
import '../../data/models/session.dart';
import '../../data/services/reading_session_service.dart';

enum VelocityPeriod { days7, days30, months6, months12 }

class ReadingVelocityChart extends StatefulWidget {
  const ReadingVelocityChart({super.key});

  @override
  State<ReadingVelocityChart> createState() => _ReadingVelocityChartState();
}

class _ReadingVelocityChartState extends State<ReadingVelocityChart> {
  VelocityPeriod _selectedPeriod = VelocityPeriod.days30;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LibraryViewModel>();
    final sessionService = context.watch<ReadingSessionService>();
    final primaryAccent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Рассчитываем данные за выбранный период
    final history = sessionService.history;
    final dataPoints = _generateDataPoints(history, _selectedPeriod);
    final totalPagesInPeriod = dataPoints.fold<int>(0, (sum, p) => sum + p.pages);
    final targetPages = _getTargetForPeriod(_selectedPeriod);
    final isAboveTarget = totalPagesInPeriod >= targetPages;
    final diffPercent = targetPages > 0 ? (((totalPagesInPeriod - targetPages) / targetPages) * 100).round() : 0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDark ? const Color(0xFF1E2024) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок и селектор периода
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Темпоритм чтения',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$totalPagesInPeriod',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : const Color(0xFF1B1D21),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'стр.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Бейдж сравнения с нормой
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isAboveTarget ? Colors.green.withOpacity(0.15) : Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isAboveTarget ? '+$diffPercent% к цели' : '$diffPercent% от цели',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isAboveTarget ? Colors.green.shade600 : Colors.amber.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Сегментированный переключатель периода
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2D33) : const Color(0xFFF1F3F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _periodPill(VelocityPeriod.days7, '7Д'),
                      _periodPill(VelocityPeriod.days30, '30Д'),
                      _periodPill(VelocityPeriod.months6, '6М'),
                      _periodPill(VelocityPeriod.months12, '12М'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Легенда
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD9532F),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Прочитано',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
                const SizedBox(width: 16),
                CustomPaint(
                  size: const Size(16, 2),
                  painter: _DashedLinePainter(color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                ),
                const SizedBox(width: 6),
                Text(
                  'Целевая норма: $targetPages стр.',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // График
            SizedBox(
              height: 140,
              width: double.infinity,
              child: CustomPaint(
                painter: _SplineChartPainter(
                  dataPoints: dataPoints,
                  targetValue: (targetPages / dataPoints.length).round(),
                  lineColor: const Color(0xFFD9532F),
                  gradientColors: [
                    const Color(0xFFD9532F).withOpacity(0.40),
                    const Color(0xFFD9532F).withOpacity(0.02),
                  ],
                  targetLineColor: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                  isDark: isDark,
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Подписи оси дат
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dataPoints.first.label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                if (dataPoints.length > 2)
                  Text(dataPoints[dataPoints.length ~/ 2].label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                Text(dataPoints.last.label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodPill(VelocityPeriod period, String text) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF1B1D21) : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  List<_DataPoint> _generateDataPoints(List<ReadingSession> history, VelocityPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case VelocityPeriod.days7:
        return List.generate(7, (i) {
          final day = now.subtract(Duration(days: 6 - i));
          final pages = history
              .where((s) => s.startTime.year == day.year && s.startTime.month == day.month && s.startTime.day == day.day)
              .fold<int>(0, (sum, s) => sum + s.pagesRead);
          final label = _weekdayName(day.weekday);
          return _DataPoint(label: label, pages: pages);
        });

      case VelocityPeriod.days30:
        return List.generate(6, (i) {
          final startDay = now.subtract(Duration(days: (5 - i) * 5));
          int pages = 0;
          for (int d = 0; d < 5; d++) {
            final check = startDay.add(Duration(days: d));
            pages += history
                .where((s) => s.startTime.year == check.year && s.startTime.month == check.month && s.startTime.day == check.day)
                .fold<int>(0, (sum, s) => sum + s.pagesRead);
          }
          final label = '${startDay.day} ${_monthName(startDay.month)}';
          return _DataPoint(label: label, pages: pages);
        });

      case VelocityPeriod.months6:
        return List.generate(6, (i) {
          final monthIndex = now.month - 5 + i;
          final normalizedMonth = ((monthIndex - 1) % 12) + 1;
          final year = now.year + ((monthIndex - 1) ~/ 12);
          final pages = history
              .where((s) => s.startTime.year == year && s.startTime.month == normalizedMonth)
              .fold<int>(0, (sum, s) => sum + s.pagesRead);
          return _DataPoint(label: _monthName(normalizedMonth), pages: pages);
        });

      case VelocityPeriod.months12:
        return List.generate(12, (i) {
          final monthIndex = now.month - 11 + i;
          final normalizedMonth = ((monthIndex - 1) % 12) + 1;
          final year = now.year + ((monthIndex - 1) ~/ 12);
          final pages = history
              .where((s) => s.startTime.year == year && s.startTime.month == normalizedMonth)
              .fold<int>(0, (sum, s) => sum + s.pagesRead);
          return _DataPoint(label: _monthName(normalizedMonth), pages: pages);
        });
    }
  }

  int _getTargetForPeriod(VelocityPeriod period) {
    switch (period) {
      case VelocityPeriod.days7:
        return 175; // 25 стр/день
      case VelocityPeriod.days30:
        return 750; // 25 стр/день
      case VelocityPeriod.months6:
        return 4500;
      case VelocityPeriod.months12:
        return 9000;
    }
  }

  String _weekdayName(int day) {
    const names = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return names[(day - 1) % 7];
  }

  String _monthName(int month) {
    const names = ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'];
    return names[(month - 1) % 12];
  }
}

class _DataPoint {
  final String label;
  final int pages;
  _DataPoint({required this.label, required this.pages});
}

class _SplineChartPainter extends CustomPainter {
  final List<_DataPoint> dataPoints;
  final int targetValue;
  final Color lineColor;
  final List<Color> gradientColors;
  final Color targetLineColor;
  final bool isDark;

  _SplineChartPainter({
    required this.dataPoints,
    required this.targetValue,
    required this.lineColor,
    required this.gradientColors,
    required this.targetLineColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final maxVal = math.max<num>(
      targetValue * 1.35,
      dataPoints.map((p) => p.pages).fold<num>(0, math.max),
    ).toDouble();

    final safeMax = maxVal == 0 ? 100.0 : maxVal;

    // Рассчитываем координаты точек
    final stepX = size.width / (dataPoints.length - 1);
    final points = <Offset>[];
    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * stepX;
      final y = size.height - (dataPoints[i].pages / safeMax) * (size.height - 20) - 10;
      points.add(Offset(x, y.clamp(10, size.height - 10)));
    }

    // 1. Рисуем пунктирную линию таргета
    final targetY = size.height - (targetValue / safeMax) * (size.height - 20) - 10;
    final targetPaint = Paint()
      ..color = targetLineColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    double startX = 0;
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, targetY), Offset(math.min(startX + dashWidth, size.width), targetY), targetPaint);
      startX += dashWidth + dashSpace;
    }

    // 2. Строим сглаженный кубический сплайн (Bezier path)
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // 3. Заливка градиента под кривой
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradientColors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // 4. Линия кривой
    final strokePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);

    // 5. Точки на графике
    final dotPaint = Paint()..color = lineColor;
    final dotInner = Paint()..color = isDark ? const Color(0xFF1E2024) : Colors.white;

    for (final p in points) {
      canvas.drawCircle(p, 4.0, dotPaint);
      canvas.drawCircle(p, 2.0, dotInner);
    }
  }

  @override
  bool shouldRepaint(covariant _SplineChartPainter oldDelegate) => true;
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2), Offset(math.min(x + 3, size.width), size.height / 2), paint);
      x += 5;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
