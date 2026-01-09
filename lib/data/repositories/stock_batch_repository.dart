import 'package:supabase_flutter/supabase_flutter.dart';
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
    required String? batch,
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
    required String? batch,
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
      subUnitQty: product.subunitQty == null
          ? null
          : (product.subunitQty as num).toDouble(),

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
  Future<bool> syncUp(String projectId) async {
    final items = await loadItems(projectId);

    final pending = items.where((e) => !e.isSynced).toList();

    if (pending.isEmpty) {
      return false;
    }

    final Map<String, List<StockBatchItemModel>> grouped = {};

    for (final item in pending) {
      final key = '${item.itemCode}__${item.batch ?? '-'}';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(item);
    }

    final List<Map<String, dynamic>> payload = [];

    for (final entry in grouped.entries) {
      final rows = entry.value;
      final first = rows.first;

      double totalQty = 0;

      for (final r in rows) {
        if (r.unitType.toUpperCase() == 'BOX') {
          totalQty += r.quantity;
        } else {
          final sub = (r.subUnitQty ?? 1);
          if (sub <= 0) {
            totalQty += r.quantity;
          } else {
            totalQty += (r.quantity / sub);
          }
        }
      }

      payload.add({
        'id': first.id,

        'project_id': first.projectId,
        'project_name': first.projectName,
        'branch_name': first.branchName.isEmpty
            ? session.branch
            : first.branchName,

        'item_code': first.itemCode,
        'item_name': first.itemName,
        'barcode': first.barcode,
        'is_deleted': first.isDeleted,

        'unit': 'BOX',
        'qty': totalQty,

        'near_expiry': first.nearExpiry?.toIso8601String(),
        'batch': first.batch,

        'created_at': first.createdAt.toUtc().toIso8601String(),
      });
    }

    await remote.uploadBatchItems(payload);

    for (final item in pending) {
      await local.updateItem(item.copyWith(isSynced: true));
    }

    return true;
  }

  // ---------------------------------------------------------------------------
  // CLEAR PROJECT
  // ---------------------------------------------------------------------------
  Future<void> clearProject(String projectId) {
    return local.clearProject(projectId);
  }

  // ---------------------------------------------------------------------------
  // EXCEL EXPORT
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> buildStockBatchExcelData({
    required String projectId,
  }) async {
    final items = await loadItems(projectId);
    final visible = items.where((e) => !e.isDeleted).toList();

    if (visible.isEmpty) return [];

    final Map<String, List<StockBatchItemModel>> grouped = {};

    for (final it in visible) {
      final key = '${it.itemCode}__${it.batch ?? '-'}';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(it);
    }

    final List<Map<String, dynamic>> result = [];

    for (final entry in grouped.entries) {
      final rows = entry.value;
      final first = rows.first;

      double totalQty = 0;
      final Map<String, double> unitQty = {};

      for (final r in rows) {
        unitQty[r.unitType] = (unitQty[r.unitType] ?? 0) + r.quantity;

        if (r.unitType.toUpperCase() == 'BOX') {
          totalQty += r.quantity;
        } else {
          final sub = r.subUnitQty ?? 1;
          if (sub > 0) {
            totalQty += r.quantity / sub;
          }
        }
      }

      result.add({
        'Branch': first.branchName,
        'Item Code': first.itemCode,
        'Item Name': first.itemName,
        'Barcode': first.barcode,
        'Batch': first.batch ?? '',
        'Near Expiry': first.nearExpiry != null
            ? first.nearExpiry!.toIso8601String()
            : '',
        'Units': unitQty.entries
            .map((e) => '${e.key}: ${e.value.toInt()}')
            .join(' | '),
        'Total Qty (BOX)': totalQty,
        'Created At': first.createdAt.toIso8601String(),
      });
    }

    return result;
  }

  Future<void> updateFullItem({required StockBatchItemModel item}) async {
    await local.updateItem(item.copyWith(isSynced: false));
  }

  Future<void> addManualRow({
    required String projectId,
    required String projectName,
    required String branchName,
    required String itemCode,
    required String itemName,
    required String barcode,
    required String unitType,
    required double qty,
    required DateTime? nearExpiry,
    required String? batch,
  }) async {
    final item = StockBatchItemModel(
      id: const Uuid().v4(),
      projectId: projectId,
      projectName: projectName,
      branchName: branchName,
      itemCode: itemCode,
      itemName: itemName,
      barcode: barcode,
      unitType: unitType,
      quantity: qty,
      nearExpiry: nearExpiry,
      batch: batch,
      isSynced: false,
      isDeleted: false,
      createdAt: DateTime.now(),
    );

    await local.saveItem(item);
  }

  Future<List<Map<String, dynamic>>> loadExcelDataFromSupabase({
    required String projectId,
  }) async {
    final res = await Supabase.instance.client
        .from('stock_taking_batch_items')
        .select()
        .eq('project_id', projectId)
        .eq('is_deleted', false)
        .order('created_at');

    if (res.isEmpty) return [];

    return res.map<Map<String, dynamic>>((e) {
      return {
        'Branch': e['branch_name'] ?? '',
        'Item Code': e['item_code'] ?? '',
        'Item Name': e['item_name'] ?? '',
        'Barcode': e['barcode'] ?? '',
        'Unit': e['unit'] ?? 'BOX', // دائمًا BOX
        'Quantity': e['qty'] ?? 0,
        'Near Expiry': e['near_expiry'] ?? '',
        'Batch': e['batch'] ?? '',
        'Created At': e['created_at'] ?? '',
      };
    }).toList();
  }
}
