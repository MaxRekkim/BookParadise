import 'dart:convert';

class ReadingNote {
  final String id;
  final int? bookId;
  final String? bookTitle;
  String title;
  String content;
  final DateTime createdAt;
  DateTime updatedAt;
  List<String> tags;
  bool isPinned;

  ReadingNote({
    required this.id,
    this.bookId,
    this.bookTitle,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.isPinned = false,
  });

  int get wordCount {
    if (content.trim().isEmpty) return 0;
    return content.trim().split(RegExp(r'\s+')).length;
  }

  int get readingTimeMinutes {
    final words = wordCount;
    return (words / 200).ceil().clamp(1, 999);
  }

  String get excerpt {
    final lines = LineSplitter.split(content)
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#'))
        .toList();
    if (lines.isNotEmpty) {
      final first = lines.first;
      return first.length > 120 ? '${first.substring(0, 120)}...' : first;
    }
    return 'Пустая заметка...';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookId': bookId,
    'bookTitle': bookTitle,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'tags': tags,
    'isPinned': isPinned,
  };

  factory ReadingNote.fromJson(Map<String, dynamic> json) => ReadingNote(
    id: json['id'] as String,
    bookId: json['bookId'] as int?,
    bookTitle: json['bookTitle'] as String?,
    title: json['title'] as String? ?? 'Без названия',
    content: json['content'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    isPinned: json['isPinned'] as bool? ?? false,
  );
}
