class BookQuote {
  final String id;
  final int bookId;
  final String text;
  final int? pageNumber;
  final String? note;
  final DateTime dateAdded;

  BookQuote({
    required this.id,
    required this.bookId,
    required this.text,
    this.pageNumber,
    this.note,
    DateTime? dateAdded,
  }) : dateAdded = dateAdded ?? DateTime.now();

  factory BookQuote.fromJson(Map<String, dynamic> json) {
    return BookQuote(
      id: json['id'] as String? ?? UniqueKey().toString(),
      bookId: json['bookId'] is int ? json['bookId'] as int : int.tryParse('${json['bookId']}') ?? 0,
      text: json['text'] as String? ?? '',
      pageNumber: json['pageNumber'] is int ? json['pageNumber'] as int : int.tryParse('${json['pageNumber']}'),
      note: json['note'] as String?,
      dateAdded: json['dateAdded'] != null ? DateTime.tryParse(json['dateAdded'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookId': bookId,
    'text': text,
    'pageNumber': pageNumber,
    'note': note,
    'dateAdded': dateAdded.toIso8601String(),
  };
}

class UniqueKey {
  @override
  String toString() => DateTime.now().microsecondsSinceEpoch.toString();
}
