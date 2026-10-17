import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/services/theme_service.dart';
import 'data/services/quotes_service.dart';
import 'data/services/reading_session_service.dart';
import 'data/services/lending_service.dart';
import 'data/services/soundscape_service.dart';
import 'data/services/achievement_service.dart';
import 'data/services/book_oracle_service.dart';
import 'data/services/notes_service.dart';
import 'data/services/update_service.dart';
import 'ui/view_models/library_view_model.dart';
import 'ui/views/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: ThemeService.instance),
        ChangeNotifierProvider.value(value: QuotesService.instance),
        ChangeNotifierProvider.value(value: ReadingSessionService.instance),
        ChangeNotifierProvider.value(value: LendingService.instance),
        ChangeNotifierProvider.value(value: SoundscapeService.instance),
        ChangeNotifierProvider.value(value: AchievementService.instance),
        ChangeNotifierProvider.value(value: BookOracleService.instance),
        ChangeNotifierProvider.value(value: NotesService.instance),
        ChangeNotifierProvider(create: (_) => UpdateService()),
        ChangeNotifierProvider(create: (_) => LibraryViewModel()),
      ],
      child: const BookParadiseApp(),
    ),
  );
}

class BookParadiseApp extends StatelessWidget {
  const BookParadiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();

    return MaterialApp(
      title: 'Книжный Рай',
      debugShowCheckedModeBanner: false,
      theme: themeService.buildTheme(Brightness.light),
      darkTheme: themeService.buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const MainNavigationShell(),
    );
  }
}
