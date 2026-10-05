import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables.dart';
import '../../domain/entities/reminder.dart';

class ReminderRepository {
  final AppDatabase _db;

  ReminderRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  Future<List<Reminder>> getAllReminders() async {
    final db = await _db.database;
    final results = await db.query(
      DbTables.reminders,
      orderBy: '${DbColumns.createdAt} DESC',
    );
    return results.map((row) => Reminder.fromMap(row)).toList();
  }

  Future<Reminder?> getReminderById(String id) async {
    final db = await _db.database;
    final results = await db.query(
      DbTables.reminders,
      where: '${DbColumns.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Reminder.fromMap(results.first);
  }

  Future<void> insertReminder(Reminder reminder) async {
    final db = await _db.database;
    await db.insert(
      DbTables.reminders,
      reminder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateReminder(Reminder reminder) async {
    final db = await _db.database;
    await db.update(
      DbTables.reminders,
      reminder.toMap(),
      where: '${DbColumns.id} = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<void> deleteReminder(String id) async {
    final db = await _db.database;
    await db.delete(
      DbTables.reminders,
      where: '${DbColumns.id} = ?',
      whereArgs: [id],
    );
  }
}
