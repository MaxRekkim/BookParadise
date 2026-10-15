import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../models/bingo_and_cycle.dart';

class GoogleSheetsService {
  static final GoogleSheetsService instance = GoogleSheetsService._internal();
  GoogleSheetsService._internal();

  String _apiUrl = '';
  String get apiUrl => _apiUrl;
  bool get isConfigured => _apiUrl.isNotEmpty;

  static const String _prefsKeyApiUrl = 'bp_google_sheets_api_url';
  static const String _prefsKeyBooksCache = 'bp_books_cache_json';
  static const String _prefsKeyBingoCache = 'bp_bingo_cache_json';
  static const String _prefsKeyOfflineQueue = 'bp_offline_queue_json';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _apiUrl = prefs.getString(_prefsKeyApiUrl) ?? '';
  }

  Future<void> setApiUrl(String url) async {
    _apiUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyApiUrl, _apiUrl);
  }

  // MARK: - GET: Загрузка базы книг
  Future<List<Book>> fetchBooks() async {
    if (!isConfigured) {
      return loadCachedBooks();
    }

    try {
      final response = await http.get(Uri.parse(_apiUrl)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> items = [];
        if (decoded is List) {
          items = decoded;
        } else if (decoded is Map && decoded['books'] is List) {
          items = decoded['books'];
        }

        final books = items.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
        await saveCachedBooks(books);
        await processOfflineQueue();
        return books;
      }
    } catch (_) {
      // Offline fallback
    }

    return loadCachedBooks();
  }

  // MARK: - POST: Обновление прогресса
  Future<void> postUpdateProgress({required int bookId, required int readPages, String? rating, String? notes}) async {
    final payload = {
      'action': 'updateProgress',
      'id': '$bookId',
      'readPages': '$readPages',
      'rating': rating ?? '',
      'notes': notes ?? '',
    };
    await _sendOrQueue('updateProgress', payload);
  }

  // MARK: - POST: Обновление плана бинго
  Future<void> postUpdatePlan({required int bookId, String? month, required int planDays}) async {
    final payload = {
      'action': 'updatePlan',
      'id': '$bookId',
      'month': month ?? '',
      'planDays': '$planDays',
    };
    await _sendOrQueue('updatePlan', payload);
  }

  // MARK: - POST: Добавление новой книги
  Future<void> postAddBook(Book book) async {
    final payload = {
      'action': 'addBook',
      'id': '${book.id}',
      'title': book.title,
      'author': book.author,
      'totalPages': '${book.totalPages}',
      'genre': book.genre.title,
      'coverURL': book.coverURL ?? '',
      'format': book.format.title,
      'shelfLocation': book.shelfLocation.title,
      'cycle': book.cycle ?? '',
      'cycleOrder': '${book.cycleOrder ?? ""}',
      'cycleTotal': '${book.cycleTotal ?? ""}',
    };
    await _sendOrQueue('addBook', payload);
  }

  Future<void> _sendOrQueue(String action, Map<String, String> payload) async {
    if (!isConfigured) {
      await _queueAction(action, payload);
      return;
    }

    try {
      final res = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        await _queueAction(action, payload);
      }
    } catch (_) {
      await _queueAction(action, payload);
    }
  }

  Future<void> _queueAction(String action, Map<String, String> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKeyOfflineQueue);
    List<dynamic> queue = [];
    if (raw != null) {
      queue = json.decode(raw);
    }
    queue.add({'action': action, 'payload': payload});
    await prefs.setString(_prefsKeyOfflineQueue, json.encode(queue));
  }

  Future<void> processOfflineQueue() async {
    if (!isConfigured) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKeyOfflineQueue);
    if (raw == null) return;

    List<dynamic> queue = json.decode(raw);
    if (queue.isEmpty) return;

    List<dynamic> remaining = [];
    for (var item in queue) {
      try {
        final payload = item['payload'] as Map<String, dynamic>;
        final res = await http.post(
          Uri.parse(_apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(payload),
        ).timeout(const Duration(seconds: 10));

        if (res.statusCode != 200) {
          remaining.add(item);
        }
      } catch (_) {
        remaining.add(item);
      }
    }

    await prefs.setString(_prefsKeyOfflineQueue, json.encode(remaining));
  }

  // MARK: - Кэширование
  Future<void> saveCachedBooks(List<Book> books) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(books.map((b) => b.toJson()).toList());
    await prefs.setString(_prefsKeyBooksCache, encoded);
  }

  Future<List<Book>> loadCachedBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKeyBooksCache);
    if (raw != null) {
      final decoded = json.decode(raw) as List;
      return decoded.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
