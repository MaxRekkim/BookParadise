import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/achievement.dart';
import '../../data/services/achievement_service.dart';
import '../view_models/library_view_model.dart';
import '../../data/services/reading_session_service.dart';
import '../../data/services/quotes_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ach = context.read<AchievementService>();
      final lib = context.read<LibraryViewModel>();
      final sess = context.read<ReadingSessionService>();
      final quotes = context.read<QuotesService>();
      ach.recalculateAll(
        history: sess.history,
        books: lib.books,
        quotes: quotes.quotes,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final achievementService = context.watch<AchievementService>();
    final primaryAccent = Theme.of(context).colorScheme.primary;

    final filtered = _selectedCategory == null
        ? achievementService.achievements
        : achievementService.achievements.where((a) => a.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Трофеи и привычки (${achievementService.unlockedCount}/${achievementService.totalCount})'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Streak & Shield Banner
            _buildStreakBanner(context, achievementService),
            const SizedBox(height: 16),

            // Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _categoryChip('Все', null),
                  _categoryChip('Стрики', 'streak'),
                  _categoryChip('Скорость', 'speed'),
                  _categoryChip('Объемы', 'volume'),
                  _categoryChip('Коллекция', 'collection'),
                  _categoryChip('Бинго', 'bingo'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Grid of Badges
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final item = filtered[index];
                return _buildBadgeCard(context, item, primaryAccent);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakBanner(BuildContext context, AchievementService service) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.orange, Colors.red],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${service.currentStreak}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('Стрик чтения', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(width: 4),
                          Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
                        ],
                      ),
                      Text(
                        service.currentStreak == 0
                            ? 'Начните читать сегодня, чтобы зажечь огонь!'
                            : 'Вы читаете ${service.currentStreak} дн. подряд!',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield, color: Colors.blue, size: 16),
                    SizedBox(width: 6),
                    Text('Щит защиты стрика:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Text(
                  service.streakShields > 0 ? '${service.streakShields} в запасе' : 'Израсходован',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: service.streakShields > 0 ? Colors.blue : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String label, String? cat) {
    final isSelected = _selectedCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCategory = cat),
      ),
    );
  }

  Widget _buildBadgeCard(BuildContext context, ReadingAchievement item, Color primaryAccent) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isUnlocked ? primaryAccent.withOpacity(0.12) : Colors.grey.withOpacity(0.12),
                border: Border.all(
                  color: item.isUnlocked ? Colors.amber : Colors.grey.withOpacity(0.3),
                  width: item.isUnlocked ? 2 : 1,
                ),
              ),
              child: Center(
                child: item.isUnlocked
                    ? Text(item.badgeEmoji, style: const TextStyle(fontSize: 26))
                    : const Icon(Icons.lock_outline, color: Colors.grey, size: 22),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: item.isUnlocked ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const Spacer(),
            if (!item.isUnlocked) ...[
              LinearProgressIndicator(
                value: item.progress,
                minHeight: 4,
                backgroundColor: Colors.grey.withOpacity(0.2),
              ),
              const SizedBox(height: 4),
              Text(item.progressText, style: const TextStyle(fontSize: 9, color: Colors.grey)),
            ] else ...[
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified, size: 12, color: Colors.green),
                  SizedBox(width: 4),
                  Text('Получено', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
