import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/theme_service.dart';
import '../view_models/library_view_model.dart';
import '../views/library_view.dart';
import '../views/reading_session_screen.dart';
import '../views/quotes_view.dart';
import '../views/notes_journal_view.dart';
import '../views/book_oracle_screen.dart';
import '../views/settings_dialog.dart';

class FloatingQuickDock extends StatelessWidget {
  const FloatingQuickDock({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF16171B).withOpacity(0.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Поиск библиотеки
          _dockItem(
            icon: Icons.search,
            tooltip: 'Поиск по библиотеке',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LibraryView()),
              );
            },
          ),
          _divider(),

          // 2. Добавить книгу
          _dockItem(
            icon: Icons.add,
            tooltip: 'Добавить книгу',
            onTap: () {
              _showAddBookDialog(context);
            },
          ),
          _divider(),

          // 3. Таймер чтения
          _dockItem(
            icon: Icons.timer_outlined,
            tooltip: 'Сессия чтения',
            onTap: () {
              final viewModel = context.read<LibraryViewModel>();
              final reading = viewModel.books.where((b) => b.readPages > 0 && !b.isFinished).toList();
              if (reading.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ReadingSessionScreen(book: reading.first)),
                );
              } else if (viewModel.books.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ReadingSessionScreen(book: viewModel.books.first)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Сначала добавьте книгу в библиотеку')),
                );
              }
            },
          ),
          _divider(),

          // 4. Цитаты
          _dockItem(
            icon: Icons.format_quote_outlined,
            tooltip: 'Цитаты и открытки',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuotesView()),
              );
            },
          ),
          _divider(),

          // 5. Дневник заметок Markdown
          _dockItem(
            icon: Icons.edit_note_rounded,
            tooltip: 'Дневник и заметки',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotesJournalView()),
              );
            },
          ),
          _divider(),

          // 6. Книжный Оракул-Сомелье
          _dockItem(
            icon: Icons.auto_awesome,
            tooltip: 'Книжный Оракул-Сомелье',
            accentColor: const Color(0xFFE5B83B),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookOracleScreen()),
              );
            },
          ),
          _divider(),

          // 6. Переключение темы
          _dockItem(
            icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            tooltip: isDark ? 'Светлая тема' : 'Темная тема',
            onTap: () {
              themeService.toggleTheme();
            },
          ),
        ],
      ),
    );
  }

  Widget _dockItem({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? accentColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            child: Icon(
              icon,
              size: 20,
              color: accentColor ?? Colors.white.withOpacity(0.85),
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: Colors.white.withOpacity(0.12),
    );
  }

  void _showAddBookDialog(BuildContext context) {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final pagesController = TextEditingController();
    final viewModel = context.read<LibraryViewModel>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Быстрое добавление книги'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Название *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: authorController,
                decoration: const InputDecoration(labelText: 'Автор *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: pagesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Всего страниц'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              final t = titleController.text.trim();
              final a = authorController.text.trim();
              final p = int.tryParse(pagesController.text.trim()) ?? 0;
              if (t.isNotEmpty && a.isNotEmpty) {
                viewModel.addCustomBook(t, a, p);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Книга «$t» добавлена в библиотеку!')),
                );
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }
}
