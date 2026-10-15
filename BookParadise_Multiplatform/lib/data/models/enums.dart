import 'package:flutter/material.dart';

enum BookGenre {
  prose('Проза', Color(0xFF6B7280)),
  detective('Детектив', Color(0xFF3B82F6)),
  thriller('Триллер', Color(0xFFDC2626)),
  psychology('Психология', Color(0xFF8B5CF6)),
  fantasy('Фэнтези', Color(0xFF10B981)),
  ya('YA', Color(0xFFEC4899)),
  classic('Классика', Color(0xFFB45309)),
  nonfiction('Нон-фикшн', Color(0xFF0D9488)),
  comics('Комиксы / Манга', Color(0xFFF97316));

  final String title;
  final Color accentColor;
  const BookGenre(this.title, this.accentColor);

  static BookGenre fromString(String raw) {
    final lower = raw.toLowerCase().trim();
    if (lower.contains('проза') || lower.contains('роман')) return BookGenre.prose;
    if (lower.contains('детектив')) return BookGenre.detective;
    if (lower.contains('триллер')) return BookGenre.thriller;
    if (lower.contains('психол')) return BookGenre.psychology;
    if (lower.contains('фэнтези') || lower.contains('фантаст')) return BookGenre.fantasy;
    if (lower.contains('ya') || lower.contains('янг') || lower.contains('молодеж')) return BookGenre.ya;
    if (lower.contains('класс')) return BookGenre.classic;
    if (lower.contains('нон') || lower.contains('бизнес') || lower.contains('саморазв')) return BookGenre.nonfiction;
    if (lower.contains('комикс') || lower.contains('манга') || lower.contains('графич')) return BookGenre.comics;
    return BookGenre.prose;
  }
}

enum ReadingStatus {
  inProgress('Читаю сейчас', 'book.fill', Color(0xFF2563EB)),
  planned('В планах', 'clock.fill', Color(0xFFD97706)),
  completed('Прочитано', 'checkmark.circle.fill', Color(0xFF16A34A)),
  dropped('Брошено', 'xmark.circle.fill', Color(0xFFDC2626));

  final String title;
  final String icon;
  final Color color;
  const ReadingStatus(this.title, this.icon, this.color);

  static ReadingStatus fromRaw(int? readPages, int? totalPages, String? rating) {
    if (rating != null && rating.toLowerCase().contains('брош')) return ReadingStatus.dropped;
    final r = readPages ?? 0;
    final t = totalPages ?? 1;
    if (r >= t && t > 0) return ReadingStatus.completed;
    if (r > 0) return ReadingStatus.inProgress;
    return ReadingStatus.planned;
  }
}

enum BookFormat {
  paper('Бумажная', Icons.menu_book),
  electronic('Электронная', Icons.devices),
  audio('Аудиокнига', Icons.headphones);

  final String title;
  final IconData icon;
  const BookFormat(this.title, this.icon);

  static BookFormat fromString(String raw) {
    final l = raw.toLowerCase();
    if (l.contains('электр') || l.contains('fb2') || l.contains('epub') || l.contains('pdf')) {
      return BookFormat.electronic;
    }
    if (l.contains('аудио')) return BookFormat.audio;
    return BookFormat.paper;
  }
}

enum ShelfLocation {
  onShelf('На полке', Icons.shelves),
  bedside('Стопка у кровати', Icons.bed),
  reader('На читалке', Icons.tablet_android),
  inTransit('В пути', Icons.local_shipping);

  final String title;
  final IconData icon;
  const ShelfLocation(this.title, this.icon);

  static ShelfLocation fromString(String raw) {
    final l = raw.toLowerCase();
    if (l.contains('кроват')) return ShelfLocation.bedside;
    if (l.contains('читалк') || l.contains('kindle')) return ShelfLocation.reader;
    if (l.contains('пути') || l.contains('достав')) return ShelfLocation.inTransit;
    return ShelfLocation.onShelf;
  }
}

enum CycleFilterMode {
  all('Все книги'),
  inCycle('Только в циклах'),
  standalone('Вне циклов'),
  specificCycle('Выбранный цикл');

  final String title;
  const CycleFilterMode(this.title);
}

enum PageRangeFilter {
  all('Любой объём'),
  short('До 200 стр.'),
  medium('200 – 400 стр.'),
  thick('400 – 700 стр.'),
  massive('Более 700 стр.');

  final String title;
  const PageRangeFilter(this.title);

  bool matches(int totalPages) {
    switch (this) {
      case PageRangeFilter.all: return true;
      case PageRangeFilter.short: return totalPages > 0 && totalPages <= 200;
      case PageRangeFilter.medium: return totalPages > 200 && totalPages <= 400;
      case PageRangeFilter.thick: return totalPages > 400 && totalPages <= 700;
      case PageRangeFilter.massive: return totalPages > 700;
    }
  }
}

class BookFilterCriteria {
  ReadingStatus? status;
  BookFormat? format;
  bool onlyWithKindleFile;
  Set<BookGenre> genres;
  int? rating;
  CycleFilterMode cycleMode;
  String? selectedCycle;
  PageRangeFilter pageRange;
  ShelfLocation? shelf;

  BookFilterCriteria({
    this.status,
    this.format,
    this.onlyWithKindleFile = false,
    Set<BookGenre>? genres,
    this.rating,
    this.cycleMode = CycleFilterMode.all,
    this.selectedCycle,
    this.pageRange = PageRangeFilter.all,
    this.shelf,
  }) : genres = genres ?? {};

  bool get isActive =>
      status != null ||
      format != null ||
      onlyWithKindleFile ||
      genres.isNotEmpty ||
      rating != null ||
      cycleMode != CycleFilterMode.all ||
      pageRange != PageRangeFilter.all ||
      shelf != null;

  int get activeCount {
    int c = 0;
    if (status != null) c++;
    if (format != null) c++;
    if (onlyWithKindleFile) c++;
    if (genres.isNotEmpty) c += genres.length;
    if (rating != null) c++;
    if (cycleMode != CycleFilterMode.all) c++;
    if (pageRange != PageRangeFilter.all) c++;
    if (shelf != null) c++;
    return c;
  }

  void reset() {
    status = null;
    format = null;
    onlyWithKindleFile = false;
    genres.clear();
    rating = null;
    cycleMode = CycleFilterMode.all;
    selectedCycle = null;
    pageRange = PageRangeFilter.all;
    shelf = null;
  }

  BookFilterCriteria copyWith({
    ReadingStatus? selectedStatus,
    ReadingStatus? status,
    BookFormat? format,
    bool? onlyWithKindleFile,
    Set<BookGenre>? genres,
    int? rating,
    CycleFilterMode? cycleMode,
    String? selectedCycle,
    PageRangeFilter? pageRange,
    ShelfLocation? shelf,
  }) {
    return BookFilterCriteria(
      status: selectedStatus ?? status ?? this.status,
      format: format ?? this.format,
      onlyWithKindleFile: onlyWithKindleFile ?? this.onlyWithKindleFile,
      genres: genres ?? Set<BookGenre>.from(this.genres),
      rating: rating ?? this.rating,
      cycleMode: cycleMode ?? this.cycleMode,
      selectedCycle: selectedCycle ?? this.selectedCycle,
      pageRange: pageRange ?? this.pageRange,
      shelf: shelf ?? this.shelf,
    );
  }
}
