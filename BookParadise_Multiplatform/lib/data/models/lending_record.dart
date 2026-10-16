enum LendingType {
  lent, // Я отдал почитать
  borrowed, // Я взял почитать
}

extension LendingTypeExtension on LendingType {
  String get title {
    switch (this) {
      case LendingType.lent:
        return 'Одолжена другу';
      case LendingType.borrowed:
        return 'Взята почитать';
    }
  }

  String get actionPrompt {
    switch (this) {
      case LendingType.lent:
        return 'Кому передана книга';
      case LendingType.borrowed:
        return 'У кого взята книга';
    }
  }
}

class BookLendingRecord {
  final String id;
  final String bookId;
  final String bookTitle;
  final String personName;
  final String? contact;
  final DateTime lentDate;
  final DateTime? dueDate;
  final bool isReturned;
  final DateTime? returnDate;
  final String? notes;
  final LendingType type;

  BookLendingRecord({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.personName,
    this.contact,
    required this.lentDate,
    this.dueDate,
    this.isReturned = false,
    this.returnDate,
    this.notes,
    this.type = LendingType.lent,
  });

  bool get isOverdue {
    if (isReturned || dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  int? get daysRemaining {
    if (dueDate == null) return null;
    final now = DateTime.now();
    final diff = dueDate!.difference(DateTime(now.year, now.month, now.day)).inDays;
    return diff;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'personName': personName,
      'contact': contact,
      'lentDate': lentDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'isReturned': isReturned,
      'returnDate': returnDate?.toIso8601String(),
      'notes': notes,
      'type': type.name,
    };
  }

  factory BookLendingRecord.fromJson(Map<String, dynamic> json) {
    return BookLendingRecord(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      bookTitle: json['bookTitle'] as String,
      personName: json['personName'] as String,
      contact: json['contact'] as String?,
      lentDate: DateTime.parse(json['lentDate'] as String),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      isReturned: json['isReturned'] as bool? ?? false,
      returnDate: json['returnDate'] != null ? DateTime.parse(json['returnDate'] as String) : null,
      notes: json['notes'] as String?,
      type: json['type'] == 'borrowed' ? LendingType.borrowed : LendingType.lent,
    );
  }
}
