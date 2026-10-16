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

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
