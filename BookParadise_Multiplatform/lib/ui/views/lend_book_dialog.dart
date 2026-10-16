import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/book.dart';
import '../../data/models/lending_record.dart';
import '../../data/services/lending_service.dart';

class LendBookDialog extends StatefulWidget {
  final Book book;

  const LendBookDialog({super.key, required this.book});

  static Future<void> show(BuildContext context, Book book) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LendBookDialog(book: book),
    );
  }

  @override
  State<LendBookDialog> createState() => _LendBookDialogState();
}

class _LendBookDialogState extends State<LendBookDialog> {
  LendingType _type = LendingType.lent;
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _notesController = TextEditingController();
  bool _hasDueDate = true;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.person_add_alt_1, color: primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Одолжить книгу «${widget.book.title}»',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<LendingType>(
              segments: const [
                ButtonSegment(
                  value: LendingType.lent,
                  label: Text('Одолжена другу'),
                  icon: Icon(Icons.arrow_outward),
                ),
                ButtonSegment(
                  value: LendingType.borrowed,
                  label: Text('Взята почитать'),
                  icon: Icon(Icons.call_received),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (set) {
                setState(() => _type = set.first);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: _type == LendingType.lent ? 'Имя друга (кому передана)' : 'Имя владельца (у кого взята)',
                prefixIcon: const Icon(Icons.person_outline),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: 'Контакт (телефон / @telegram)',
                prefixIcon: const Icon(Icons.contact_phone_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Установить срок возврата'),
              value: _hasDueDate,
              onChanged: (val) => setState(() => _hasDueDate = val),
            ),
            if (_hasDueDate) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Дата возврата'),
                subtitle: Text('${_dueDate.day}.${_dueDate.month}.${_dueDate.year}'),
                trailing: TextButton(
                  child: const Text('Выбрать'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _dueDate = picked);
                    }
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Примечание / состояние книги',
                prefixIcon: Icon(Icons.notes_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Сохранить запись'),
              onPressed: _nameController.text.trim().isEmpty
                  ? null
                  : () async {
                      await context.read<LendingService>().lendBook(
                            bookId: widget.book.id.toString(),
                            bookTitle: widget.book.title,
                            personName: _nameController.text.trim(),
                            contact: _contactController.text.trim().isEmpty ? null : _contactController.text.trim(),
                            dueDate: _hasDueDate ? _dueDate : null,
                            type: _type,
                            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                          );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Запись об одолженной книге сохранена')),
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
