import 'dart:math';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/enums.dart';
import 'reading_session_service.dart';

enum ReadingMood {
  any('Любое', Icons.auto_awesome, Colors.purple, 'Всё разнообразие библиотеки'),
  cozy('Уют и тепло', Icons.coffee, Colors.orange, 'Согревающая проза, сказки, лёгкая классика'),
  thrilling('Острый сюжет', Icons.local_fire_department, Colors.red, 'Детективы, триллеры, приключения, динамика'),
  intellectual('Интеллект', Icons.psychology, Colors.blue, 'Философия, нон-фикшн, история, наука'),
  emotional('Драма и чувства', Icons.favorite, Colors.pink, 'Глубокие переживания, романтика, поэзия');

  final String label;
  final IconData icon;
  final Color color;
  final String subtitle;
  const ReadingMood(this.label, this.icon, this.color, this.subtitle);
}

enum AvailableReadingTime {
  any('Любое', Icons.access_time),
  short('15–30 мин', Icons.bolt),
  medium('1–2 часа', Icons.hourglass_bottom),
  deep('Вечер / Эпос', Icons.nights_stay);

  final String label;
  final IconData icon;
  const AvailableReadingTime(this.label, this.icon);
}

enum OracleQueueSource {
  planned('В планах', Icons.bookmark),
  inProgress('Читаю сейчас', Icons.menu_book),
  cycle('Циклы', Icons.link),
  all('Вся библиотека', Icons.library_books);

  final String label;
  final IconData icon;
  const OracleQueueSource(this.label, this.icon);
}

class BookRecommendation {
  final Book book;
  final ReadingMood mood;
  final AvailableReadingTime time;
  final String justification;
  final String estimatedTimeToFinish;

  BookRecommendation({
    required this.book,
    required this.mood,
    required this.time,
    required this.justification,
    required this.estimatedTimeToFinish,
  });
}

class BookOracleService extends ChangeNotifier {
  static final BookOracleService instance = BookOracleService._internal();
  BookOracleService._internal();

  final _rnd = Random();

  BookRecommendation? recommend({
    required List<Book> books,
    required ReadingMood mood,
    required AvailableReadingTime time,
    required OracleQueueSource source,
  }) {
    if (books.isEmpty) return null;

    List<Book> candidates = [];
    switch (source) {
      case OracleQueueSource.planned:
        candidates = books.where((b) => b.status == ReadingStatus.toRead).toList();
        break;
      case OracleQueueSource.inProgress:
        candidates = books.where((b) => b.status == ReadingStatus.reading).toList();
        break;
      case OracleQueueSource.cycle:
        candidates = books.where((b) => b.cycle != null && b.cycle!.trim().isNotEmpty && b.status != ReadingStatus.completed).toList();
        break;
      case OracleQueueSource.all:
        candidates = books.where((b) => b.status != ReadingStatus.completed).toList();
        break;
    }

    if (candidates.isEmpty) {
      candidates = books.where((b) => b.status != ReadingStatus.completed).toList();
    }
    if (candidates.isEmpty) {
      candidates = List.from(books);
    }

    final scored = <Map<String, dynamic>>[];

    for (final b in candidates) {
      double score = _rnd.nextDouble() * 2.0;
      final reasons = <String>[];

      // Mood match
      switch (mood) {
        case ReadingMood.any:
          score += 5;
          break;
        case ReadingMood.cozy:
          if ([BookGenre.classic, BookGenre.novel, BookGenre.children, BookGenre.ya].contains(b.genre)) {
            score += 15;
            reasons.add('жанр «${b.genre.label}» создаст тёплую и комфортную атмосферу');
          }
          break;
        case ReadingMood.thrilling:
          if ([BookGenre.detective, BookGenre.thriller, BookGenre.fantasy, BookGenre.scifi, BookGenre.adventures].contains(b.genre)) {
            score += 15;
            reasons.add('«${b.genre.label}» захватит динамичным сюжетом');
          }
          break;
        case ReadingMood.intellectual:
          if ([BookGenre.nonfiction, BookGenre.science, BookGenre.philosophy, BookGenre.biography, BookGenre.history, BookGenre.psychology].contains(b.genre)) {
            score += 15;
            reasons.add('«${b.genre.label}» подарит пищу для глубоких размышлений');
          }
          break;
        case ReadingMood.emotional:
          if ([BookGenre.poetry, BookGenre.drama, BookGenre.novel, BookGenre.ya].contains(b.genre)) {
            score += 15;
            reasons.add('книга наполнена сильными эмоциями и тонкими чувствами');
          }
          break;
      }

      // Time match
      final pages = b.remainingPages > 0 ? b.remainingPages : b.totalPages;
      switch (time) {
        case AvailableReadingTime.any:
          score += 5;
          break;
        case AvailableReadingTime.short:
          if (pages <= 180 || b.remainingPages <= 60) {
            score += 14;
            reasons.add('объём всего $pages стр. идеально подходит для короткого чтения');
          }
          break;
        case AvailableReadingTime.medium:
          if (pages > 180 && pages <= 380) {
            score += 14;
            reasons.add('комфортный объём ($pages стр.) не перегрузит ваш вечер');
          }
          break;
        case AvailableReadingTime.deep:
          if (pages > 380 || (b.cycle != null && b.cycle!.isNotEmpty)) {
            score += 14;
            reasons.add('масштабный объём ($pages стр.) позволит полностью погрузиться в историю');
          }
          break;
      }

      if (b.status == ReadingStatus.toRead) score += 4;
      if (b.rating == BookRating.fiveStars) score += 6;
      if (b.cycle != null && b.cycle!.isNotEmpty) {
        score += 3;
        reasons.add('часть цикла «${b.cycle}»');
      }

      final justification = reasons.isNotEmpty
          ? 'Книжный сомелье рекомендует эту книгу, так как ${reasons.join(', ')}.'
          : 'Прекрасный выбор для чтения прямо сейчас из вашей домашней библиотеки.';

      scored.add({
        'book': b,
        'score': score,
        'justification': justification,
      });
    }

    scored.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    final best = scored.first;
    final bestBook = best['book'] as Book;
    final timeStr = ReadingSessionService.instance.formatEstimatedTime(bestBook.remainingPages);

    return BookRecommendation(
      book: bestBook,
      mood: mood,
      time: time,
      justification: best['justification'] as String,
      estimatedTimeToFinish: timeStr,
    );
  }

  BookRecommendation? rollDice(List<Book> books) {
    final unread = books.where((b) => b.status == ReadingStatus.toRead).toList();
    final pool = unread.isEmpty ? books : unread;
    if (pool.isEmpty) return null;

    final randomBook = pool[_rnd.nextInt(pool.length)];
    final timeStr = ReadingSessionService.instance.formatEstimatedTime(randomBook.remainingPages);

    return BookRecommendation(
      book: randomBook,
      mood: ReadingMood.any,
      time: AvailableReadingTime.any,
      justification: 'Случайный жребий оракула пал на эту книгу. Время стряхнуть с неё пыль и открыть первую страницу!',
      estimatedTimeToFinish: timeStr,
    );
  }
}
