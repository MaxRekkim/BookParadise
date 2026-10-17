import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/book.dart';
import '../../data/models/bingo_and_cycle.dart';
import '../../data/models/enums.dart';
import '../../data/models/sample_data.dart';
import '../../data/services/google_sheets_service.dart';

enum LibraryLayoutMode {
  grid,
  list,
  bookshelf,
}

class LibraryViewModel extends ChangeNotifier {
  final GoogleSheetsService _api = GoogleSheetsService.instance;

  List<Book> _books = [];
  List<Book> get books => _books;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  BookGenre? _selectedGenre;
  BookGenre? get selectedGenre => _selectedGenre;

  final BookFilterCriteria filterCriteria = BookFilterCriteria();

  int _annualGoal = 30;
  int get annualGoal => _annualGoal;

  LibraryLayoutMode _layoutMode = LibraryLayoutMode.grid;
  LibraryLayoutMode get layoutMode => _layoutMode;

  static const String _prefsKeyAnnualGoal = 'bp_annual_goal_count';

  LibraryViewModel() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _annualGoal = prefs.getInt(_prefsKeyAnnualGoal) ?? 30;

    await _api.init();
    final cached = await _api.loadCachedBooks();
    if (cached.isNotEmpty) {
      _books = cached;
    } else {
      _books = SampleData.books;
    }

    _isLoading = false;
    notifyListeners();

    // Background refresh
    refreshFromCloud();
  }

  Future<void> refreshFromCloud() async {
    if (!_api.isConfigured) return;
    _isLoading = true;
    notifyListeners();

    try {
      final remote = await _api.fetchBooks();
      if (remote.isNotEmpty) {
        _books = remote;
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setGenreFilter(BookGenre? genre) {
    _selectedGenre = genre;
    notifyListeners();
  }

  void clearFilters() {
    filterCriteria.reset();
    _searchQuery = '';
    _selectedGenre = null;
    notifyListeners();
  }

  void setStatusFilter(ReadingStatus? status) {
    filterCriteria.reset();
    filterCriteria.status = status;
    _searchQuery = '';
    _selectedGenre = null;
    notifyListeners();
  }

  void updateFilterCriteria(BookFilterCriteria criteria) {
    filterCriteria.status = criteria.status;
    filterCriteria.format = criteria.format;
    filterCriteria.onlyWithKindleFile = criteria.onlyWithKindleFile;
    filterCriteria.genres = Set<BookGenre>.from(criteria.genres);
    filterCriteria.rating = criteria.rating;
    filterCriteria.cycleMode = criteria.cycleMode;
    filterCriteria.selectedCycle = criteria.selectedCycle;
    filterCriteria.pageRange = criteria.pageRange;
    filterCriteria.shelf = criteria.shelf;
    notifyListeners();
  }

  void setLayoutMode(LibraryLayoutMode mode) {
    if (_layoutMode != mode) {
      _layoutMode = mode;
      notifyListeners();
    }
  }

  Future<void> setAnnualGoal(int newGoal) async {
    _annualGoal = newGoal.clamp(5, 500);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKeyAnnualGoal, _annualGoal);
    notifyListeners();
  }

  // MARK: - JSON Backup & Restore
  String exportJsonBackup() {
    final list = _books.map((b) => b.toJson()).toList();
    final data = {
      'version': '2.10.0',
      'exportDate': DateTime.now().toIso8601String(),
      'annualGoal': _annualGoal,
      'booksCount': list.length,
      'books': list,
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<int> importJsonBackup(String jsonStr) async {
    final decoded = json.decode(jsonStr);
    List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map && decoded['books'] is List) {
      list = decoded['books'] as List;
      if (decoded['annualGoal'] is int) {
        await setAnnualGoal(decoded['annualGoal'] as int);
      }
    } else {
      throw const FormatException('Неверный формат файла резервной копии');
    }

    final newBooks = list
        .map((item) => Book.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    if (newBooks.isEmpty) {
      throw const FormatException('В файле резервной копии не найдено книг');
    }

    _books = newBooks;
    await _api.saveCachedBooks(_books);
    notifyListeners();
    return newBooks.length;
  }

  // MARK: - Filtered Books (Multi-parameter Filtering)
  List<Book> get filteredBooks {
    var result = List<Book>.from(_books);

    // Search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      result = result.where((b) =>
          b.title.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q) ||
          (b.cycle?.toLowerCase().contains(q) ?? false)).toList();
    }

    // Top chip genre filter
    if (_selectedGenre != null) {
      result = result.where((b) => b.genre == _selectedGenre).toList();
    }

    // Modal Sheet Filter Criteria
    if (filterCriteria.isActive) {
      if (filterCriteria.status != null) {
        result = result.where((b) => b.status == filterCriteria.status).toList();
      }

      if (filterCriteria.format != null) {
        result = result.where((b) => b.format == filterCriteria.format).toList();
      }

      if (filterCriteria.onlyWithKindleFile) {
        result = result.where((b) => b.hasKindleFile).toList();
      }

      if (filterCriteria.genres.isNotEmpty) {
        result = result.where((b) => filterCriteria.genres.contains(b.genre)).toList();
      }

      if (filterCriteria.rating != null) {
        result = result.where((b) {
          final r = int.tryParse(b.rating ?? '') ?? 0;
          return r == filterCriteria.rating;
        }).toList();
      }

      if (filterCriteria.shelf != null) {
        result = result.where((b) => b.shelfLocation == filterCriteria.shelf).toList();
      }

      if (filterCriteria.pageRange != PageRangeFilter.all) {
        result = result.where((b) => filterCriteria.pageRange.matches(b.totalPages)).toList();
      }

      switch (filterCriteria.cycleMode) {
        case CycleFilterMode.all:
          break;
        case CycleFilterMode.inCycle:
          result = result.where((b) => b.cycle != null && b.cycle!.trim().isNotEmpty).toList();
          break;
        case CycleFilterMode.standalone:
          result = result.where((b) => b.cycle == null || b.cycle!.trim().isEmpty).toList();
          break;
        case CycleFilterMode.specificCycle:
          if (filterCriteria.selectedCycle != null) {
            result = result.where((b) => b.cycle == filterCriteria.selectedCycle).toList();
          }
          break;
      }
    }

    return result;
  }

  // MARK: - Cycles
  List<CycleInfo> get cycles {
    final Map<String, List<Book>> map = {};
    for (var b in _books) {
      if (b.cycle != null && b.cycle!.trim().isNotEmpty) {
        final key = b.cycle!.trim();
        map.putIfAbsent(key, () => []).add(b);
      }
    }

    final list = map.entries.map((e) {
      e.value.sort((a, b) => (a.cycleOrder ?? 0).compareTo(b.cycleOrder ?? 0));
      return CycleInfo(name: e.key, books: e.value);
    }).toList();

    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  // MARK: - Bingo Items
  List<BingoItem> get bingoItems {
    final list = <BingoItem>[];
    for (var b in _books) {
      if (b.planMonth != null && b.planMonth!.trim().isNotEmpty) {
        list.add(BingoItem(
          id: b.id,
          title: b.title,
          author: b.author,
          planMonth: b.planMonth!.trim(),
          planDays: b.planDays ?? 0,
          totalPages: b.totalPages,
          readPages: b.readPages,
          coverURL: b.cleanCoverURL,
        ));
      }
    }
    return list;
  }

  // MARK: - Statistics
  ReadingStats get stats {
    int read = 0;
    int inProgress = 0;
    int planned = 0;
    int totalPages = 0;
    int ratedCount = 0;
    double ratingSum = 0.0;

    for (var b in _books) {
      if (b.isFinished) {
        read++;
        totalPages += b.totalPages;
      } else if (b.readPages > 0) {
        inProgress++;
        totalPages += b.readPages;
      } else {
        planned++;
      }

      final r = double.tryParse(b.rating ?? '');
      if (r != null && r > 0) {
        ratedCount++;
        ratingSum += r;
      }
    }

    return ReadingStats(
      totalBooks: _books.length,
      readBooks: read,
      inProgressBooks: inProgress,
      plannedBooks: planned,
      totalPagesRead: totalPages,
      averageRating: ratedCount > 0 ? ratingSum / ratedCount : 0.0,
    );
  }

  // MARK: - Actions
  Future<void> updateProgress(int bookId, int newPages, {String? rating, String? notes}) async {
    final idx = _books.indexIndex((b) => b.id == bookId);
    if (idx != -1) {
      final b = _books[idx];
      b.readPages = newPages.clamp(0, b.totalPages);
      if (rating != null) b.rating = rating;
      if (notes != null) b.notes = notes;
      b.status = ReadingStatus.fromRaw(b.readPages, b.totalPages, b.rating);

      await _api.saveCachedBooks(_books);
      notifyListeners();

      await _api.postUpdateProgress(
        bookId: bookId,
        readPages: b.readPages,
        rating: b.rating,
        notes: b.notes,
      );
    }
  }

  Future<void> updateReview(int bookId, String reviewText) async {
    final idx = _books.indexIndex((b) => b.id == bookId);
    if (idx != -1) {
      _books[idx].review = reviewText.trim().isEmpty ? null : reviewText;
      await _api.saveCachedBooks(_books);
      notifyListeners();
    }
  }

  Future<void> removeFromBingo(BingoItem item) async {
    final idx = _books.indexIndex((b) => b.id == item.id);
    if (idx != -1) {
      _books[idx].planMonth = null;
      await _api.saveCachedBooks(_books);
      notifyListeners();
      await _api.postUpdatePlan(bookId: item.id, month: '', planDays: 0);
    }
  }

  Future<void> addBook(Book book) async {
    _books.insert(0, book);
    await _api.saveCachedBooks(_books);
    notifyListeners();
    await _api.postAddBook(book);
  }

  Future<void> addCustomBook(String title, String author, int totalPages) async {
    final newBook = Book(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      author: author,
      totalPages: totalPages > 0 ? totalPages : 300,
      status: ReadingStatus.planned,
    );
    await addBook(newBook);
  }

  Future<void> updateBook(Book book) async {
    final idx = _books.indexWhere((b) => b.id == book.id);
    if (idx != -1) {
      _books[idx] = book;
      await _api.saveCachedBooks(_books);
      notifyListeners();
    }
  }
}

extension on List<Book> {
  int indexIndex(bool Function(Book) test) {
    for (int i = 0; i < length; i++) {
      if (test(this[i])) return i;
    }
    return -1;
  }
}
