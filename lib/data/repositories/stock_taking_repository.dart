import 'package:uuid/uuid.dart';

import '../../core/session/user_session.dart';
import '../model/products_model.dart';
import '../model/stock_taking_model.dart';
import '../remote/stock_remote_service.dart';
import '../services/stock_local_service.dart';

class StockRepository {
  final StockLocalService local;
  final StockRemoteService remote;
  final UserSession session;

  StockRepository(this.local, this.remote, this.session);

  Future<List<StockItemModel>> loadItems(String projectId) {
    return local.loadItems(projectId);
  }

  Future<void> scanAndAdd({
    required String projectId,
    required String barcode,
    required ProductModel product,
    required int qty,
  }) async {
    final item = StockItemModel(
      id: const Uuid().v4(),
      projectId: projectId,
      branchName: session.branch!,
      barcode: barcode,
      itemId: product.id,
      itemCode: product.itemCode,
      itemName: product.itemName,
      unit: product.unit,
      subUnit: product.subUnit,
      quantity: qty,
      isDeleted: false,
      isSynced: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await local.saveOrUpdate(item);
  }

  Future<void> delete(String id) async {
    await local.deleteSoft(id);
  }

  Future<void> syncUp(int projectId) async {
    final dirtyItems = await local.getDirty(projectId);
    if (dirtyItems.isEmpty) return;

    await remote.syncUp(dirtyItems);

    for (final item in dirtyItems) {
      await local.saveOrUpdate(
        item.copyWith(isSynced: true, updatedAt: DateTime.now()),
      );
    }
  }
}
