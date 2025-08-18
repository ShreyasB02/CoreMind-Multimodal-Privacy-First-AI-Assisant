import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class MemoryDatabase {
  static Database? _database;
  static const String _dbName = 'coremind_memories.db';
  static const int _dbVersion = 1;

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Main memories table for semantic storage
    await db.execute('''
      CREATE TABLE memories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        content_type TEXT NOT NULL,
        embedding BLOB,
        timestamp INTEGER NOT NULL,
        context_metadata TEXT,
        privacy_level INTEGER DEFAULT 0,
        source_app TEXT,
        user_rating INTEGER DEFAULT 0
      )
    ''');

    // Conversations table for dialog context
    await db.execute('''
      CREATE TABLE conversations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        metadata TEXT
      )
    ''');

    // App integrations log
    await db.execute('''
      CREATE TABLE app_interactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        target_app TEXT NOT NULL,
        action_type TEXT NOT NULL,
        parameters TEXT,
        result TEXT,
        timestamp INTEGER NOT NULL,
        success INTEGER DEFAULT 1
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_memories_timestamp ON memories(timestamp)');
    await db.execute('CREATE INDEX idx_memories_privacy ON memories(privacy_level)');
    await db.execute('CREATE INDEX idx_conversations_session ON conversations(session_id)');
  }

  // Store a semantic memory
  Future<int> insertMemory({
    required String content,
    required String contentType,
    List<double>? embedding,
    Map<String, dynamic>? metadata,
    int privacyLevel = 0,
    String? sourceApp,
  }) async {
    final db = await database;

    final embeddingBlob = embedding != null
        ? Float64List.fromList(embedding).buffer.asUint8List()
        : null;

    return await db.insert('memories', {
      'content': content,
      'content_type': contentType,
      'embedding': embeddingBlob,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'context_metadata': jsonEncode(metadata ?? {}),
      'privacy_level': privacyLevel,
      'source_app': sourceApp,
      'user_rating': 0,
    });
  }

  // Retrieve recent memories
  Future<List<Map<String, dynamic>>> getRecentMemories({
    int limit = 20,
    int maxPrivacyLevel = 2,
  }) async {
    final db = await database;

    return await db.query(
      'memories',
      where: 'privacy_level <= ?',
      whereArgs: [maxPrivacyLevel],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  // Search memories by content (simple text search for now)
  Future<List<Map<String, dynamic>>> searchMemories(
      String query, {
        int limit = 10,
        int maxPrivacyLevel = 2,
      }) async {
    final db = await database;

    return await db.query(
      'memories',
      where: 'content LIKE ? AND privacy_level <= ?',
      whereArgs: ['%$query%', maxPrivacyLevel],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  // Store conversation turn
  Future<int> insertConversation({
    required String sessionId,
    required String role,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    final db = await database;

    return await db.insert('conversations', {
      'session_id': sessionId,
      'role': role,
      'content': content,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'metadata': jsonEncode(metadata ?? {}),
    });
  }

  // Get conversation history
  Future<List<Map<String, dynamic>>> getConversationHistory(
      String sessionId, {
        int limit = 50,
      }) async {
    final db = await database;

    return await db.query(
      'conversations',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
      limit: limit,
    );
  }

  // Log app interaction
  Future<int> logAppInteraction({
    required String targetApp,
    required String actionType,
    Map<String, dynamic>? parameters,
    String? result,
    bool success = true,
  }) async {
    final db = await database;

    return await db.insert('app_interactions', {
      'target_app': targetApp,
      'action_type': actionType,
      'parameters': jsonEncode(parameters ?? {}),
      'result': result,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'success': success ? 1 : 0,
    });
  }

  // Privacy-first: Clear sensitive data
  Future<void> clearPrivateMemories() async {
    final db = await database;
    await db.delete('memories', where: 'privacy_level >= ?', whereArgs: [3]);
    await db.delete('conversations', where: 'timestamp < ?',
        whereArgs: [DateTime.now().subtract(Duration(days: 7)).millisecondsSinceEpoch]);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
