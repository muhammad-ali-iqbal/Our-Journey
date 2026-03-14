import 'dart:convert';

class QuizOption {
  final String text;
  final bool isCorrect;

  QuizOption({required this.text, required this.isCorrect});

  factory QuizOption.fromMap(Map<String, dynamic> m) => QuizOption(
        text: m['text'] as String? ?? '',
        isCorrect: m['isCorrect'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {'text': text, 'isCorrect': isCorrect};
}

class MemoryQuiz {
  final String question;
  final List<QuizOption> options;

  MemoryQuiz({required this.question, required this.options});

  factory MemoryQuiz.fromMap(Map<String, dynamic> m) => MemoryQuiz(
        question: m['question'] as String? ?? '',
        options: (m['options'] as List<dynamic>? ?? [])
            .map((o) => QuizOption.fromMap(o as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'question': question,
        'options': options.map((o) => o.toMap()).toList(),
      };
}

class Memory {
  final String id;
  final String title;
  final String story;
  final String locationName;
  final double? lat;   // canvas Y position (0.0–1.0)
  final double? lng;   // canvas X position (0.0–1.0)
  final DateTime date;
  final List<String> imagePaths; // Supabase Storage URLs
  final MemoryQuiz? quiz;
  final bool isUnlocked;
  final DateTime createdAt;

  Memory({
    required this.id,
    required this.title,
    required this.story,
    required this.locationName,
    this.lat,
    this.lng,
    required this.date,
    this.imagePaths = const [],
    this.quiz,
    this.isUnlocked = false,
    required this.createdAt,
  });

  // ── From Supabase row ───────────────────────────────────────────────────────
  factory Memory.fromMap(Map<String, dynamic> d) {
    // quiz is stored as JSON string in Supabase
    MemoryQuiz? quiz;
    if (d['quiz'] != null) {
      final quizData = d['quiz'] is String
          ? jsonDecode(d['quiz'] as String) as Map<String, dynamic>
          : d['quiz'] as Map<String, dynamic>;
      quiz = MemoryQuiz.fromMap(quizData);
    }

    // image_paths stored as JSON array string or List
    List<String> imagePaths = [];
    if (d['image_paths'] != null) {
      if (d['image_paths'] is String) {
        imagePaths = List<String>.from(
            jsonDecode(d['image_paths'] as String) as List);
      } else {
        imagePaths = List<String>.from(d['image_paths'] as List);
      }
    }

    return Memory(
      id: d['id'] as String,
      title: d['title'] as String? ?? '',
      story: d['story'] as String? ?? '',
      locationName: d['location_name'] as String? ?? '',
      lat: (d['lat'] as num?)?.toDouble(),
      lng: (d['lng'] as num?)?.toDouble(),
      date: DateTime.parse(d['date'] as String),
      imagePaths: imagePaths,
      quiz: quiz,
      isUnlocked: d['is_unlocked'] as bool? ?? false,
      createdAt: DateTime.parse(d['created_at'] as String),
    );
  }

  // ── To Supabase row ─────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'story': story,
        'location_name': locationName,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'date': date.toIso8601String(),
        'image_paths': jsonEncode(imagePaths),
        'quiz': quiz != null ? jsonEncode(quiz!.toMap()) : null,
        'is_unlocked': isUnlocked,
        'created_at': createdAt.toIso8601String(),
      };

  Memory copyWith({
    String? title,
    String? story,
    String? locationName,
    double? lat,
    double? lng,
    DateTime? date,
    List<String>? imagePaths,
    MemoryQuiz? quiz,
    bool? isUnlocked,
  }) =>
      Memory(
        id: id,
        title: title ?? this.title,
        story: story ?? this.story,
        locationName: locationName ?? this.locationName,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        date: date ?? this.date,
        imagePaths: imagePaths ?? this.imagePaths,
        quiz: quiz ?? this.quiz,
        isUnlocked: isUnlocked ?? this.isUnlocked,
        createdAt: createdAt,
      );
}
