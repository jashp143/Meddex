abstract class BaseRepository<T> {
  Future<void> insert(T item);
  Future<void> update(T item);
  Future<void> delete(String id);
  Future<T?> getById(String id);
  Future<List<T>> getAll();
  Future<void> deleteAll();
}

abstract class DatabaseItem {
  String get id;
  Map<String, dynamic> toJson();
  Map<String, dynamic> toMap();
}
