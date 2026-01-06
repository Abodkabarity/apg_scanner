import 'package:uuid/uuid.dart';

import '../../core/session/user_session.dart';
import '../model/product_with_batch_model.dart';
import '../model/stock_batch_item_model.dart';
import '../remote/stock_batch_remote_service.dart';
import '../services/stock_batch_local_service.dart';

class StockBatchRepository {
  final StockBatchLocalService local;
  final StockBatchRemoteService remote;
  final UserSession session;

  StockBatchRepository(this.local, this.remote, this.session);

  // ---------------------------------------------------------------------------
  // LOAD
  // ---------------------------------------------------------------------------
  Future<List<StockBatchItemModel>> loadItems(String projectId) {
    return local.loadItems(projectId);
  }

  // ---------------------------------------------------------------------------
  // FIND EXISTING
  // Identity: project + item_code + unit + batch
  // ---------------------------------------------------------------------------
  Future<StockBatchItemModel?> findExistingItem({
    required String projectId,
    required String itemCode,
    required String unit,
    required String batch,
  }) async {
    final items = await loadItems(projectId);

    try {
      return items.firstWhere(
        (e) =>
            !e.isDeleted &&
            e.itemCode == itemCode &&
            e.unitType == unit &&
            (e.batch ?? '') == batch,
      );
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // SAVE NEW
  // ---------------------------------------------------------------------------
  Future<void> saveNewItem({
    required String projectId,
    required String projectName,
    required String branchName,
    required ProductWithBatchModel product,
    required String barcode,
    required String unit,
    required double qty,
    required DateTime? expiry,
    required String batch,
  }) async {
    final item = StockBatchItemModel(
      id: const Uuid().v4(),
      projectId: projectId,
      projectName: projectName,
      branchName: branchName,

      itemCode: product.itemCode,
      itemName: product.itemName,
      barcode: barcode,

      unitType: unit,
      quantity: qty,

      nearExpiry: expiry,
      batch: batch,

      isSynced: false,
      isDeleted: false,
      createdAt: DateTime.now(),
    );

    await local.saveItem(item);
  }

  // ---------------------------------------------------------------------------
  // UPDATE QTY
  // ---------------------------------------------------------------------------
  Future<void> updateItemQty({
    required StockBatchItemModel item,
    required double qty,
  }) async {
    await local.updateItem(item.copyWith(quantity: qty, isSynced: false));
  }

  // ---------------------------------------------------------------------------
  // DELETE (SOFT)
  // ---------------------------------------------------------------------------
  Future<void> delete(String id) async {
    final item = await local.getById(id);
    if (item == null) return;

    await local.updateItem(item.copyWith(isDeleted: true, isSynced: false));
  }

  // ---------------------------------------------------------------------------
  // SYNC UP (UPLOAD)
  // ---------------------------------------------------------------------------
  Future<void> syncUp(String projectId) async {
    final items = await loadItems(projectId);

    final toUpload = items.where((e) => !e.isDeleted && !e.isSynced).toList();
    if (toUpload.isEmpty) return;

    final payload = toUpload.map((e) {
      return {
        'id': e.id, // نرفع نفس id
        'project_id': e.projectId,
        'project_name': e.projectName,
        'branch_name': e.branchName.isEmpty ? session.branch : e.branchName,

        'item_code': e.itemCode,
        'item_name': e.itemName,
        'barcode': e.barcode,

        'unit': e.unitType,
        'qty': e.quantity,

        'near_expiry': e.nearExpiry?.toIso8601String(),
        'batch': e.batch,

        'created_at': e.createdAt.toUtc().toIso8601String(),
      };
    }).toList();

    await remote.uploadBatchItems(payload);

    // mark synced
    for (final item in toUpload) {
      await local.updateItem(item.copyWith(isSynced: true));
    }
  }

  // ---------------------------------------------------------------------------
  // CLEAR PROJECT
  // ---------------------------------------------------------------------------
  Future<void> clearProject(String projectId) {
    return local.clearProject(projectId);
  }
}
