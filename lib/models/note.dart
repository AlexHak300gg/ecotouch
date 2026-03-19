class Note {
  final int? id;
  final int userId;
  final String title;
  final String content;
  final DateTime date;
  final DateTime? reminderTime;
  final bool isCompleted;
  final String? category;
  final NotePriority priority;
  final DateTime createdAt;

  Note({
    this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.date,
    this.reminderTime,
    this.isCompleted = false,
    this.category,
    this.priority = NotePriority.normal,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'reminder_time': reminderTime?.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'category': category,
      'priority': priority.value,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      content: map['content'],
      date: DateTime.parse(map['date']),
      reminderTime: map['reminder_time'] != null
          ? DateTime.parse(map['reminder_time'])
          : null,
      isCompleted: map['is_completed'] == 1,
      category: map['category'],
      priority: NotePriority.fromValue(map['priority'] ?? 0),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Note copyWith({
    int? id,
    int? userId,
    String? title,
    String? content,
    DateTime? date,
    DateTime? reminderTime,
    bool? isCompleted,
    String? category,
    NotePriority? priority,
    DateTime? createdAt,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      reminderTime: reminderTime ?? this.reminderTime,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Приоритет заметки
enum NotePriority {
  low(0),
  normal(1),
  high(2);

  final int value;
  const NotePriority(this.value);

  static NotePriority fromValue(int value) {
    switch (value) {
      case 0:
        return NotePriority.low;
      case 2:
        return NotePriority.high;
      default:
        return NotePriority.normal;
    }
  }
}

extension NotePriorityExtension on NotePriority {
  String get label {
    switch (this) {
      case NotePriority.low:
        return 'Низкий';
      case NotePriority.normal:
        return 'Обычный';
      case NotePriority.high:
        return 'Высокий';
    }
  }

  // ignore: deprecated_member_use
  int getColorValue() {
    switch (this) {
      case NotePriority.low:
        return 0xFF2196F3; // Blue
      case NotePriority.normal:
        return 0xFF4CAF50; // Green
      case NotePriority.high:
        return 0xFFF44336; // Red
    }
  }
}

/// Категории заметок
class NoteCategory {
  final String id;
  final String name;
  final String icon;
  final int colorValue;

  const NoteCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
  });

  static const List<NoteCategory> all = [
    NoteCategory(id: 'personal', name: 'Личное', icon: '👤', colorValue: 0xFF9C27B0),
    NoteCategory(id: 'work', name: 'Работа', icon: '💼', colorValue: 0xFF2196F3),
    NoteCategory(id: 'eco', name: 'Экология', icon: '🌱', colorValue: 0xFF4CAF50),
    NoteCategory(id: 'shopping', name: 'Покупки', icon: '🛒', colorValue: 0xFFFF9800),
    NoteCategory(id: 'health', name: 'Здоровье', icon: '❤️', colorValue: 0xFFF44336),
    NoteCategory(id: 'education', name: 'Обучение', icon: '📚', colorValue: 0xFF00BCD4),
    NoteCategory(id: 'other', name: 'Другое', icon: '📝', colorValue: 0xFF9E9E9E),
  ];

  static NoteCategory? fromId(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}
