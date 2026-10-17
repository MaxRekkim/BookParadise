import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/reading_note.dart';
import '../../data/services/notes_service.dart';
import '../../data/services/theme_service.dart';
import '../view_models/library_view_model.dart';

enum EditorMode { edit, preview, split }

enum EditorFontFamily { serif, sans, mono }

class MarkdownEditorView extends StatefulWidget {
  final ReadingNote? note;
  final int? initialBookId;

  const MarkdownEditorView({super.key, this.note, this.initialBookId});

  @override
  State<MarkdownEditorView> createState() => _MarkdownEditorViewState();
}

class _MarkdownEditorViewState extends State<MarkdownEditorView> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final TextEditingController _tagController = TextEditingController();

  EditorMode _mode = EditorMode.edit;
  EditorFontFamily _font = EditorFontFamily.serif;
  double _fontSize = 16.0;

  int? _selectedBookId;
  String? _selectedBookTitle;
  List<String> _tags = [];
  bool _isPinned = false;
  late String _noteId;
  late DateTime _createdAt;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      final n = widget.note!;
      _noteId = n.id;
      _titleController = TextEditingController(text: n.title);
      _contentController = TextEditingController(text: n.content);
      _selectedBookId = n.bookId;
      _selectedBookTitle = n.bookTitle;
      _tags = List.from(n.tags);
      _isPinned = n.isPinned;
      _createdAt = n.createdAt;
    } else {
      _noteId = DateTime.now().millisecondsSinceEpoch.toString();
      _titleController = TextEditingController();
      _contentController = TextEditingController();
      _selectedBookId = widget.initialBookId;
      _createdAt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  TextStyle _getTextStyle() {
    switch (_font) {
      case EditorFontFamily.serif:
        return TextStyle(fontFamily: 'Georgia', fontSize: _fontSize, height: 1.6);
      case EditorFontFamily.mono:
        return TextStyle(fontFamily: 'Courier', fontSize: _fontSize, height: 1.5);
      case EditorFontFamily.sans:
      default:
        return TextStyle(fontSize: _fontSize, height: 1.5);
    }
  }

  void _insertSnippet(String snippet) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    if (selection.isValid && selection.start >= 0 && selection.end >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, snippet);
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + snippet.length),
      );
    } else {
      final append = text.isEmpty ? snippet : (text.endsWith('\n') ? snippet : '\n$snippet');
      _contentController.text = text + append;
      _contentController.selection = TextSelection.collapsed(offset: _contentController.text.length);
    }
    setState(() {});
  }

  void _saveNote() {
    final title = _titleController.text.trim().isEmpty ? 'Без названия' : _titleController.text.trim();
    final note = ReadingNote(
      id: _noteId,
      bookId: _selectedBookId,
      bookTitle: _selectedBookTitle,
      title: title,
      content: _contentController.text,
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
      tags: _tags,
      isPinned: _isPinned,
    );

    NotesService.instance.saveNote(note);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final accent = themeService.currentAccentColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 720;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleController.text.isEmpty ? 'Новая заметка' : _titleController.text, maxLines: 1),
        actions: [
          // Кнопка сохранения
          TextButton.icon(
            onPressed: _saveNote,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Сохранить', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Верхний тулбар управления режимом и типографикой
          _buildTopBar(accent, isDark),
          const Divider(height: 1),

          // Основное рабочее пространство
          Expanded(
            child: _buildBodyWorkspace(isWide, isDark),
          ),
          const Divider(height: 1),

          // Нижняя панель действий и Markdown сниппетов
          _buildBottomToolbar(accent, isDark),
        ],
      ),
    );
  }

  Widget _buildTopBar(Color accent, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E222A) : const Color(0xFFF1F5F9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // Селектор режима Редактор / Просмотр / Сплит
          SegmentedButton<EditorMode>(
            segments: const [
              ButtonSegment(value: EditorMode.edit, label: Text('Текст')),
              ButtonSegment(value: EditorMode.preview, label: Text('Превью')),
              ButtonSegment(value: EditorMode.split, label: Text('Сплит')),
            ],
            selected: {_mode},
            onSelectionChanged: (val) {
              setState(() {
                _mode = val.first;
              });
            },
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const Spacer(),

          // Выбор шрифта и размера
          PopupMenuButton<String>(
            tooltip: 'Настройки типографики',
            icon: const Icon(Icons.text_format, size: 20),
            onSelected: (val) {
              setState(() {
                if (val == 'serif') _font = EditorFontFamily.serif;
                if (val == 'sans') _font = EditorFontFamily.sans;
                if (val == 'mono') _font = EditorFontFamily.mono;
                if (val == 'plus') _fontSize = math.min(24.0, _fontSize + 1.0);
                if (val == 'minus') _fontSize = math.max(12.0, _fontSize - 1.0);
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'serif', child: Text('Книжный Serif')),
              const PopupMenuItem(value: 'sans', child: Text('Современный Sans')),
              const PopupMenuItem(value: 'mono', child: Text('Моноширинный Mono')),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'plus', child: Text('Увеличить размер (${_fontSize.toInt() + 1}pt)')),
              PopupMenuItem(value: 'minus', child: Text('Уменьшить размер (${_fontSize.toInt() - 1}pt)')),
            ],
          ),

          // Привязка к книге
          IconButton(
            tooltip: 'Привязать к книге',
            icon: Icon(
              Icons.book,
              color: _selectedBookId != null ? accent : Colors.grey,
              size: 20,
            ),
            onPressed: _showBookPickerModal,
          ),

          // Экспорт
          IconButton(
            tooltip: 'Скопировать Markdown',
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _contentController.text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Markdown скопирован в буфер обмена')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBodyWorkspace(bool isWide, bool isDark) {
    if (_mode == EditorMode.edit) {
      return _buildEditorSection(isDark);
    } else if (_mode == EditorMode.preview) {
      return _buildPreviewSection(isDark);
    } else {
      if (isWide) {
        return Row(
          children: [
            Expanded(child: _buildEditorSection(isDark)),
            const VerticalDivider(width: 1),
            Expanded(child: _buildPreviewSection(isDark)),
          ],
        );
      } else {
        return _buildEditorSection(isDark);
      }
    }
  }

  Widget _buildEditorSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          // Заголовок
          TextField(
            controller: _titleController,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: 'Заголовок заметки или главы...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (_) => setState(() {}),
          ),

          // Теги
          _buildTagsBar(),
          const SizedBox(height: 8),

          // Тело заметки
          Expanded(
            child: TextField(
              controller: _contentController,
              maxLines: null,
              expands: true,
              style: _getTextStyle(),
              decoration: const InputDecoration(
                hintText: 'Пишите ваши мысли, конспект или цитаты здесь (поддерживается Markdown)...',
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsBar() {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._tags.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Chip(
                    label: Text('#$t', style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    onDeleted: () {
                      setState(() {
                        _tags.remove(t);
                      });
                    },
                  ),
                )),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _tagController,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: '+ тег',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (val) {
                      final trimmed = val.trim();
                      if (trimmed.isNotEmpty && !_tags.contains(trimmed)) {
                        setState(() {
                          _tags.add(trimmed);
                          _tagController.clear();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSection(bool isDark) {
    final text = _contentController.text;
    final lines = text.split('\n');

    return Container(
      color: isDark ? const Color(0xFF14171F) : const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(20.0),
      child: ListView(
        children: [
          if (_titleController.text.isNotEmpty)
            Text(
              _titleController.text,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          if (_selectedBookTitle != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Книга: $_selectedBookTitle',
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (text.isEmpty)
            const Text(
              'Здесь отобразится отформатированный превью вашей заметки...',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            )
          else
            ...lines.map((line) => _renderMarkdownLine(line, isDark)),
        ],
      ),
    );
  }

  Widget _renderMarkdownLine(String line, bool isDark) {
    if (line.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 14.0, bottom: 6.0),
        child: Text(line.substring(2), style: TextStyle(fontSize: _fontSize + 8, fontWeight: FontWeight.w900, fontFamily: _font == EditorFontFamily.serif ? 'Georgia' : null)),
      );
    } else if (line.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 10.0, bottom: 4.0),
        child: Text(line.substring(3), style: TextStyle(fontSize: _fontSize + 4, fontWeight: FontWeight.bold, fontFamily: _font == EditorFontFamily.serif ? 'Georgia' : null)),
      );
    } else if (line.startsWith('### ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
        child: Text(line.substring(4), style: TextStyle(fontSize: _fontSize + 2, fontWeight: FontWeight.w600, fontFamily: _font == EditorFontFamily.serif ? 'Georgia' : null)),
      );
    } else if (line.startsWith('> ')) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.08),
          border: const Border(left: BorderSide(color: Colors.orange, width: 4)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          line.substring(2),
          style: TextStyle(fontSize: _fontSize, fontStyle: FontStyle.italic, height: 1.5),
        ),
      );
    } else if (line.startsWith('- [ ] ')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_box_outline_blank, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(child: Text(line.substring(6), style: TextStyle(fontSize: _fontSize))),
          ],
        ),
      );
    } else if (line.startsWith('- [x] ') || line.startsWith('- [X] ')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_box, size: 18, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                line.substring(6),
                style: TextStyle(fontSize: _fontSize, decoration: TextDecoration.lineThrough, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    } else if (line.startsWith('- ') || line.startsWith('* ')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(child: Text(line.substring(2), style: TextStyle(fontSize: _fontSize))),
          ],
        ),
      );
    } else if (line.trim() == '---') {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Divider(),
      );
    } else if (line.trim().isEmpty) {
      return const SizedBox(height: 8);
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Text(line, style: _getTextStyle()),
      );
    }
  }

  Widget _buildBottomToolbar(Color accent, bool isDark) {
    final words = _contentController.text.trim().isEmpty
        ? 0
        : _contentController.text.trim().split(RegExp(r'\s+')).length;
    final mins = (words / 200).ceil().clamp(1, 999);

    return Container(
      color: isDark ? const Color(0xFF1E222A) : const Color(0xFFF1F5F9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // Кнопка слэш-команд
          FilledButton.tonalIcon(
            onPressed: _showSlashCommandsModal,
            icon: const Text('/', style: TextStyle(fontWeight: FontWeight.w900, fontFamily: 'monospace')),
            label: const Text('Сниппеты'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
          ),
          const SizedBox(width: 8),

          // Горизонтальный скролл быстрых тегов
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _snipButton('B', '**текст**'),
                  _snipButton('I', '*текст*'),
                  _snipButton('H1', '\n# Заголовок\n'),
                  _snipButton('H2', '\n## Подзаголовок\n'),
                  _snipButton('Цитата', '\n> "Цитата"\n'),
                  _snipButton('Список', '\n- Пункт\n'),
                  _snipButton('Чекбокс', '\n- [ ] Задача\n'),
                  _snipButton('Инсайт', '\n💡 **Инсайт**: \n'),
                  _snipButton('Спойлер', '\n> ⚠️ **Спойлер**: \n'),
                  _snipButton('Черта', '\n---\n'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Счетчик слов
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$words сл.', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              Text('~$mins мин', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _snipButton(String label, String snippet) {
    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: OutlinedButton(
        onPressed: () => _insertSnippet(snippet),
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11)),
      ),
    );
  }

  void _showSlashCommandsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Команды быстрого форматирования', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Выберите нужный блок для вставки в текст'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.title),
              title: const Text('Заголовок H1 / H2'),
              subtitle: const Text('Крупные разделы конспекта'),
              onTap: () {
                Navigator.pop(ctx);
                _insertSnippet('\n# Заголовок\n');
              },
            ),
            ListTile(
              leading: const Icon(Icons.format_quote),
              title: const Text('Цитата книги (>)'),
              subtitle: const Text('Цитата с выделенным фоном и полосой'),
              onTap: () {
                Navigator.pop(ctx);
                _insertSnippet('\n> "Цитата из книги"\n');
              },
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb_outline, color: Colors.amber),
              title: const Text('Инсайт читателя (💡)'),
              subtitle: const Text('Ключевой вывод или озарение'),
              onTap: () {
                Navigator.pop(ctx);
                _insertSnippet('\n💡 **Инсайт**: \n');
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_box_outlined),
              title: const Text('Список задач (- [ ])'),
              subtitle: const Text('Интерактивный список дел'),
              onTap: () {
                Navigator.pop(ctx);
                _insertSnippet('\n- [ ] Прочитать главу\n- [ ] Записать мысли\n');
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
              title: const Text('Спойлер (⚠️)'),
              subtitle: const Text('Предупреждение о сюжетном повороте'),
              onTap: () {
                Navigator.pop(ctx);
                _insertSnippet('\n> ⚠️ **Осторожно, спойлер**: \n');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showBookPickerModal() {
    final viewModel = context.read<LibraryViewModel>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          children: [
            const ListTile(
              title: Text('Связать заметку с книгой', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Выберите книгу из вашей библиотеки'),
            ),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('Без книги (Общий дневник)'),
              onTap: () {
                setState(() {
                  _selectedBookId = null;
                  _selectedBookTitle = null;
                });
                Navigator.pop(ctx);
              },
            ),
            Expanded(
              child: ListView.builder(
                itemCount: viewModel.books.length,
                itemBuilder: (context, index) {
                  final b = viewModel.books[index];
                  final isSelected = _selectedBookId == b.id;
                  return ListTile(
                    leading: const Icon(Icons.book),
                    title: Text(b.title),
                    subtitle: Text(b.author),
                    trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                    onTap: () {
                      setState(() {
                        _selectedBookId = b.id;
                        _selectedBookTitle = b.title;
                      });
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
