import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/book.dart';
import '../../data/services/reading_session_service.dart';
import '../view_models/library_view_model.dart';
import '../widgets/thinking_orb_widget.dart';

class ReadingSessionScreen extends StatelessWidget {
  final Book book;

  const ReadingSessionScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final sessionService = context.watch<ReadingSessionService>();
    final libraryVM = context.watch<LibraryViewModel>();
    final primaryAccent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сессия чтения'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Верхняя карточка книги
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Icon(Icons.auto_stories, color: primaryAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Старт со страницы ${sessionService.startPage}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Центр: Дзен-сфера и секундомер
              Column(
                children: [
                  ThinkingOrbWidget(
                    size: 160,
                    state: sessionService.isActive ? OrbState.breathing : OrbState.idle,
                    color: primaryAccent,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    sessionService.formattedTime,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sessionService.isActive ? 'Фокус и концентрация...' : 'Пауза',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),

              // 3. Нижние кнопки управления
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          icon: Icon(sessionService.isActive ? Icons.pause : Icons.play_arrow),
                          label: Text(sessionService.isActive ? 'Пауза' : 'Продолжить'),
                          onPressed: () {
                            if (sessionService.isActive) {
                              sessionService.pauseSession();
                            } else {
                              sessionService.resumeSession();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Завершить'),
                          onPressed: () => _showFinishDialog(context, sessionService, libraryVM),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFinishDialog(BuildContext context, ReadingSessionService sessionService, LibraryViewModel libraryVM) {
    final controller = TextEditingController(text: '${sessionService.startPage}');
    final durationSec = sessionService.elapsedSeconds;
    final durationMins = (durationSec / 60).round();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Завершить чтение'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Время сессии: $durationMins мин.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'На какой странице остановились?',
                suffixText: 'из ${book.totalPages}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () async {
              final finalPage = int.tryParse(controller.text) ?? sessionService.startPage;
              final session = await sessionService.finishSession(finalPage);
              if (session != null) {
                await libraryVM.updateProgress(book.id, finalPage);
              }
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close session screen
            },
            child: const Text('Сохранить результат'),
          ),
        ],
      ),
    );
  }
}
