class ReadingSession {
  final String id;
  final int bookId;
  final DateTime startTime;
  DateTime endTime;
  int startPage;
  int endPage;
  int durationSeconds;

  ReadingSession({
    required this.id,
    required this.bookId,
    required this.startTime,
    required this.endTime,
    required this.startPage,
    required this.endPage,
    required this.durationSeconds,
  });

  int get pagesRead => (endPage - startPage).clamp(0, 9999);

  double get pagesPerHour {
    if (durationSeconds <= 0) return 0.0;
    return (pagesRead / (durationSeconds / 3600.0));
  }

  factory ReadingSession.fromJson(Map<String, dynamic> json) {
    return ReadingSession(
      id: json['id'] as String? ?? '',
      bookId: json['bookId'] is int ? json['bookId'] as int : int.tryParse('${json['bookId']}') ?? 0,
      startTime: DateTime.tryParse(json['startTime'] as String? ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['endTime'] as String? ?? '') ?? DateTime.now(),
      startPage: json['startPage'] is int ? json['startPage'] as int : int.tryParse('${json['startPage']}') ?? 0,
      endPage: json['endPage'] is int ? json['endPage'] as int : int.tryParse('${json['endPage']}') ?? 0,
      durationSeconds: json['durationSeconds'] is int ? json['durationSeconds'] as int : int.tryParse('${json['durationSeconds']}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookId': bookId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'startPage': startPage,
    'endPage': endPage,
    'durationSeconds': durationSeconds,
  };
}
