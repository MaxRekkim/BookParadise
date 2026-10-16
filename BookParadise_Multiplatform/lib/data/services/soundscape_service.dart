import 'package:flutter/material.dart';

enum SoundscapeMode {
  none,
  rain,
  fireplace,
  coffeehouse,
  forest,
}

extension SoundscapeModeExtension on SoundscapeMode {
  String get title {
    switch (this) {
      case SoundscapeMode.none:
        return 'Тишина';
      case SoundscapeMode.rain:
        return 'Дождь за окном';
      case SoundscapeMode.fireplace:
        return 'Камин в библиотеке';
      case SoundscapeMode.coffeehouse:
        return 'Уютная кофейня';
      case SoundscapeMode.forest:
        return 'Лесной бриз';
    }
  }

  IconData get icon {
    switch (this) {
      case SoundscapeMode.none:
        return Icons.volume_off;
      case SoundscapeMode.rain:
        return Icons.water_drop;
      case SoundscapeMode.fireplace:
        return Icons.local_fire_department;
      case SoundscapeMode.coffeehouse:
        return Icons.coffee;
      case SoundscapeMode.forest:
        return Icons.forest;
    }
  }

  Color get accentColor {
    switch (this) {
      case SoundscapeMode.none:
        return Colors.grey;
      case SoundscapeMode.rain:
        return Colors.blue;
      case SoundscapeMode.fireplace:
        return Colors.orange;
      case SoundscapeMode.coffeehouse:
        return const Color(0xFF8D6E63);
      case SoundscapeMode.forest:
        return Colors.green;
    }
  }
}

class SoundscapeService extends ChangeNotifier {
  static final SoundscapeService instance = SoundscapeService._internal();
  SoundscapeService._internal();

  SoundscapeMode _mode = SoundscapeMode.none;
  SoundscapeMode get mode => _mode;

  double _volume = 0.5;
  double get volume => _volume;

  void setMode(SoundscapeMode newMode) {
    if (_mode == newMode) return;
    _mode = newMode;
    notifyListeners();
  }

  void setVolume(double newVolume) {
    _volume = newVolume.clamp(0.0, 1.0);
    notifyListeners();
  }

  void stop() {
    _mode = SoundscapeMode.none;
    notifyListeners();
  }
}
