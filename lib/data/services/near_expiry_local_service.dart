import 'package:hive/hive.dart';

import '../../core/di/injection.dart';
import '../../core/session/user_session.dart';
import '../model/near_expiry_item_model.dart';

class NearExpiryLocalService {
  Future<Box> _openBox() async {
    final userId = getIt<UserSession>().userId;

    if (userId == null || userId.isEmpty) {
      throw Exception("User not logged in - userId is null");
    }

    final boxName = 'near_expiry_items_$userId';

    return await Hive.openBox(boxName);
  }

  Future<List<NearExpiryItemModel>> loadItems(String projectId) async {
    final box = await _openBox();

    return box.values
        .where((e) => e is NearExpiryItemModel && e.projectId == projectId)
        .cast<NearExpiryItemModel>()
        .toList();
  }

  Future<void> saveOrUpdate(NearExpiryItemModel item) async {
    final box = await _openBox();
    await box.put(item.id, item);
  }

  Future<void> deleteSoft(String id) async {
    final box = await _openBox();

    for (final key in box.keys) {
      final item = box.get(key);

      if (item is NearExpiryItemModel && item.id == id) {
        await box.put(
          key,
          item.copyWith(
            isDeleted: true,
            isSynced: false,
            updatedAt: DateTime.now(),
          ),
        );
        return;
      }
    }

    throw Exception("Item not found for soft delete: $id");
  }

  Future<List<NearExpiryItemModel>> getDirty(String projectId) async {
    final box = await _openBox();

    return box.values
        .where(
          (e) =>
              e is NearExpiryItemModel &&
              e.projectId == projectId &&
              (!e.isSynced || e.isDeleted),
        )
        .cast<NearExpiryItemModel>()
        .toList();
  }
}
