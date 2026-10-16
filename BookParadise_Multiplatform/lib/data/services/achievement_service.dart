import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../models/quote.dart';
import '../models/session_record.dart';

class AchievementService extends ChangeNotifier {
  static final AchievementService instance = AchievementService._internal();
  AchievementService._internal() {
    _initBaseAchievements();
    _loadFromPrefs();
  }

  List<ReadingAchievement> _achievements = [];
  List<ReadingAchievement> get achievements => _achievements;

  int _currentStreak = 0;
  int get currentStreak => _currentStreak;

  int _streakShields = 1;
  int get streakShields => _streakShields;

  bool _isShieldActiveToday = false;
  bool get isShieldActiveToday => _isShieldActiveToday;

  int get unlockedCount => _achievements.where((a) => a.isUnlocked).length;
  int get totalCount => _achievements.length;

  void _initBaseAchievements() {
    _achievements = [
      ReadingAchievement(
        id: 'streak_7',
        title: 'Книжный огонь',
        subtitle: 'Читать каждый день 7 дней подряд',
        badgeEmoji: '🔥',
        category: 'streak',
      ),
      ReadingAchievement(
        id: 'streak_30',
        title: 'Железная привычка',
        subtitle: 'Удерживать стрик чтения 30 дней подряд',
        badgeEmoji: '🛡️',
        category: 'streak',
      ),
      ReadingAchievement(
        id: 'night_owl',
        title: 'Ночной книгочей',
        subtitle: 'Завершить сессию чтения между 00:00 и 04:00',
        badgeEmoji: '🦉',
        category: 'speed',
      ),
      ReadingAchievement(
        id: 'sprint_master',
        title: 'Читательский спринт',
        subtitle: 'Прочитать более 60 страниц за одну сессию',
        badgeEmoji: '⚡',
        category: 'speed',
      ),
      ReadingAchievement(
        id: 'tome_conqueror',
        title: 'Покоритель талмудов',
        subtitle: 'Полностью прочитать книгу объемом от 600 страниц',
        badgeEmoji: '🧱',
        category: 'volume',
      ),
      ReadingAchievement(
        id: 'saga_keeper',
        title: 'Хранитель саги',
        subtitle: 'Полностью прочитать все книги одного цикла',
        badgeEmoji: '👑',
        category: 'collection',
      ),
      ReadingAchievement(
        id: 'quote_hunter',
        title: 'Мастер цитат',
        subtitle: 'Сохранить 10 или более цитат из книг',
        badgeEmoji: '📝',
        category: 'collection',
      ),
      ReadingAchievement(
        id: 'bibliophile',
        title: 'Библиофил',
        subtitle: 'Собрать в своей библиотеке 50 или более книг',
        badgeEmoji: '📚',
        category: 'collection',
      ),
      ReadingAchievement(
        id: 'bingo_sniper',
        title: 'Снайпер Бинго',
        subtitle: 'Завершить книгу, запланированную в книжном бинго',
        badgeEmoji: '🎯',
        category: 'bingo',
      ),
      ReadingAchievement(
        id: 'soundscape_zen',
        title: 'Дзен-погружение',
        subtitle: 'Провести сессию чтения со звуками природы',
        badgeEmoji: '🎧',
        category: 'speed',
      ),
    ];
  }

  void recalculateAll({
    required List<ReadingSessionRecord> history,
    required List<Book> books,
    required List<BookQuote> quotes,
  }) {
    _calculateStreakAndShields(history);

    // Night Owl
    final hasNight = history.any((r) => r.date.hour >= 0 && r.date.hour < 4);
    _updateStatus('night_owl', hasNight, hasNight ? 1.0 : 0.0, hasNight ? 'Получено!' : '0/1');

    // Sprint
    int maxPages = 0;
    for (final r in history) {
      final p = r.pagesRead;
      if (p > maxPages) maxPages = p;
    }
    final sprintUnlocked = maxPages >= 60;
    _updateStatus('sprint_master', sprintUnlocked, (maxPages / 60.0).clamp(0.0, 1.0), '$maxPages/60 стр.');

    // Tome
    int maxTome = 0;
    for (final b in books.where((b) => b.status == ReadingStatus.completed)) {
      if (b.totalPages > maxTome) maxTome = b.totalPages;
    }
    final tomeUnlocked = maxTome >= 600;
    _updateStatus('tome_conqueror', tomeUnlocked, (maxTome / 600.0).clamp(0.0, 1.0), '$maxTome/600 стр.');

    // Quotes
    final qCount = quotes.length;
    _updateStatus('quote_hunter', qCount >= 10, (qCount / 10.0).clamp(0.0, 1.0), '$qCount/10 цитат');

    // Bibliophile
    final bCount = books.length;
    _updateStatus('bibliophile', bCount >= 50, (bCount / 50.0).clamp(0.0, 1.0), '$bCount/50 книг');

    // Streaks
    _updateStatus('streak_7', _currentStreak >= 7, (_currentStreak / 7.0).clamp(0.0, 1.0), '${_currentStreak.clamp(0, 7)}/7 дней');
    _updateStatus('streak_30', _currentStreak >= 30, (_currentStreak / 30.0).clamp(0.0, 1.0), '${_currentStreak.clamp(0, 30)}/30 дней');

    _saveToPrefs();
    notifyListeners();
  }

  void markSoundscapeUsed() {
    _updateStatus('soundscape_zen', true, 1.0, 'Получено!');
    _saveToPrefs();
    notifyListeners();
  }

  void _calculateStreakAndShields(List<ReadingSessionRecord> history) {
    if (history.isEmpty) {
      _currentStreak = 0;
      return;
    }

    final dates = history.map((r) => DateTime(r.date.year, r.date.month, r.date.day)).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    DateTime checkDate = dates.contains(today) ? today : (dates.contains(yesterday) ? yesterday : today);
    int streak = 0;
    bool usedShield = false;

    while (true) {
      if (dates.contains(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (!usedShield && _streakShields > 0 && streak > 0) {
        usedShield = true;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    _currentStreak = streak;
    _isShieldActiveToday = usedShield;

    if (streak >= 14 && _streakShields < 2) {
      _streakShields = 2;
    } else if (streak >= 7 && _streakShields < 1) {
      _streakShields = 1;
    }
  }

  void _updateStatus(String id, bool isUnlocked, double progress, String progressText) {
    final idx = _achievements.indexWhere((a) => a.id == id);
    if (idx != -1) {
      final a = _achievements[idx];
      a.progress = progress;
      a.progressText = progressText;
      if (isUnlocked && !a.isUnlocked) {
        a.isUnlocked = true;
        a.unlockedDate = DateTime.now();
      }
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _achievements.map((a) => a.toJson()).toList();
    await prefs.setString('achievements_data', jsonEncode(list));
    await prefs.setInt('streak_shields_count', _streakShields);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _streakShields = prefs.getInt('streak_shields_count') ?? 1;

    final raw = prefs.getString('achievements_data');
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        for (final item in decoded) {
          final loaded = ReadingAchievement.fromJson(item as Map<String, dynamic>);
          final idx = _achievements.indexWhere((a) => a.id == loaded.id);
          if (idx != -1) {
            _achievements[idx].isUnlocked = loaded.isUnlocked;
            _achievements[idx].unlockedDate = loaded.unlockedDate;
            _achievements[idx].progress = loaded.progress;
            _achievements[idx].progressText = loaded.progressText;
          }
        }
      } catch (e) {
        debugPrint('Error loading achievements: $e');
      }
    }
    notifyListeners();
  }
}
