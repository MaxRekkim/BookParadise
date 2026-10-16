import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme {
  wineVelvet('Винный бархат'),
  midnightOxford('Полуночный оксфорд'),
  bookAmber('Книжный янтарь'),
  emeraldBinding('Изумрудный переплёт'),
  autoDayNight('Автосмена');

  final String title;
  const AppTheme(this.title);
}

class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._internal();
  ThemeService._internal() {
    _loadFromPrefs();
    _startTimer();
  }

  AppTheme _selectedTheme = AppTheme.wineVelvet;
  AppTheme get selectedTheme => _selectedTheme;

  AppTheme _effectiveTheme = AppTheme.wineVelvet;
  AppTheme get effectiveTheme => _effectiveTheme;

  Color _primaryAccent = const Color(0xFF8B263E);
  Color get primaryAccent => _primaryAccent;

  Color _secondaryAccent = const Color(0xFFC0586B);
  Color get secondaryAccent => _secondaryAccent;

  final Color paperBackgroundLight = const Color(0xFFFAF7F2);
  final Color paperBackgroundDark = const Color(0xFF141416);

  final Color cardBackgroundLight = Colors.white;
  final Color cardBackgroundDark = const Color(0xFF1F1F23);

  final Color cardBorderLight = const Color(0x15000000);
  final Color cardBorderDark = const Color(0x20FFFFFF);

  Timer? _timer;

  Color paperBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? paperBackgroundDark
        : paperBackgroundLight;
  }

  Color cardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? cardBackgroundDark
        : cardBackgroundLight;
  }

  Color cardBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? cardBorderDark
        : cardBorderLight;
  }

  void setTheme(AppTheme theme) {
    _selectedTheme = theme;
    _updateActiveColors();
    _saveToPrefs();
    notifyListeners();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_selectedTheme == AppTheme.autoDayNight) {
        _updateActiveColors();
        notifyListeners();
      }
    });
  }

  void _updateActiveColors() {
    final hour = DateTime.now().hour;
    final isEvening = hour >= 19 || hour < 7;

    if (_selectedTheme == AppTheme.autoDayNight) {
      _effectiveTheme = isEvening ? AppTheme.midnightOxford : AppTheme.wineVelvet;
    } else {
      _effectiveTheme = _selectedTheme;
    }

    switch (_effectiveTheme) {
      case AppTheme.wineVelvet:
        _primaryAccent = const Color(0xFF8B263E);
        _secondaryAccent = const Color(0xFFC0586B);
        break;
      case AppTheme.midnightOxford:
        _primaryAccent = const Color(0xFF1E3A8A);
        _secondaryAccent = const Color(0xFF3B82F6);
        break;
      case AppTheme.bookAmber:
        _primaryAccent = const Color(0xFFB45309);
        _secondaryAccent = const Color(0xFFF59E0B);
        break;
      case AppTheme.emeraldBinding:
        _primaryAccent = const Color(0xFF047857);
        _secondaryAccent = const Color(0xFF10B981);
        break;
      case AppTheme.autoDayNight:
        break;
    }
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('selectedThemeIndex') ?? AppTheme.wineVelvet.index;
    if (savedIndex >= 0 && savedIndex < AppTheme.values.length) {
      _selectedTheme = AppTheme.values[savedIndex];
    }
    _updateActiveColors();
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedThemeIndex', _selectedTheme.index);
  }

  ThemeData buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryAccent,
        brightness: brightness,
        primary: _primaryAccent,
        secondary: _secondaryAccent,
        surface: isDark ? cardBackgroundDark : cardBackgroundLight,
      ),
      scaffoldBackgroundColor: isDark ? paperBackgroundDark : paperBackgroundLight,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? paperBackgroundDark : paperBackgroundLight,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: isDark ? cardBackgroundDark : cardBackgroundLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? cardBorderDark : cardBorderLight),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
