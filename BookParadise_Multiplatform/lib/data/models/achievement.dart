class ReadingAchievement {
  final String id;
  final String title;
  final String subtitle;
  final String badgeEmoji;
  final String category; // streak, speed, volume, collection, bingo
  bool isUnlocked;
  DateTime? unlockedDate;
  double progress; // 0.0 ... 1.0
  String progressText;

  ReadingAchievement({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badgeEmoji,
    required this.category,
    this.isUnlocked = false,
    this.unlockedDate,
    this.progress = 0.0,
    this.progressText = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'badgeEmoji': badgeEmoji,
    'category': category,
    'isUnlocked': isUnlocked,
    'unlockedDate': unlockedDate?.toIso8601String(),
    'progress': progress,
    'progressText': progressText,
  };

  factory ReadingAchievement.fromJson(Map<String, dynamic> json) => ReadingAchievement(
    id: json['id'] as String,
    title: json['title'] as String,
    subtitle: json['subtitle'] as String,
    badgeEmoji: json['badgeEmoji'] as String,
    category: json['category'] as String,
    isUnlocked: json['isUnlocked'] as bool? ?? false,
    unlockedDate: json['unlockedDate'] != null ? DateTime.tryParse(json['unlockedDate'] as String) : null,
    progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    progressText: json['progressText'] as String? ?? '',
  );
}
