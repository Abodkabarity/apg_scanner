import 'package:hive/hive.dart';

import '../model/stock_batch_item_model.dart';

class StockBatchLocalService {
  static const String boxName = 'stock_batch_items_box';

  Future<Box> _open() => Hive.openBox(boxName);

  String _key(String projectId, String id) => '$projectId|$id';

  Future<void> saveItem(StockBatchItemModel item) async {
    final box = await _open();
    await box.put(_key(item.projectId, item.id), item.toJson());
  }

  Future<void> updateItem(StockBatchItemModel item) async {
    final box = await _open();
    await box.put(_key(item.projectId, item.id), item.toJson());
  }

  Future<StockBatchItemModel?> getById(String id) async {
    final box = await _open();
    // نبحث داخل القيم لأننا خزّنا key = project|id
    for (final v in box.values) {
      if (v is Map) {
        final m = Map<String, dynamic>.from(v);
        if ((m['id'] ?? '').toString() == id) {
          return StockBatchItemModel.fromJson(m);
        }
      }
    }
    return null;
  }

  Future<List<StockBatchItemModel>> loadItems(String projectId) async {
    final box = await _open();

    final items = <StockBatchItemModel>[];
    for (final entry in box.toMap().entries) {
      final k = entry.key.toString();
      if (!k.startsWith('$projectId|')) continue;

      final v = entry.value;
      if (v is Map) {
        items.add(StockBatchItemModel.fromJson(Map<String, dynamic>.from(v)));
      }
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> clearProject(String projectId) async {
    final box = await _open();
    final keysToDelete = box.keys
        .where((k) => k.toString().startsWith('$projectId|'))
        .toList();
    await box.deleteAll(keysToDelete);
  }

  Future<void> clearAll() async {
    final box = await _open();
    await box.clear();
  }
}
