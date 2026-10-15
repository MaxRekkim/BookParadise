import 'book.dart';

class BingoItem {
  final int id;
  final String title;
  final String author;
  final String planMonth;
  int planDays;
  final int totalPages;
  int readPages;
  final String? coverURL;

  BingoItem({
    required this.id,
    required this.title,
    required this.author,
    required this.planMonth,
    this.planDays = 0,
    required this.totalPages,
    this.readPages = 0,
    this.coverURL,
  });

  bool get isCompleted => readPages >= totalPages && totalPages > 0;

  factory BingoItem.fromJson(Map<String, dynamic> json) {
    return BingoItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      planMonth: json['planMonth'] as String? ?? '',
      planDays: json['planDays'] is int ? json['planDays'] as int : int.tryParse('${json['planDays']}') ?? 0,
      totalPages: json['totalPages'] is int ? json['totalPages'] as int : int.tryParse('${json['totalPages']}') ?? 1,
      readPages: json['readPages'] is int ? json['readPages'] as int : int.tryParse('${json['readPages']}') ?? 0,
      coverURL: json['coverURL'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'author': author,
    'planMonth': planMonth,
    'planDays': planDays,
    'totalPages': totalPages,
    'readPages': readPages,
    'coverURL': coverURL,
  };
}

class CycleInfo {
  final String name;
  final List<Book> books;

  CycleInfo({required this.name, required this.books});

  int get totalBooks => books.length;
  int get readBooks => books.where((b) => b.isFinished).length;
  bool get isCompleted => totalBooks > 0 && readBooks == totalBooks;
  double get progress => totalBooks > 0 ? readBooks / totalBooks : 0.0;
}

class ReadingStats {
  final int totalBooks;
  final int readBooks;
  final int inProgressBooks;
  final int plannedBooks;
  final int totalPagesRead;
  final double averageRating;

  ReadingStats({
    this.totalBooks = 0,
    this.readBooks = 0,
    this.inProgressBooks = 0,
    this.plannedBooks = 0,
    this.totalPagesRead = 0,
    this.averageRating = 0.0,
  });
}
