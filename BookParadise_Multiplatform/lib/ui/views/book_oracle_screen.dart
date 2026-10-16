import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/book.dart';
import '../../data/models/enums.dart';
import '../../data/services/book_oracle_service.dart';
import '../view_models/library_view_model.dart';
import 'reading_session_screen.dart';

class BookOracleScreen extends StatefulWidget {
  const BookOracleScreen({super.key});

  @override
  State<BookOracleScreen> createState() => _BookOracleScreenState();
}

class _BookOracleScreenState extends State<BookOracleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ReadingMood _selectedMood = ReadingMood.cozy;
  AvailableReadingTime _selectedTime = AvailableReadingTime.medium;
  OracleQueueSource _selectedSource = OracleQueueSource.planned;

  BookRecommendation? _recommendation;
  bool _isRolling = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  void _generate() {
    final lib = context.read<LibraryViewModel>();
    setState(() {
      _recommendation = BookOracleService.instance.recommend(
        books: lib.books,
        mood: _selectedMood,
        time: _selectedTime,
        source: _selectedSource,
      );
    });
  }

  void _rollDice() {
    final lib = context.read<LibraryViewModel>();
    setState(() {
      _isRolling = true;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _isRolling = false;
        _recommendation = BookOracleService.instance.rollDice(lib.books);
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryAccent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Книжный Оракул'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Подбор сомелье', icon: Icon(Icons.auto_awesome, size: 20)),
            Tab(text: 'Литературный кубик', icon: Icon(Icons.casino, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWizardTab(primaryAccent),
          _buildDiceTab(primaryAccent),
        ],
      ),
    );
  }

  Widget _buildWizardTab(Color primaryAccent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '1. Какое настроение вы ищете?',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: ReadingMood.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final mood = ReadingMood.values[index];
                final isSelected = _selectedMood == mood;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(mood.icon, size: 16, color: isSelected ? Colors.white : mood.color),
                      const SizedBox(width: 6),
                      Text(mood.label),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedMood = mood);
                      _generate();
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '2. Сколько у вас есть времени?',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: AvailableReadingTime.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final time = AvailableReadingTime.values[index];
                final isSelected = _selectedTime == time;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(time.icon, size: 16),
                      const SizedBox(width: 6),
                      Text(time.label),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedTime = time);
                      _generate();
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '3. Откуда выбрать?',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: OracleQueueSource.values.map((src) {
                final isSelected = _selectedSource == src;
                return ChoiceChip(
                  label: Text(src.label),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedSource = src);
                      _generate();
                    }
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          if (_recommendation != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildRecommendationCard(_recommendation!, primaryAccent),
            ),
        ],
      ),
    );
  }

  Widget _buildDiceTab(Color primaryAccent) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedRotation(
              turns: _isRolling ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Icon(Icons.casino, size: 64, color: primaryAccent),
            ),
            const SizedBox(height: 16),
            Text(
              'Не можете определиться среди книг на полке?\nДоверьтесь жребию!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _rollDice,
              icon: const Icon(Icons.shuffle),
              label: const Text('Бросить кубик'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            if (_recommendation != null)
              _buildRecommendationCard(_recommendation!, primaryAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(BookRecommendation rec, Color primaryAccent) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 75,
                    height: 110,
                    color: Colors.grey.shade200,
                    child: rec.book.coverUrl != null && rec.book.coverUrl!.isNotEmpty
                        ? Image.network(
                            rec.book.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.menu_book, color: Colors.grey),
                          )
                        : const Icon(Icons.menu_book, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          rec.book.genre.label,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rec.book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rec.book.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.hourglass_bottom, size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              rec.estimatedTimeToFinish,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.orange),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryAccent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: primaryAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rec.justification,
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.menu_book, size: 18),
                    label: const Text('Начать читать'),
                    onPressed: () {
                      final lib = context.read<LibraryViewModel>();
                      var updated = rec.book;
                      if (updated.status != ReadingStatus.reading) {
                        updated = updated.copyWith(status: ReadingStatus.reading);
                        lib.updateBook(updated);
                      }
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ReadingSessionScreen(book: updated)),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Другой вариант',
                  onPressed: _tabController.index == 0 ? _generate : _rollDice,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
