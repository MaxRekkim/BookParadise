import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lending_record.dart';

class LendingService extends ChangeNotifier {
  static final LendingService instance = LendingService._internal();

  LendingService._internal() {
    _loadRecords();
  }

  List<BookLendingRecord> _records = [];
  List<BookLendingRecord> get records => _records;

  List<BookLendingRecord> get activeRecords =>
      _records.where((r) => !r.isReturned).toList()
        ..sort((a, b) => (a.dueDate ?? DateTime(2099))
            .compareTo(b.dueDate ?? DateTime(2099)));

  List<BookLendingRecord> get overdueRecords =>
      activeRecords.where((r) => r.isOverdue).toList();

  BookLendingRecord? activeLendingForBook(String bookId) {
    try {
      return _records.firstWhere((r) => r.bookId == bookId && !r.isReturned);
    } catch (_) {
      return null;
    }
  }

  static const String _prefsKeyLending = 'bp_lending_records_json';

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKeyLending);
    if (raw != null) {
      try {
        final decoded = json.decode(raw) as List;
        _records = decoded
            .map((e) => BookLendingRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Error loading lending records: $e');
      }
    }
    notifyListeners();
  }

  Future<void> _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_records.map((r) => r.toJson()).toList());
    await prefs.setString(_prefsKeyLending, encoded);
    notifyListeners();
  }

  Future<void> lendBook({
    required String bookId,
    required String bookTitle,
    required String personName,
    String? contact,
    DateTime? dueDate,
    LendingType type = LendingType.lent,
    String? notes,
  }) async {
    final trimmedName = personName.trim();
    if (trimmedName.isEmpty) return;

    // Закрываем предыдущую активную запись по этой книге, если была
    final existingIdx =
        _records.indexWhere((r) => r.bookId == bookId && !r.isReturned);
    if (existingIdx != -1) {
      final old = _records[existingIdx];
      _records[existingIdx] = BookLendingRecord(
        id: old.id,
        bookId: old.bookId,
        bookTitle: old.bookTitle,
        personName: old.personName,
        contact: old.contact,
        lentDate: old.lentDate,
        dueDate: old.dueDate,
        isReturned: true,
        returnDate: DateTime.now(),
        notes: old.notes,
        type: old.type,
      );
    }

    final newRecord = BookLendingRecord(
      id: 'lend_${DateTime.now().millisecondsSinceEpoch}',
      bookId: bookId,
      bookTitle: bookTitle,
      personName: trimmedName,
      contact: contact?.trim(),
      lentDate: DateTime.now(),
      dueDate: dueDate,
      isReturned: false,
      notes: notes?.trim(),
      type: type,
    );

    _records.insert(0, newRecord);
    await _saveRecords();
  }

  Future<void> markReturned(String id) async {
    final idx = _records.indexWhere((r) => r.id == id);
    if (idx != -1) {
      final rec = _records[idx];
      _records[idx] = BookLendingRecord(
        id: rec.id,
        bookId: rec.bookId,
        bookTitle: rec.bookTitle,
        personName: rec.personName,
        contact: rec.contact,
        lentDate: rec.lentDate,
        dueDate: rec.dueDate,
        isReturned: true,
        returnDate: DateTime.now(),
        notes: rec.notes,
        type: rec.type,
      );
      await _saveRecords();
    }
  }

  Future<void> deleteRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
    await _saveRecords();
  }
}
