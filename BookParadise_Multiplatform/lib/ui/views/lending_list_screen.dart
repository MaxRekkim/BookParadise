import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/lending_record.dart';
import '../../data/services/lending_service.dart';

class LendingListScreen extends StatelessWidget {
  const LendingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lendingService = context.watch<LendingService>();
    final active = lendingService.activeRecords;
    final history = lendingService.records.where((r) => r.isReturned).toList()
      ..sort((a, b) => (b.returnDate ?? DateTime.now()).compareTo(a.returnDate ?? DateTime.now()));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Книги у друзей'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'У друзей (${active.length})'),
              Tab(text: 'Возвращены (${history.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildActiveList(context, lendingService, active),
            _buildHistoryList(context, lendingService, history),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveList(BuildContext context, LendingService service, List<BookLendingRecord> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'Все книги дома!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Вы пока никому не одалживали книги из библиотеки',
              style: TextStyle(color: Colors.grey.withOpacity(0.8)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = list[index];
        final days = item.daysRemaining;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.bookTitle,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                item.type == LendingType.lent ? Icons.arrow_outward : Icons.call_received,
                                size: 14,
                                color: item.type == LendingType.lent ? Colors.orange : Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.type == LendingType.lent ? "У кого:" : "Взята у:"} ${item.personName}',
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (days != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.isOverdue
                              ? Colors.red.withOpacity(0.15)
                              : Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.isOverdue ? 'Просрочено ${days.abs()} дн.' : 'Осталось $days дн.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: item.isOverdue ? Colors.red : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (item.contact != null && item.contact!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.send, size: 12, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(item.contact!, style: const TextStyle(fontSize: 12, color: Colors.blue)),
                    ],
                  ),
                ],
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Заметка: ${item.notes}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Отдано: ${item.lentDate.day}.${item.lentDate.month}.${item.lentDate.year}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Отметить возврат'),
                      onPressed: () => service.markReturned(item.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryList(BuildContext context, LendingService service, List<BookLendingRecord> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text('История возвратов пуста', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = list[index];
        final rDate = item.returnDate;

        return ListTile(
          tileColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Text(item.bookTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Был(а) у: ${item.personName}'),
          trailing: rDate != null
              ? Text(
                  'Возвращена: ${rDate.day}.${rDate.month}.${rDate.year}',
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                )
              : null,
        );
      },
    );
  }
}
