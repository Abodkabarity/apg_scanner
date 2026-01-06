import 'package:uuid/uuid.dart';

import '../../core/session/user_session.dart';
import '../model/product_unit_map_model.dart';
import '../remote/product_unit_remote_service.dart';
import '../services/product_unit_local_service.dart';

class ProductUnitRepository {
  final ProductUnitLocalService local;
  final ProductUnitRemoteService remote;
  final UserSession session;

  final _uuid = const Uuid();

  ProductUnitRepository({
    required this.local,
    required this.remote,
    required this.session,
  });

  Future<List<String>> loadUnitsDistinct() {
    return remote.fetchAllUnitsDistinct();
  }

  Future<List<ProductUnitMapModel>> loadPending() {
    return local.loadPending();
  }

  Future<void> addPending({
    required String itemCode,
    required String itemName,
    required String barcode,
    required String unit,
  }) async {
    final list = await local.loadPending();

    final item = ProductUnitMapModel(
      id: _uuid.v4(),
      itemCode: itemCode,
      itemName: itemName,
      barcode: barcode,
      unit: unit,
      createdAt: DateTime.now(),
    );

    if (list.any((e) => e.key == item.key)) return;

    list.insert(0, item);
    await local.savePending(list);
  }

  Future<void> removePendingByKey(String key) async {
    final list = await local.loadPending();
    list.removeWhere((e) => e.key == key);
    await local.savePending(list);
  }

  Future<void> clearPending() => local.clear();

  Future<int> syncPending() async {
    final list = await local.loadPending();
    if (list.isEmpty) return 0;

    final createdBy = session.userId; // عدّل حسب UserSession عندك
    await remote.upsertMappings(items: list, createdBy: createdBy);

    await local.clear();
    return list.length;
  }
}
