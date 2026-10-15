import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quote.dart';

class QuotesService extends ChangeNotifier {
  static final QuotesService instance = QuotesService._internal();
  QuotesService._internal() {
    _loadQuotes();
  }

  List<BookQuote> _quotes = [];
  List<BookQuote> get quotes => _quotes;

  BookQuote? _currentQuote;
  BookQuote? get currentQuote => _currentQuote;

  static const String _prefsKeyQuotes = 'bp_quotes_json';

  Future<void> _loadQuotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKeyQuotes);
    if (raw != null) {
      final decoded = json.decode(raw) as List;
      _quotes = decoded.map((e) => BookQuote.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      // Default quotes
      _quotes = [
        BookQuote(
          id: 'q1',
          bookId: 1,
          text: 'Книга — это мечта, которую вы держите в руках.',
          note: 'Нил Гейман',
        ),
        BookQuote(
          id: 'q2',
          bookId: 2,
          text: 'Страх — это самый древний инстинкт, но именно он помогает нам оставаться людьми в критические моменты.',
          note: 'Классика детектива',
        ),
        BookQuote(
          id: 'q3',
          bookId: 3,
          text: 'Человек не знает, как много он может забыть, пока не начнет вспоминать.',
          note: 'Эрих Мария Ремарк',
        ),
      ];
      await _saveQuotes();
    }

    rotateQuote();
    notifyListeners();
  }

  Future<void> _saveQuotes() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_quotes.map((q) => q.toJson()).toList());
    await prefs.setString(_prefsKeyQuotes, encoded);
  }

  void rotateQuote() {
    if (_quotes.isEmpty) {
      _currentQuote = null;
      return;
    }
    final nextList = List<BookQuote>.from(_quotes)..shuffle();
    _currentQuote = nextList.first;
    notifyListeners();
  }

  Future<void> addQuote(BookQuote quote) async {
    _quotes.insert(0, quote);
    await _saveQuotes();
    notifyListeners();
  }

  Future<void> deleteQuote(String id) async {
    _quotes.removeWhere((q) => q.id == id);
    if (_currentQuote?.id == id) {
      rotateQuote();
    }
    await _saveQuotes();
    notifyListeners();
  }
}
