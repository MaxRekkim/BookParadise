import 'enums.dart';

class Book {
  final int id;
  final String title;
  final String author;
  final int totalPages;
  int readPages;
  String? coverURL;
  BookGenre genre;
  ReadingStatus status;
  String? rating;
  String? notes;
  String? review;
  String? cycle;
  int? cycleOrder;
  int? cycleTotal;
  String? planMonth;
  int? planDays;
  double? price;
  String? publisher;
  BookFormat format;
  ShelfLocation shelfLocation;
  String? localFileName;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.totalPages,
    this.readPages = 0,
    this.coverURL,
    this.genre = BookGenre.prose,
    this.status = ReadingStatus.planned,
    this.rating,
    this.notes,
    this.review,
    this.cycle,
    this.cycleOrder,
    this.cycleTotal,
    this.planMonth,
    this.planDays,
    this.price,
    this.publisher,
    this.format = BookFormat.paper,
    this.shelfLocation = ShelfLocation.onShelf,
    this.localFileName,
  });

  double get progressPercentage {
    if (totalPages <= 0) return 0.0;
    return (readPages / totalPages).clamp(0.0, 1.0);
  }

  bool get isFinished => readPages >= totalPages && totalPages > 0;
  bool get hasKindleFile => localFileName != null && localFileName!.isNotEmpty;

  String? get cleanCoverURL {
    if (coverURL == null || coverURL!.trim().isEmpty) return null;
    var url = coverURL!.trim();
    if (url.startsWith('http://')) {
      url = url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    final id = json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0;
    final title = json['title'] as String? ?? 'Без названия';
    final author = json['author'] as String? ?? 'Неизвестный автор';
    final total = json['totalPages'] is int ? json['totalPages'] as int : int.tryParse('${json['totalPages']}') ?? 1;
    final read = json['readPages'] is int ? json['readPages'] as int : int.tryParse('${json['readPages']}') ?? 0;
    final ratingStr = json['rating'] as String?;

    return Book(
      id: id,
      title: title,
      author: author,
      totalPages: total > 0 ? total : 1,
      readPages: read,
      coverURL: json['coverURL'] as String?,
      genre: BookGenre.fromString(json['genre'] as String? ?? ''),
      status: ReadingStatus.fromRaw(read, total, ratingStr),
      rating: ratingStr,
      notes: json['notes'] as String?,
      review: json['review'] as String?,
      cycle: json['cycle'] as String?,
      cycleOrder: json['cycleOrder'] is int ? json['cycleOrder'] as int : int.tryParse('${json['cycleOrder']}'),
      cycleTotal: json['cycleTotal'] is int ? json['cycleTotal'] as int : int.tryParse('${json['cycleTotal']}'),
      planMonth: json['planMonth'] as String?,
      planDays: json['planDays'] is int ? json['planDays'] as int : int.tryParse('${json['planDays']}'),
      price: json['price'] != null ? double.tryParse('${json['price']}') : null,
      publisher: json['publisher'] as String?,
      format: BookFormat.fromString(json['format'] as String? ?? ''),
      shelfLocation: ShelfLocation.fromString(json['shelfLocation'] as String? ?? ''),
      localFileName: json['localFileName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'totalPages': totalPages,
      'readPages': readPages,
      'coverURL': coverURL,
      'genre': genre.title,
      'status': status.name,
      'rating': rating,
      'notes': notes,
      'review': review,
      'cycle': cycle,
      'cycleOrder': cycleOrder,
      'cycleTotal': cycleTotal,
      'planMonth': planMonth,
      'planDays': planDays,
      'price': price,
      'publisher': publisher,
      'format': format.title,
      'shelfLocation': shelfLocation.title,
      'localFileName': localFileName,
    };
  }
}
