import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/note.dart';
import '../models/recycling_point.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ecotouch.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Добавляем колонки category и priority в таблицу notes
      await db.execute('ALTER TABLE notes ADD COLUMN category TEXT');
      await db.execute('ALTER TABLE notes ADD COLUMN priority INTEGER DEFAULT 1');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    // Таблица пользователей
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        email $textType,
        password_hash $textType,
        name $textType,
        phone TEXT,
        avatar_path TEXT,
        created_at $textType
      )
    ''');

    // Таблица заметок
    await db.execute('''
      CREATE TABLE notes (
        id $idType,
        user_id $integerType,
        title $textType,
        content $textType,
        date $textType,
        reminder_time TEXT,
        is_completed $integerType DEFAULT 0,
        category TEXT,
        priority $integerType DEFAULT 1,
        created_at $textType,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Таблица пунктов приёма
    await db.execute('''
      CREATE TABLE recycling_points (
        id $idType,
        name $textType,
        address $textType,
        latitude $realType,
        longitude $realType,
        description TEXT,
        phone TEXT,
        working_hours TEXT,
        accepted_types $textType,
        created_at $textType
      )
    ''');

    // Добавим тестовые пункты приёма в Удмуртии
    await _insertSampleRecyclingPoints(db);
  }

  Future<void> _insertSampleRecyclingPoints(Database db) async {
    final now = DateTime.now().toIso8601String();
    final samplePoints = [
      {
        'name': 'ЭкоПункт - Ижевск Центр',
        'address': 'г. Ижевск, ул. Пушкинская, 260',
        'latitude': 56.8527,
        'longitude': 53.2041,
        'description': 'Крупный пункт приёма вторсырья',
        'phone': '+7 (3412) 12-34-56',
        'working_hours': 'Пн-Пт: 9:00-18:00',
        'accepted_types': 'paper,plastic,glass,metal,batteries',
        'created_at': now,
      },
      {
        'name': 'Пункт приёма - Северный',
        'address': 'г. Ижевск, ул. Северная, 50',
        'latitude': 56.8697,
        'longitude': 53.1925,
        'description': 'Приём пластика и бумаги',
        'phone': '+7 (3412) 23-45-67',
        'working_hours': 'Пн-Сб: 10:00-19:00',
        'accepted_types': 'paper,plastic,clothes',
        'created_at': now,
      },
      {
        'name': 'ЭкоПост - Воткинск',
        'address': 'г. Воткинск, ул. Ленина, 15',
        'latitude': 57.0498,
        'longitude': 53.9859,
        'description': 'Филиал сети ЭкоПост',
        'phone': '+7 (34145) 3-21-00',
        'working_hours': 'Вт-Вс: 9:00-17:00',
        'accepted_types': 'glass,metal,electronics,batteries',
        'created_at': now,
      },
      {
        'name': 'Зелёный пункт - Сарапул',
        'address': 'г. Сарапул, ул. Труда, 8',
        'latitude': 56.4639,
        'longitude': 53.8047,
        'description': 'Приём всех видов вторсырья',
        'phone': '+7 (34148) 2-34-56',
        'working_hours': 'Пн-Пт: 8:00-17:00',
        'accepted_types': 'paper,plastic,glass,metal,electronics,batteries,clothes,organic',
        'created_at': now,
      },
      {
        'name': 'ЭкоПункт - Можга',
        'address': 'г. Можга, ул. Кирова, 42',
        'latitude': 56.4444,
        'longitude': 52.2667,
        'description': 'Приём макулатуры и пластика',
        'phone': '+7 (34139) 4-56-78',
        'working_hours': 'Пн-Сб: 9:00-18:00',
        'accepted_types': 'paper,plastic,glass',
        'created_at': now,
      },
      {
        'name': 'Пункт сбора - Глазов',
        'address': 'г. Глазов, ул. Мира, 10',
        'latitude': 58.1397,
        'longitude': 52.6575,
        'description': 'Городской пункт приёма',
        'phone': '+7 (34161) 3-45-67',
        'working_hours': 'Пн-Пт: 10:00-19:00',
        'accepted_types': 'paper,plastic,metal,batteries,electronics',
        'created_at': now,
      },
    ];

    for (final point in samplePoints) {
      await db.insert('recycling_points', point);
    }
  }

  // === Пользователи ===
  Future<int> createUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // === Заметки ===
  Future<int> createNote(Note note) async {
    final db = await database;
    return await db.insert('notes', note.toMap());
  }

  Future<List<Note>> getNotesByUser(int userId) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return Note.fromMap(maps[i]);
    });
  }

  Future<List<Note>> getNotesByDate(int userId, DateTime date) async {
    final db = await database;
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final maps = await db.query(
      'notes',
      where: 'user_id = ? AND date >= ? AND date < ?',
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
    );

    return List.generate(maps.length, (i) {
      return Note.fromMap(maps[i]);
    });
  }

  Future<List<Note>> getNotesWithReminders(int userId) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'user_id = ? AND reminder_time IS NOT NULL AND is_completed = 0',
      whereArgs: [userId],
      orderBy: 'reminder_time ASC',
    );

    return List.generate(maps.length, (i) {
      return Note.fromMap(maps[i]);
    });
  }

  Future<int> updateNote(Note note) async {
    final db = await database;
    return db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === Пункты приёма ===
  Future<int> createRecyclingPoint(RecyclingPoint point) async {
    final db = await database;
    return await db.insert('recycling_points', point.toMap());
  }

  Future<List<RecyclingPoint>> getAllRecyclingPoints() async {
    final db = await database;
    final maps = await db.query('recycling_points');

    return List.generate(maps.length, (i) {
      return RecyclingPoint.fromMap(maps[i]);
    });
  }

  Future<List<RecyclingPoint>> getRecyclingPointsByType(String type) async {
    final db = await database;
    final maps = await db.query(
      'recycling_points',
      where: 'accepted_types LIKE ?',
      whereArgs: ['%$type%'],
    );

    return List.generate(maps.length, (i) {
      return RecyclingPoint.fromMap(maps[i]);
    });
  }

  Future<int> updateRecyclingPoint(RecyclingPoint point) async {
    final db = await database;
    return db.update(
      'recycling_points',
      point.toMap(),
      where: 'id = ?',
      whereArgs: [point.id],
    );
  }

  Future<int> deleteRecyclingPoint(int id) async {
    final db = await database;
    return await db.delete(
      'recycling_points',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    // Сначала удаляем заметки (из-за FOREIGN KEY)
    await db.delete(
      'notes',
      where: 'user_id = ?',
      whereArgs: [id],
    );
    // Затем удаляем пользователя
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Получение статистики пользователя
  Future<Map<String, int>> getUserStats(int userId) async {
    final db = await database;

    // Количество заметок
    final notesCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM notes WHERE user_id = ?',
        [userId],
      ),
    ) ?? 0;

    // Количество выполненных заметок
    final completedNotesCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM notes WHERE user_id = ? AND is_completed = 1',
        [userId],
      ),
    ) ?? 0;

    // Заметки по категориям (для будущей статистики)
    await db.rawQuery(
      'SELECT category, COUNT(*) as count FROM notes WHERE user_id = ? AND category IS NOT NULL GROUP BY category',
      [userId],
    );

    // Заметки с высоким приоритетом
    final highPriorityCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM notes WHERE user_id = ? AND priority = 2',
        [userId],
      ),
    ) ?? 0;

    return {
      'totalNotes': notesCount,
      'completedNotes': completedNotesCount,
      'highPriorityNotes': highPriorityCount,
    };
  }

  /// Поиск заметок по тексту
  Future<List<Note>> searchNotes(int userId, String query) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'user_id = ? AND (title LIKE ? OR content LIKE ?)',
      whereArgs: [userId, '%$query%', '%$query%'],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return Note.fromMap(maps[i]);
    });
  }

  /// Получение заметок по категории
  Future<List<Note>> getNotesByCategory(int userId, String category) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'user_id = ? AND category = ?',
      whereArgs: [userId, category],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return Note.fromMap(maps[i]);
    });
  }

  /// Получение заметок по приоритету
  Future<List<Note>> getNotesByPriority(int userId, NotePriority priority) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'user_id = ? AND priority = ?',
      whereArgs: [userId, priority.value],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return Note.fromMap(maps[i]);
    });
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
