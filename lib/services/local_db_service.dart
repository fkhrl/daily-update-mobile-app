import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'taskdigest.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tasks table
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY,
        title TEXT,
        description TEXT,
        scheduled_at TEXT,
        is_instant INTEGER,
        is_notified INTEGER,
        status TEXT,
        priority TEXT,
        category TEXT,
        recurrence TEXT,
        recurrence_interval INTEGER,
        workspace_id INTEGER,
        dependency_id INTEGER,
        voice_note_path TEXT,
        attachments TEXT,
        reminders TEXT,
        subtasks TEXT
      )
    ''');

    // Habits table
    await db.execute('''
      CREATE TABLE habits(
        id INTEGER PRIMARY KEY,
        name TEXT,
        frequency TEXT,
        difficulty TEXT,
        time_of_day TEXT,
        color TEXT,
        reminder_time TEXT,
        is_completed_today INTEGER,
        streak INTEGER,
        progress REAL
      )
    ''');

    // Notes table
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY,
        content TEXT,
        is_markdown INTEGER,
        color TEXT,
        task_id INTEGER,
        voice_note_path TEXT,
        images TEXT,
        tags TEXT,
        created_at TEXT
      )
    ''');

    // Sync Queue table
    // action: 'CREATE', 'UPDATE', 'DELETE'
    // entity: 'task', 'habit', 'note'
    await db.execute('''
      CREATE TABLE sync_queue(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT,
        entity TEXT,
        entity_id INTEGER,
        payload TEXT,
        created_at TEXT
      )
    ''');
  }

  // --- Sync Queue Helpers ---
  
  Future<void> addToSyncQueue(String action, String entity, int? entityId, Map<String, dynamic> payload) async {
    final db = await database;
    await db.insert('sync_queue', {
      'action': action,
      'entity': entity,
      'entity_id': entityId,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    return await db.query('sync_queue', orderBy: 'id ASC');
  }

  Future<void> removeFromSyncQueue(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearSyncQueue() async {
    final db = await database;
    await db.delete('sync_queue');
  }

  // --- Generic Save/Fetch Helpers ---

  Future<void> saveTasks(List<dynamic> tasks) async {
    final db = await database;
    Batch batch = db.batch();
    await db.delete('tasks'); // Replace all logic for simplicity
    for (var task in tasks) {
      batch.insert('tasks', {
        'id': task['id'],
        'title': task['title'],
        'description': task['description'],
        'scheduled_at': task['scheduled_at'],
        'is_instant': task['is_instant'] == true ? 1 : 0,
        'is_notified': task['is_notified'] == true ? 1 : 0,
        'status': task['status'],
        'priority': task['priority'],
        'category': task['category'],
        'recurrence': task['recurrence'],
        'recurrence_interval': task['recurrence_interval'],
        'workspace_id': task['workspace_id'],
        'dependency_id': task['dependency_id'],
        'voice_note_path': task['voice_note_path'],
        'attachments': jsonEncode(task['attachments'] ?? []),
        'reminders': jsonEncode(task['reminders'] ?? []),
        'subtasks': jsonEncode(task['subtasks'] ?? []),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<dynamic>> getTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks');
    return maps.map((map) {
      final task = Map<String, dynamic>.from(map);
      task['is_instant'] = map['is_instant'] == 1;
      task['is_notified'] = map['is_notified'] == 1;
      try { task['attachments'] = jsonDecode(map['attachments']); } catch (_) {}
      try { task['reminders'] = jsonDecode(map['reminders']); } catch (_) {}
      try { task['subtasks'] = jsonDecode(map['subtasks']); } catch (_) {}
      return task;
    }).toList();
  }

  Future<void> updateTaskLocal(int id, Map<String, dynamic> data) async {
    final db = await database;
    await db.update('tasks', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertTaskLocal(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('tasks', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  
  Future<void> deleteTaskLocal(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
