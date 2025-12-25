class Topic {
  final String id;
  final String subjectId;
  final String title;
  final int intervalIndex;
  final DateTime? lastReviewedAt;
  final DateTime? nextReviewAt;
  final bool archived;

  const Topic({
    required this.id,
    required this.subjectId,
    required this.title,
    this.intervalIndex = 0,
    this.lastReviewedAt,
    this.nextReviewAt,
    this.archived = false,
  });

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
    id: (json['id'] ?? '').toString(),
    subjectId: (json['subjectId'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    intervalIndex: (json['intervalIndex'] as num?)?.toInt() ?? 0,
    lastReviewedAt: json['lastReviewedAt'] == null
        ? null
        : DateTime.tryParse(json['lastReviewedAt'].toString()),
    nextReviewAt: json['nextReviewAt'] == null
        ? null
        : DateTime.tryParse(json['nextReviewAt'].toString()),
    archived: json['archived'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectId': subjectId,
    'title': title,
    'intervalIndex': intervalIndex,
    'lastReviewedAt': lastReviewedAt?.toIso8601String(),
    'nextReviewAt': nextReviewAt?.toIso8601String(),
    'archived': archived,
  };

  Topic copyWith({
    String? id,
    String? subjectId,
    String? title,
    int? intervalIndex,
    DateTime? lastReviewedAt,
    DateTime? nextReviewAt,
    bool? archived,
  }) =>
      Topic(
        id: id ?? this.id,
        subjectId: subjectId ?? this.subjectId,
        title: title ?? this.title,
        intervalIndex: intervalIndex ?? this.intervalIndex,
        lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
        nextReviewAt: nextReviewAt ?? this.nextReviewAt,
        archived: archived ?? this.archived,
      );
}