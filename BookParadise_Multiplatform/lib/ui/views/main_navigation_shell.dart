import 'package:flutter/material.dart';
import 'dashboard_view.dart';
import 'library_view.dart';
import 'bingo_view.dart';
import 'cycles_view.dart';
import 'quotes_view.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardView(),
    LibraryView(),
    BingoView(),
    CyclesView(),
    QuotesView(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 750;

        if (isDesktop) {
          // Windows / Desktop Layout with NavigationRail Sidebar
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (val) => setState(() => _currentIndex = val),
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Icon(Icons.menu_book, color: Theme.of(context).colorScheme.primary, size: 32),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: Text('Главная'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.shelves),
                      selectedIcon: Icon(Icons.shelves),
                      label: Text('Библиотека'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month),
                      label: Text('Планы'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.bookmarks_outlined),
                      selectedIcon: Icon(Icons.bookmarks),
                      label: Text('Циклы'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.format_quote_outlined),
                      selectedIcon: Icon(Icons.format_quote),
                      label: Text('Цитаты'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: _screens[_currentIndex]),
              ],
            ),
          );
        }

        // Mobile / Android Layout with NavigationBar
        return Scaffold(
          body: _screens[_currentIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (val) => setState(() => _currentIndex = val),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Главная',
              ),
              NavigationDestination(
                icon: Icon(Icons.shelves),
                selectedIcon: Icon(Icons.shelves),
                label: 'Каталог',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: 'Планы',
              ),
              NavigationDestination(
                icon: Icon(Icons.bookmarks_outlined),
                selectedIcon: Icon(Icons.bookmarks),
                label: 'Циклы',
              ),
              NavigationDestination(
                icon: Icon(Icons.format_quote_outlined),
                selectedIcon: Icon(Icons.format_quote),
                label: 'Цитаты',
              ),
            ],
          ),
        );
      },
    );
  }
}
