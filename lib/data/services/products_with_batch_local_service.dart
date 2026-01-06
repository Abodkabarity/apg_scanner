import 'package:hive/hive.dart';

import '../model/product_with_batch_model.dart';

class ProductsWithBatchLocalService {
  static const String boxName = 'products_with_batch_box';
  static const String metaBoxName = 'products_with_batch_meta';

  Future<Box> _openBox() => Hive.openBox(boxName);
  Future<Box> _openMeta() => Hive.openBox(metaBoxName);

  Future<void> saveAll(List<ProductWithBatchModel> items) async {
    final box = await _openBox();
    final Map<String, Map> map = {for (final p in items) p.cacheKey: p.toMap()};
    await box.putAll(map);
  }

  Future<int> count() async {
    final box = await _openBox();
    return box.length;
  }

  Future<void> clear() async {
    final box = await _openBox();
    await box.clear();
  }

  Future<List<ProductWithBatchModel>> loadAll() async {
    final box = await _openBox();
    return box.values
        .whereType<Map>()
        .map((m) => ProductWithBatchModel.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> setLastSync(String iso) async {
    final meta = await _openMeta();
    await meta.put('last_sync', iso);
  }

  Future<String?> getLastSync() async {
    final meta = await _openMeta();
    return meta.get('last_sync') as String?;
  }
}
