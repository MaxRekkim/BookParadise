import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/reading_note.dart';
import '../../data/services/notes_service.dart';
import '../../data/services/theme_service.dart';
import '../view_models/library_view_model.dart';
import 'markdown_editor_view.dart';

class NotesJournalView extends StatefulWidget {
  const NotesJournalView({super.key});

  @override
  State<NotesJournalView> createState() => _NotesJournalViewState();
}

class _NotesJournalViewState extends State<NotesJournalView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedTag;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesService = context.watch<NotesService>();
    final themeService = context.watch<ThemeService>();
    final accent = themeService.currentAccentColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    var allNotes = notesService.search(_searchQuery);
    if (_selectedTag != null) {
      allNotes = allNotes.where((n) => n.tags.contains(_selectedTag)).toList();
    }

    final pinnedNotes = allNotes.where((n) => n.isPinned).toList();
    final regularNotes = allNotes.where((n) => !n.isPinned).toList();

    // Сбор уникальных тегов
    final allTags = <String>{};
    for (final n in notesService.notes) {
      allTags.addAll(n.tags);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Дневник заметок (Studio)', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Новая заметка',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MarkdownEditorView()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Поле поиска
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по конспектам, идеям, цитатам...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),

          // Горизонтальный скролл тегов
          if (allTags.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Все'),
                    selected: _selectedTag == null,
                    onSelected: (_) {
                      setState(() {
                        _selectedTag = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ...allTags.map((tag) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text('#$tag'),
                      selected: _selectedTag == tag,
                      onSelected: (selected) {
                        setState(() {
                          _selectedTag = selected ? tag : null;
                        });
                      },
                    ),
                  )),
                ],
              ),
            ),

          const SizedBox(height: 6),

          // Список заметок
          Expanded(
            child: allNotes.isEmpty
                ? _buildEmptyState(accent)
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    children: [
                      if (pinnedNotes.isNotEmpty) ...[
                        const Row(
                          children: [
                            Icon(Icons.push_pin, size: 16, color: Colors.orange),
                            SizedBox(width: 6),
                            Text('Закрепленные', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...pinnedNotes.map((n) => _buildNoteCard(n, accent, isDark)),
                        const SizedBox(height: 16),
                      ],
                      if (regularNotes.isNotEmpty) ...[
                        Text('Все записи (${regularNotes.count})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 8),
                        ...regularNotes.map((n) => _buildNoteCard(n, accent, isDark)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MarkdownEditorView()),
          );
        },
        backgroundColor: accent,
        child: const Icon(Icons.edit_note, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notes, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'Заметок пока нет',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Создавайте красивые Markdown конспекты, записывайте озарения и цитаты из прочитанных книг.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MarkdownEditorView()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Создать первую заметку'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(ReadingNote note, Color accent, bool isDark) {
    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        NotesService.instance.deleteNote(note.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E222A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MarkdownEditorView(note: note)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Верхний ряд: Название, книга, пин
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (note.bookTitle != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.menu_book, size: 12, color: accent),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    note.bookTitle!,
                                    style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 18,
                        color: note.isPinned ? Colors.orange : Colors.grey,
                      ),
                      onPressed: () {
                        NotesService.instance.togglePin(note.id);
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Фрагмент текста
                Text(
                  note.excerpt,
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[700], height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Теги и статистика
                Row(
                  children: [
                    ...note.tags.take(3).map((t) => Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('#$t', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    )),
                    const Spacer(),
                    Text(
                      '${note.wordCount} сл. • ${note.readingTimeMinutes} мин',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension on List {
  int get count => length;
}
