

class Event {
  final String id;
  final String title;
  final String note;
  final DateTime createdAt;
  final String category;
  final String status; // 'pending', 'completed', 'missed'
  final String? result; // optional result note, e.g. 'Tidak terlaksana'
  final List<String>? mediaPaths; // optional list of media file paths (images/videos)

  Event({
    required this.id,
    required this.title,
    required this.note,
    required this.createdAt,
    required this.category,
    this.status = 'pending',
    this.result,
    this.mediaPaths,
  });

  Event copyWith({String? id, String? title, String? note, DateTime? createdAt, String? category, String? status, String? result, List<String>? mediaPaths}) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      status: status ?? this.status,
      result: result ?? this.result,
      mediaPaths: mediaPaths ?? this.mediaPaths,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
    'category': category,
    'status': status,
    'result': result,
    'mediaPaths': mediaPaths,
  };

  factory Event.fromJson(Map<String, dynamic> json) => Event(
    id: json['id'] as String,
    title: json['title'] as String,
    note: json['note'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    category: json['category'] as String? ?? 'Lainnya',
    status: json['status'] as String? ?? 'pending',
    result: json['result'] as String?,
    mediaPaths: (json['mediaPaths'] as List<dynamic>?)?.map((e) => e as String).toList(),
  );
}
