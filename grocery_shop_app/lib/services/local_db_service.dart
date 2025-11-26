import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class LocalDBService {
  static Database? _db;

  static Future<Database> _openDB() async {
    if (_db != null) return _db!;

    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'recommendation.sqlite3');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS collector_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_type TEXT,
            product_id TEXT,
            user_id TEXT,
            session_id TEXT,
            timestamp TEXT
          )
        ''');
      },
    );

    return _db!;
  }

  static Future<void> insertLog(Map<String, dynamic> data) async {
    final db = await _openDB();
    await db.insert("collector_log", data);
  }
}
