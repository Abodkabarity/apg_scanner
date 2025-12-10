import 'package:hive/hive.dart';

import '../model/stock_taking_model.dart';

class StockLocalService {
  static const String boxName = 'stock_items';

  Future<Box> _openBox() async {
    return await Hive.openBox(boxName);
  }

  Future<List<StockItemModel>> loadItems(String projectId) async {
    final box = await _openBox();
    return box.values
        .where(
          (e) =>
              e is StockItemModel && e.projectId == projectId && !e.isDeleted,
        )
        .cast<StockItemModel>()
        .toList();
  }

  Future<void> saveOrUpdate(StockItemModel item) async {
    final box = await _openBox();
    await box.put(item.id, item);
  }

  Future<void> deleteSoft(String id) async {
    final box = await _openBox();
    final item = box.get(id);

    if (item != null && item is StockItemModel) {
      final newItem = item.copyWith(
        isDeleted: true,
        isSynced: false,
        updatedAt: DateTime.now(),
      );
      await box.put(id, newItem);
    }
  }

  Future<List<StockItemModel>> getDirty(int projectId) async {
    final box = await _openBox();
    return box.values
        .where(
          (e) =>
              e is StockItemModel &&
              e.projectId == projectId &&
              (!e.isSynced || e.isDeleted),
        )
        .cast<StockItemModel>()
        .toList();
  }
}
