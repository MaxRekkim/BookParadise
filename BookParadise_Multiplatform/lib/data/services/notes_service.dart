import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_note.dart';

class NotesService extends ChangeNotifier {
  static final NotesService instance = NotesService._internal();
  NotesService._internal() {
    _loadNotes();
  }

  List<ReadingNote> _notes = [];
  List<ReadingNote> get notes => List.unmodifiable(_notes);

  static const String _prefsKeyNotes = 'bp_reading_notes_json';

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKeyNotes);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        _notes = list.map((item) => ReadingNote.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        _createDefaultSample();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notes: $e');
      _createDefaultSample();
    }
  }

  void _createDefaultSample() {
    _notes = [
      ReadingNote(
        id: 'sample-1',
        title: 'Глубокая работа и фокус',
        content: '''# Размышления о ценности сосредоточенного чтения

> "Способность концентрироваться на трудной задаче без отвлечений — это суперсила XXI века."

## Ключевые идеи
- Чтение сложных объемных книг перестраивает нейронные связи в коре мозга.
- Ежедневный блок в 45 минут без уведомлений дает больший эффект, чем хаотичные попытки читать урывками.

### Список шагов к идеальной читательской привычке:
- [x] Отложить телефон в другую комнату перед началом чтения
- [x] Заварить чай и включить теплый библиотечный свет
- [ ] Записать главную мысль главы в этот Markdown Studio

💡 **Инсайт**: Чтобы книга осталась в памяти, нужно связать хотя бы один ее тезис с собственным жизненным опытом.''',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['Инсайт', 'Фокус', 'Привычки'],
        isPinned: true,
      ),
    ];
    _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _notes.map((n) => n.toJson()).toList();
      await prefs.setString(_prefsKeyNotes, jsonEncode(list));
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving notes: $e');
    }
  }

  Future<void> saveNote(ReadingNote note) async {
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx >= 0) {
      note.updatedAt = DateTime.now();
      _notes[idx] = note;
    } else {
      _notes.insert(0, note);
    }
    await _persist();
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await _persist();
  }

  Future<void> togglePin(String id) async {
    final idx = _notes.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      _notes[idx].isPinned = !_notes[idx].isPinned;
      await _persist();
    }
  }

  List<ReadingNote> notesForBook(int bookId) {
    return _notes.where((n) => n.bookId == bookId).toList();
  }

  List<ReadingNote> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _notes;
    return _notes.where((n) =>
      n.title.toLowerCase().contains(q) ||
      n.content.toLowerCase().contains(q) ||
      (n.bookTitle?.toLowerCase().contains(q) ?? false) ||
      n.tags.any((t) => t.toLowerCase().contains(q))
    ).toList();
  }
}
