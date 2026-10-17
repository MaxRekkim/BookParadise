import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/theme_service.dart';
import '../../data/services/google_sheets_service.dart';
import '../../data/services/quotes_service.dart';
import '../../data/services/markdown_export_service.dart';
import '../../data/services/update_service.dart';
import '../view_models/library_view_model.dart';

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

            // 1.5. Обновление ПО «по воздуху» (OTA)
            Builder(
              builder: (ctx) {
                final updateService = ctx.watch<UpdateService>();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ОБНОВЛЕНИЕ ПО (OTA)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                        if (updateService.isChecking)
                          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          TextButton(
                            onPressed: () => updateService.checkForUpdates(),
                            child: const Text('Проверить', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    Text(
                      'Текущая версия: v${updateService.currentVersion} (Build 20)',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (updateService.isUpdateAvailable) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.pad(BorderSide(color: Colors.amber.withOpacity(0.3))),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.bolt, color: Colors.amber, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Доступна версия v${updateService.latestVersion}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            if (updateService.releaseTitle.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(updateService.releaseTitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ),
                          ],
                        ),
                      ),
                    ] else if (updateService.lastChecked != null && !updateService.isChecking) ...[
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 14),
                          SizedBox(width: 4),
                          Text('Установлена актуальная версия', style: TextStyle(fontSize: 11, color: Colors.green)),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
            const Divider(height: 28),

            // 2. Экспорт в Markdown (Obsidian / Notion)
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

            // 3.5. Резервная копия (JSON Backup & Restore)
            const Text(
              'РЕЗЕРВНАЯ КОПИЯ И ВОССТАНОВЛЕНИЕ (JSON)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('Экспорт JSON', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      final jsonString = libraryVM.exportJsonBackup();
                      Clipboard.setData(ClipboardData(text: jsonString));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Резервная копия всей библиотеки скопирована в буфер обмена!')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.file_upload_outlined, size: 18),
                    label: const Text('Импорт JSON', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      _showImportJsonDialog(context, libraryVM);
                    },
                  ),
                ),
              ],
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
                'Книжный Рай • Версия 2.11.0 (Сборка 16)',
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

  void _showImportJsonDialog(BuildContext context, LibraryViewModel libraryVM) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Импорт из JSON'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Вставьте содержимое резервной копии в формате JSON. Существующая библиотека будет заменена данными из бэкапа.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 8,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              decoration: const InputDecoration(
                hintText: '{\n  "version": "2.11.0",\n  "books": [...]\n}',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () async {
              final raw = controller.text.trim();
              if (raw.isEmpty) return;
              try {
                final count = await libraryVM.importJsonBackup(raw);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Успешно восстановлено книг: $count')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  showDialog(
                    context: ctx,
                    builder: (_) => AlertDialog(
                      title: const Text('Ошибка импорта'),
                      content: Text('$e'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(_),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            child: const Text('Восстановить'),
          ),
        ],
      ),
    );
  }
}
