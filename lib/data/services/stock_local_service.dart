import 'package:hive/hive.dart';

import '../../core/di/injection.dart';
import '../../core/session/user_session.dart';
import '../model/stock_taking_model.dart';

class StockLocalService {
  Future<Box> _openBox() async {
    final userId = getIt<UserSession>().userId;

    if (userId == null || userId.isEmpty) {
      throw Exception("User not logged in - userId is null");
    }

    final boxName = 'stock_items_$userId';
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

  Future<List<StockItemModel>> getDirty(String projectId) async {
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
