import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../view_models/library_view_model.dart';
import '../widgets/book_cover_widget.dart';

class ReadingChallengeView extends StatefulWidget {
  const ReadingChallengeView({super.key});

  @override
  State<ReadingChallengeView> createState() => _ReadingChallengeViewState();
}

class _ReadingChallengeViewState extends State<ReadingChallengeView> {
  int _monthlySprintGoal = 400;
  static const String _prefsKeyMonthlySprint = 'bp_monthly_sprint_goal';

  @override
  void initState() {
    super.initState();
    _loadMonthlyGoal();
  }

  Future<void> _loadMonthlyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _monthlySprintGoal = prefs.getInt(_prefsKeyMonthlySprint) ?? 400;
    });
  }

  Future<void> _setMonthlyGoal(int goal) async {
    setState(() {
      _monthlySprintGoal = goal;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKeyMonthlySprint, goal);
  }

  static const List<String> _monthNames = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
  ];

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LibraryViewModel>();
    final primaryAccent = Theme.of(context).colorScheme.primary;

    final readBooks = viewModel.books.where((b) => b.isFinished).toList();
    final readBooksCount = readBooks.length;
    final annualGoal = viewModel.annualGoal;

    final now = DateTime.now();
    final dayOfYear = int.parse("${now.difference(DateTime(now.year, 1, 1)).inDays + 1}");
    final isLeapYear = (now.year % 4 == 0 && now.year % 100 != 0) || (now.year % 400 == 0);
    final daysInYear = isLeapYear ? 366 : 365;

    final expectedReadRatio = dayOfYear / daysInYear;
    final expectedBooks = expectedReadRatio * annualGoal;
    final paceDifference = readBooksCount - expectedBooks;

    final percent = annualGoal > 0 ? (readBooksCount / annualGoal).clamp(0.0, 1.0) : 0.0;

    // Monthly sprint data
    final currentMonthName = _monthNames[(now.month - 1).clamp(0, 11)];
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final currentDayOfMonth = now.day;
    final daysLeftInMonth = max(1, daysInMonth - currentDayOfMonth);

    // Current month pages read
    final monthPages = viewModel.books
        .where((b) => b.isFinished || b.readPages > 0)
        .fold<int>(0, (sum, b) => sum + (b.isFinished ? b.totalPages : b.readPages));

    final sprintRatio = _monthlySprintGoal > 0 ? (monthPages / _monthlySprintGoal).clamp(0.0, 1.0) : 0.0;
    final expectedMonthPagesByNow = _monthlySprintGoal * (currentDayOfMonth / daysInMonth);
    final neededPagesPerDay = max(0, (_monthlySprintGoal - monthPages) / daysLeftInMonth).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Книжный вызов 2026'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. Главный прогресс (Годовая цель)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ПРОГРЕСС ЦЕЛИ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: primaryAccent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$readBooksCount из $annualGoal книг',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${(percent * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 12,
                      backgroundColor: primaryAccent.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Анализ темпа (Pace analysis)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        paceDifference >= 0 ? Icons.trending_up : Icons.timelapse,
                        color: paceDifference >= 0 ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        paceDifference >= 0 ? 'Опережаете график!' : 'Нужно ускориться',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: paceDifference >= 0 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (paceDifference >= 0)
                    Text(
                      'Вы прочитали на ${paceDifference.toInt()} ${_bookWord(paceDifference.toInt())} больше графика на текущий день года. Прекрасный результат!',
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    )
                  else ...[
                    Builder(builder: (context) {
                      final behind = paceDifference.abs().toInt();
                      final remBooks = max(1, annualGoal - readBooksCount);
                      final remDays = max(1, daysInYear - dayOfYear);
                      final daysPerBook = (remDays / remBooks).round();
                      final pagesPerDay = (350 / max(1, daysPerBook)).round();

                      return Text(
                        'Отставание от графика: $behind ${_bookWord(behind)}. Чтобы успеть к концу года, читайте примерно по 1 книге каждые $daysPerBook дн. (около $pagesPerDay стр. в день).',
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2.5. Марафон текущего месяца (Спринт)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orange, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Марафон месяца: $currentMonthName',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'Персональный спринт по страницам',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${(sprintRatio * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: sprintRatio >= 1.0 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Дорожка спринта с бегуном
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final runnerX = (sprintRatio * w).clamp(10.0, w - 24.0);
                      return Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.centerLeft,
                            children: [
                              Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              Container(
                                height: 10,
                                width: (sprintRatio * w).clamp(10.0, w),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.orange, Colors.deepOrange],
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              Positioned(
                                left: runnerX - 10,
                                top: -14,
                                child: Text(
                                  sprintRatio >= 1.0 ? '🏆' : '🏃‍♂️',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              const Positioned(
                                right: 0,
                                top: -14,
                                child: Text('🏁', style: TextStyle(fontSize: 14)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$monthPages стр. прочитано',
                                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Цель: $_monthlySprintGoal стр.',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Прогноз темпа спринта
                  Row(
                    children: [
                      Icon(
                        sprintRatio >= 1.0
                            ? Icons.verified
                            : (monthPages >= expectedMonthPagesByNow ? Icons.bolt : Icons.track_changes),
                        size: 16,
                        color: sprintRatio >= 1.0
                            ? Colors.green
                            : (monthPages >= expectedMonthPagesByNow ? Colors.orange : Colors.grey),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          sprintRatio >= 1.0
                              ? 'Ура! Цель спринта на $currentMonthName выполнена!'
                              : (monthPages >= expectedMonthPagesByNow
                                  ? 'Отличный темп! Опережаешь план спринта на ${(monthPages - expectedMonthPagesByNow).toInt()} стр.'
                                  : 'Чтобы успеть за $daysLeftInMonth дн., читай по ~$neededPagesPerDay стр./день'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: sprintRatio >= 1.0 ? Colors.green : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Быстрый выбор цели спринта
                  Wrap(
                    spacing: 8,
                    children: [250, 400, 600, 1000].map((goal) {
                      final isSelected = _monthlySprintGoal == goal;
                      return ChoiceChip(
                        label: Text('$goal стр'),
                        selected: isSelected,
                        onSelected: (_) => _setMonthlyGoal(goal),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Настройка годовой цели
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'НАСТРОЙКА ГОДОВОЙ ЦЕЛИ',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$annualGoal ${_bookWord(annualGoal)} в год',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: [
                          IconButton.outlined(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: annualGoal > 5 ? () => viewModel.setAnnualGoal(annualGoal - 5) : null,
                          ),
                          const SizedBox(width: 8),
                          IconButton.outlined(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () => viewModel.setAnnualGoal(annualGoal + 5),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [20, 30, 50, 75, 100].map((preset) {
                      final isSelected = annualGoal == preset;
                      return ChoiceChip(
                        label: Text('$preset книг'),
                        selected: isSelected,
                        onSelected: (_) => viewModel.setAnnualGoal(preset),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Виртуальная полка прочитанных книг
          Text(
            'Прочитано в 2026 году ($readBooksCount)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (readBooks.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.auto_stories_outlined, size: 40, color: primaryAccent.withOpacity(0.5)),
                      const SizedBox(height: 10),
                      const Text('Пока нет прочитанных книг в 2026 году'),
                    ],
                  ),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: readBooks.length,
              itemBuilder: (context, index) {
                final book = readBooks[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: BookCoverWidget(
                        coverURL: book.cleanCoverURL,
                        title: book.title,
                        author: book.author,
                        width: double.infinity,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  static String _bookWord(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod100 >= 11 && mod100 <= 19) return 'книг';
    if (mod10 == 1) return 'книгу';
    if (mod10 >= 2 && mod10 <= 4) return 'книги';
    return 'книг';
  }
}
