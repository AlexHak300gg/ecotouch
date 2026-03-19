import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class NotesProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final NotificationService _notifications = NotificationService.instance;

  List<Note> _notes = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedCategory;
  NotePriority? _selectedPriority;
  String _searchQuery = '';

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedCategory => _selectedCategory;
  NotePriority? get selectedPriority => _selectedPriority;
  String get searchQuery => _searchQuery;

  /// Загрузка заметок пользователя
  Future<void> loadNotes(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _notes = await _db.getNotesByUser(userId);
      _applyFilters();
    } catch (e) {
      _error = 'Ошибка загрузки заметок: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Поиск заметок
  Future<void> searchNotes(int userId, String query) async {
    _searchQuery = query;
    _isLoading = true;
    notifyListeners();

    try {
      if (query.isEmpty) {
        _notes = await _db.getNotesByUser(userId);
      } else {
        _notes = await _db.searchNotes(userId, query);
      }
      _applyFilters();
    } catch (e) {
      _error = 'Ошибка поиска: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Установка фильтра по категории
  void setCategoryFilter(String? categoryId) {
    _selectedCategory = categoryId;
    _applyFilters();
    notifyListeners();
  }

  /// Установка фильтра по приоритету
  void setPriorityFilter(NotePriority? priority) {
    _selectedPriority = priority;
    _applyFilters();
    notifyListeners();
  }

  /// Очистка фильтров
  void clearFilters() {
    _selectedCategory = null;
    _selectedPriority = null;
    _searchQuery = '';
    notifyListeners();
  }

  /// Применение фильтров
  void _applyFilters() {
    var filtered = _notes;

    if (_selectedCategory != null) {
      filtered = filtered.where((n) => n.category == _selectedCategory).toList();
    }

    if (_selectedPriority != null) {
      filtered = filtered.where((n) => n.priority == _selectedPriority).toList();
    }

    _notes = filtered;
  }

  /// Создание заметки
  Future<bool> createNote({
    required int userId,
    required String title,
    required String content,
    required DateTime date,
    DateTime? reminderTime,
    String? category,
    NotePriority priority = NotePriority.normal,
  }) async {
    try {
      final note = Note(
        userId: userId,
        title: title,
        content: content,
        date: date,
        reminderTime: reminderTime,
        category: category,
        priority: priority,
      );

      final noteId = await _db.createNote(note);

      if (reminderTime != null && reminderTime.isAfter(DateTime.now())) {
        await _notifications.scheduleNoteReminder(
          id: noteId,
          title: '📝 $title',
          body: content.length > 50 ? '${content.substring(0, 50)}...' : content,
          scheduledDate: reminderTime,
        );
      }

      await loadNotes(userId);
      return true;
    } catch (e) {
      _error = 'Ошибка создания заметки: $e';
      notifyListeners();
      return false;
    }
  }

  /// Обновление заметки
  Future<bool> updateNote({
    required int id,
    required int userId,
    String? title,
    String? content,
    DateTime? date,
    DateTime? reminderTime,
    bool? isCompleted,
    String? category,
    NotePriority? priority,
  }) async {
    try {
      final existingNote = _notes.firstWhere((n) => n.id == id);

      final updatedNote = existingNote.copyWith(
        title: title,
        content: content,
        date: date,
        reminderTime: reminderTime,
        isCompleted: isCompleted,
        category: category,
        priority: priority,
      );

      await _db.updateNote(updatedNote);

      // Обновляем напоминание
      if (reminderTime != null) {
        await _notifications.cancelNotification(id);
        if (reminderTime.isAfter(DateTime.now()) && !(isCompleted ?? false)) {
          await _notifications.scheduleNoteReminder(
            id: id,
            title: '📝 ${updatedNote.title}',
            body: updatedNote.content,
            scheduledDate: reminderTime,
          );
        }
      } else {
        await _notifications.cancelNotification(id);
      }

      await loadNotes(userId);
      return true;
    } catch (e) {
      _error = 'Ошибка обновления заметки: $e';
      notifyListeners();
      return false;
    }
  }

  /// Удаление заметки
  Future<bool> deleteNote({
    required int id,
    required int userId,
  }) async {
    try {
      await _notifications.cancelNotification(id);
      await _db.deleteNote(id);
      await loadNotes(userId);
      return true;
    } catch (e) {
      _error = 'Ошибка удаления заметки: $e';
      notifyListeners();
      return false;
    }
  }

  /// Получение заметок для даты
  List<Note> getNotesForDate(DateTime date) {
    return _notes.where((note) {
      return note.date.year == date.year &&
          note.date.month == date.month &&
          note.date.day == date.day;
    }).toList();
  }

  /// Получение предстоящих напоминаний
  List<Note> getUpcomingReminders() {
    final now = DateTime.now();
    return _notes
        .where((note) =>
            note.reminderTime != null &&
            note.reminderTime!.isAfter(now) &&
            !note.isCompleted)
        .toList();
  }

  /// Получение заметок по категории
  List<Note> getNotesByCategory(String category) {
    return _notes.where((note) => note.category == category).toList();
  }

  /// Получение заметок по приоритету
  List<Note> getNotesByPriority(NotePriority priority) {
    return _notes.where((note) => note.priority == priority).toList();
  }
}
