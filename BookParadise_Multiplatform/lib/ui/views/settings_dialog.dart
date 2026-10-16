import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/theme_service.dart';
import '../../data/services/google_sheets_service.dart';
import '../../data/services/lending_service.dart';
import '../../data/services/quotes_service.dart';
import '../../data/services/markdown_export_service.dart';
import '../view_models/library_view_model.dart';
import 'lending_list_screen.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final _apiUrlController = TextEditingController();
  final _kindleEmailController = TextEditingController();

  static const _prefsKeyKindleEmail = 'bp_kindle_email';

  @override
  void initState() {
    super.initState();
    _apiUrlController.text = GoogleSheetsService.instance.apiUrl;
    _loadKindleEmail();
  }

  Future<void> _loadKindleEmail() async {
    final prefs = await SharedPreferences.getInstance();
    _kindleEmailController.text = prefs.getString(_prefsKeyKindleEmail) ?? '';
  }

  Future<void> _saveSettings() async {
    await GoogleSheetsService.instance.setApiUrl(_apiUrlController.text);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyKindleEmail, _kindleEmailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final lendingService = context.watch<LendingService>();
    final quotesService = context.watch<QuotesService>();
    final libraryVM = context.watch<LibraryViewModel>();

    return AlertDialog(
      title: const Text('Настройки'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Оформление
            const Text(
              'ОФОРМЛЕНИЕ',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppTheme.values.map((t) {
                final isSelected = themeService.selectedTheme == t;
                return ChoiceChip(
                  label: Text(t.title),
                  selected: isSelected,
                  onSelected: (_) => themeService.setTheme(t),
                );
              }).toList(),
            ),
            const Divider(height: 28),

            // 2. Книги у друзей
            const Text(
              'КНИГИ У ДРУЗЕЙ (ТРЕКЕР ДОЛГОВ)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.people_alt_outlined),
              label: Text('Управление отданными книгами (${lendingService.activeRecords.length})'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LendingListScreen()),
                );
              },
            ),
            const Divider(height: 28),

            // 3. Экспорт в Markdown (Obsidian / Notion)
            const Text(
              'ЭКСПОРТ В MARKDOWN (OBSIDIAN / NOTION)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.copy_all),
              label: const Text('Скопировать всю библиотеку в Markdown'),
              onPressed: () {
                final md = MarkdownExportService.instance.exportCatalogToMarkdown(
                  libraryVM.books,
                  quotesService.quotes,
                );
                Clipboard.setData(ClipboardData(text: md));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Каталог всей библиотеки скопирован в буфер для Obsidian!')),
                );
              },
            ),
            const Divider(height: 28),

            // 4. Google Таблица API
            const Text(
              'СИНХРОНИЗАЦИЯ С GOOGLE ТАБЛИЦЕЙ',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiUrlController,
              decoration: const InputDecoration(
                hintText: 'https://script.google.com/macros/s/.../exec',
                labelText: 'URL Google Apps Script',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 5. Kindle Email
            const Text(
              'ОТПРАВКА НА KINDLE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _kindleEmailController,
              decoration: const InputDecoration(
                hintText: 'user@kindle.com',
                labelText: 'Kindle Email',
                border: OutlineInputBorder(),
              ),
            ),
            const Divider(height: 28),

            // 6. Версия
            Center(
              child: Text(
                'Книжный Рай • Версия 2.5.0 (Сборка 10)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () async {
            await _saveSettings();
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Настройки успешно сохранены')),
              );
            }
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
