abstract class PresetRepository<T> {
  Future<List<T>> getAll();

  Future<T?> getById(String id);

  Future<void> save(T item);

  Future<void> delete(String id);
}