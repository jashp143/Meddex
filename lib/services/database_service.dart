import 'package:sqflite/sqflite.dart';
import '../repositories/base_repository.dart';

class DatabaseService<T extends DatabaseItem> {
  final Database database;
  final String tableName;
  final T Function(Map<String, dynamic>) fromMap;

  DatabaseService({
    required this.database,
    required this.tableName,
    required this.fromMap,
  });

  Future<void> insert(T item) async {
    await database.insert(
      tableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(T item) async {
    await database.update(
      tableName,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> delete(String id) async {
    await database.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<T?> getById(String id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return fromMap(maps.first);
  }

  Future<List<T>> getAll() async {
    final List<Map<String, dynamic>> maps = await database.query(tableName);
    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  Future<void> deleteAll() async {
    await database.delete(tableName);
  }

  Future<List<T>> query({
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  Future<int> count({
    String? where,
    List<Object?>? whereArgs,
  }) async {
    return Sqflite.firstIntValue(
          await database.query(
            tableName,
            columns: ['COUNT(*)'],
            where: where,
            whereArgs: whereArgs,
          ),
        ) ??
        0;
  }
}
