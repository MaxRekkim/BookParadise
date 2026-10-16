import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session.dart';

class ReadingSessionService extends ChangeNotifier {
  static final ReadingSessionService instance = ReadingSessionService._internal();
  ReadingSessionService._internal() {
    _loadHistory();
  }

  bool _isActive = false;
  bool get isActive => _isActive;

  int _elapsedSeconds = 0;
  int get elapsedSeconds => _elapsedSeconds;

  int? _activeBookId;
  int? get activeBookId => _activeBookId;

  int _startPage = 0;
  int get startPage => _startPage;

  DateTime? _sessionStartTime;
  Timer? _ticker;

  List<ReadingSession> _sessionHistory = [];
  List<ReadingSession> get sessionHistory => _sessionHistory;
  List<ReadingSession> get history => _sessionHistory;

  static const String _prefsKeySessions = 'bp_reading_sessions_json';

  String get formattedTime {
    final hours = _elapsedSeconds ~/ 3600;
    final mins = (_elapsedSeconds % 3600) ~/ 60;
    final secs = _elapsedSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  void startSession(int bookId, int currentBookPage) {
    _activeBookId = bookId;
    _startPage = currentBookPage;
    _elapsedSeconds = 0;
    _sessionStartTime = DateTime.now();
    _isActive = true;

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });

    notifyListeners();
  }

  void pauseSession() {
    _ticker?.cancel();
    _isActive = false;
    notifyListeners();
  }

  void resumeSession() {
    if (_activeBookId != null) {
      _isActive = true;
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsedSeconds++;
        notifyListeners();
      });
      notifyListeners();
    }
  }

  Future<ReadingSession?> finishSession(int finalPage) async {
    _ticker?.cancel();
    _isActive = false;

    if (_activeBookId == null || _sessionStartTime == null) return null;

    final session = ReadingSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: _activeBookId!,
      startTime: _sessionStartTime!,
      endTime: DateTime.now(),
      startPage: _startPage,
      endPage: finalPage,
      durationSeconds: _elapsedSeconds,
    );

    _sessionHistory.insert(0, session);
    await _saveHistory();

    _activeBookId = null;
    _elapsedSeconds = 0;
    notifyListeners();
    return session;
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKeySessions);
    if (raw != null) {
      final decoded = json.decode(raw) as List;
      _sessionHistory = decoded.map((e) => ReadingSession.fromJson(e as Map<String, dynamic>)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_sessionHistory.map((s) => s.toJson()).toList());
    await prefs.setString(_prefsKeySessions, encoded);
  }

  // MARK: - Time to Finish & Wrapped Analytics
  double get averageSpeedPagesPerHour {
    final valid = _sessionHistory.where((s) => s.durationSeconds >= 60 && s.pagesRead > 0).toList();
    if (valid.isEmpty) return 40.0;
    final totalPages = valid.fold<int>(0, (sum, s) => sum + s.pagesRead);
    final totalHours = valid.fold<int>(0, (sum, s) => sum + s.durationSeconds) / 3600.0;
    if (totalHours <= 0) return 40.0;
    final sp = totalPages / totalHours;
    return sp.clamp(15.0, 150.0);
  }

  String formatEstimatedTime(int remainingPages) {
    if (remainingPages <= 0) return 'Книга прочитана';
    final speed = averageSpeedPagesPerHour;
    final totalMinutes = ((remainingPages / speed) * 60).round().clamp(1, 999999);
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    final evenings = ((totalMinutes / 45.0).ceil()).clamp(1, 9999);

    final timeStr = h > 0 ? (m > 0 ? '~$h ч $m мин' : '~$h ч') : '~$m мин';
    final eveningWord = evenings == 1 ? '1 вечер' : '$evenings вечера';
    return '$timeStr (около $eveningWord)';
  }

  int get totalReadingSeconds => _sessionHistory.fold<int>(0, (sum, s) => sum + s.durationSeconds);

  String get mostActiveWeekdayString {
    if (_sessionHistory.isEmpty) return 'Выходные';
    final counts = <int, int>{};
    for (final s in _sessionHistory) {
      final w = s.startTime.weekday;
      counts[w] = (counts[w] ?? 0) + 1;
    }
    int bestDay = 6;
    int maxCount = -1;
    counts.forEach((day, count) {
      if (count > maxCount) {
        maxCount = count;
        bestDay = day;
      }
    });
    switch (bestDay) {
      case DateTime.monday: return 'Понедельник';
      case DateTime.tuesday: return 'Вторник';
      case DateTime.wednesday: return 'Среда';
      case DateTime.thursday: return 'Четверг';
      case DateTime.friday: return 'Пятница';
      case DateTime.saturday: return 'Суббота';
      case DateTime.sunday: return 'Воскресенье';
      default: return 'Выходные';
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
