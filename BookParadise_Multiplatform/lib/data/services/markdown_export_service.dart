import '../models/book.dart';
import '../models/quote.dart';
import '../models/enums.dart';

class MarkdownExportService {
  static final MarkdownExportService instance = MarkdownExportService._internal();
  MarkdownExportService._internal();

  /// Экспорт отдельной книги в Markdown с YAML Frontmatter
  String exportBookToMarkdown(Book book, List<BookQuote> allQuotes) {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final buffer = StringBuffer();

    // YAML Frontmatter
    buffer.writeln('---');
    buffer.writeln('title: "${_escapeYaml(book.title)}"');
    buffer.writeln('author: "${_escapeYaml(book.author)}"');
    buffer.writeln('genre: "${_escapeYaml(book.genre.title)}"');
    buffer.writeln('status: "${book.status.title}"');
    buffer.writeln('pages_read: ${book.readPages}');
    buffer.writeln('total_pages: ${book.totalPages}');
    buffer.writeln('progress_percent: ${(book.progressPercentage * 100).toInt()}');
    if (book.rating != null && book.rating!.isNotEmpty) {
      buffer.writeln('rating: "${_escapeYaml(book.rating!)}"');
    }
    buffer.writeln('format: "${book.format.title}"');
    buffer.writeln('shelf: "${book.shelfLocation.title}"');
    if (book.publisher != null && book.publisher!.isNotEmpty) {
      buffer.writeln('publisher: "${_escapeYaml(book.publisher!)}"');
    }
    if (book.cycle != null && book.cycle!.isNotEmpty) {
      buffer.writeln('cycle: "${_escapeYaml(book.cycle!)}"');
      if (book.cycleOrder != null) {
        buffer.writeln('cycle_order: ${book.cycleOrder}');
      }
    }
    buffer.writeln('export_date: "$todayStr"');
    buffer.writeln('source: "BookParadise"');
    buffer.writeln('---\n');

    // Тело документа
    buffer.writeln('# ${book.title}\n');
    buffer.writeln('**Автор:** ${book.author}  ');
    buffer.writeln('**Жанр:** ${book.genre.title} | **Формат:** ${book.format.title}  ');
    if (book.cycle != null && book.cycle!.isNotEmpty) {
      buffer.writeln('**Серия:** ${book.cycle} (книга № ${book.cycleOrder ?? 1})  ');
    }
    buffer.writeln('**Прогресс:** ${book.readPages} из ${book.totalPages} стр. (${(book.progressPercentage * 100).toInt()}%)  ');
    if (book.rating != null && book.rating!.isNotEmpty) {
      buffer.writeln('**Оценка:** ${book.rating}  ');
    }
    buffer.writeln('\n---\n');

    // Рецензия
    if (book.review != null && book.review!.trim().isNotEmpty) {
      buffer.writeln('## Рецензия и впечатления\n');
      buffer.writeln('${book.review!.trim()}\n');
      buffer.writeln('---\n');
    }

    // Заметки
    if (book.notes != null && book.notes!.trim().isNotEmpty) {
      buffer.writeln('## Заметки\n');
      buffer.writeln('${book.notes!.trim()}\n');
      buffer.writeln('---\n');
    }

    // Цитаты
    final bookQuotes = allQuotes.where((q) => q.bookId == book.id).toList();
    if (bookQuotes.isNotEmpty) {
      buffer.writeln('## Избранные цитаты (${bookQuotes.length})\n');
      for (int i = 0; i < bookQuotes.length; i++) {
        final q = bookQuotes[i];
        buffer.writeln('> «${q.text}»\n>');
        final meta = <String>[];
        if (q.pageNumber != null && q.pageNumber! > 0) {
          meta.add('Стр. ${q.pageNumber}');
        }
        meta.add('${q.dateAdded.year}-${q.dateAdded.month.toString().padLeft(2, '0')}-${q.dateAdded.day.toString().padLeft(2, '0')}');
        buffer.writeln('> *— ${meta.join(' • ')}*\n');

        if (q.note != null && q.note!.trim().isNotEmpty) {
          buffer.writeln('💡 **Заметка:** *${q.note!.trim()}*\n');
        }

        if (i < bookQuotes.length - 1) {
          buffer.writeln('---\n');
        }
      }
    }

    return buffer.toString();
  }

  /// Экспорт сводного каталога всей библиотеки
  String exportCatalogToMarkdown(List<Book> books, List<BookQuote> allQuotes) {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final buffer = StringBuffer();
    buffer.writeln('# Книжный Рай — Каталог библиотеки\n');
    buffer.writeln('*Экспортировано: $todayStr • Всего книг: ${books.length}*\n');

    final read = books.where((b) => b.status == ReadingStatus.finished).length;
    final inProgress = books.where((b) => b.status == ReadingStatus.reading).length;
    final planned = books.where((b) => b.status == ReadingStatus.planned).length;

    buffer.writeln('## Сводка');
    buffer.writeln('- **Прочитано:** $read');
    buffer.writeln('- **Читаю сейчас:** $inProgress');
    buffer.writeln('- **В планах:** $planned');
    buffer.writeln('- **Сохранено цитат:** ${allQuotes.length}\n');

    buffer.writeln('## Список книг\n');
    buffer.writeln('| Название | Автор | Жанр | Статус | Стр. | Оценка |');
    buffer.writeln('|---|---|---|---|---|---|');

    final sorted = List<Book>.from(books)..sort((a, b) => a.title.compareTo(b.title));
    for (final b in sorted) {
      final rating = b.rating ?? '-';
      buffer.writeln('| ${_escapePipe(b.title)} | ${_escapePipe(b.author)} | ${b.genre.title} | ${b.status.title} | ${b.readPages}/${b.totalPages} | $rating |');
    }

    return buffer.toString();
  }

  String _escapeYaml(String str) {
    return str.replaceAll('"', '\\"');
  }

  String _escapePipe(String str) {
    return str.replaceAll('|', '\\|');
  }
}
