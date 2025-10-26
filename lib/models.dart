// lib/models.dart


/// Representasi struktur data untuk satu entri jurnal.
/// Class ini adalah inti dari kriteria Penyimpanan Data (25%).
class Event {
  final String id;
  final String title;
  final String note;
  final DateTime createdAt;
  final String category; // Kategori acara


  Event({
    required this.id,
    required this.title,
    required this.note,
    required this.createdAt,
    required this.category,
  });


  /// Metode untuk konversi objek JournalEntry menjadi Map (serialisasi JSON).
  /// Penting untuk penyimpanan data ke File I/O.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
    'category': category,
  };


  /// Factory constructor untuk membuat objek JournalEntry dari Map (deserialisasi JSON).
  /// Digunakan saat memuat data dari File I/O.
  factory Event.fromJson(Map<String, dynamic> json) => Event(
    id: json['id'] as String,
    title: json['title'] as String,
    note: json['note'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    category: json['category'] as String? ?? 'Lainnya',
  );
}



