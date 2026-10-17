import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Сервис обновлений «по воздуху» (OTA) для Flutter (Android & Windows)
class UpdateService extends ChangeNotifier {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final String _repoOwner = 'MaxRekkim';
  final String _repoName = 'BookParadise';
  final String currentVersion = '3.2.0';

  bool _isChecking = false;
  bool get isChecking => _isChecking;

  bool _isUpdateAvailable = false;
  bool get isUpdateAvailable => _isUpdateAvailable;

  String _latestVersion = '';
  String get latestVersion => _latestVersion;

  String _releaseTitle = '';
  String get releaseTitle => _releaseTitle;

  String _releaseNotes = '';
  String get releaseNotes => _releaseNotes;

  String? _apkDownloadUrl;
  String? get apkDownloadUrl => _apkDownloadUrl;

  String? _windowsDownloadUrl;
  String? get windowsDownloadUrl => _windowsDownloadUrl;

  DateTime? _lastChecked;
  DateTime? get lastChecked => _lastChecked;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> checkForUpdates({bool silent = false}) async {
    if (_isChecking) return;
    _isChecking = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse('https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'BookParadise-Flutter/$currentVersion',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rawTag = data['tag_name'] as String? ?? '';
        final parsedVersion = rawTag.startsWith('v') ? rawTag.substring(1) : rawTag;

        _latestVersion = parsedVersion;
        _releaseTitle = data['name'] as String? ?? 'Версия $parsedVersion';
        _releaseNotes = data['body'] as String? ?? '';
        _lastChecked = DateTime.now();

        final assets = data['assets'] as List<dynamic>? ?? [];
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          final downloadUrl = asset['browser_download_url'] as String? ?? '';
          if (name.endsWith('-Android.apk')) {
            _apkDownloadUrl = downloadUrl;
          } else if (name.endsWith('-Windows-x64.zip')) {
            _windowsDownloadUrl = downloadUrl;
          }
        }

        _isUpdateAvailable = _isNewer(parsedVersion, currentVersion);
      } else {
        if (!silent) {
          _errorMessage = 'Не удалось связаться с сервером обновлений (${response.statusCode})';
        }
      }
    } catch (e) {
      if (!silent) {
        _errorMessage = e.toString();
      }
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  bool _isNewer(String remote, String local) {
    try {
      final rParts = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final lParts = local.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final maxLen = rParts.length > lParts.length ? rParts.length : lParts.length;

      for (int i = 0; i < maxLen; i++) {
        final r = i < rParts.length ? rParts[i] : 0;
        final l = i < lParts.length ? lParts[i] : 0;
        if (r > l) return true;
        if (r < l) return false;
      }
    } catch (_) {}
    return false;
  }
}
