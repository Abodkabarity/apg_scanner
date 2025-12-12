import 'package:uuid/uuid.dart';

import '../../core/di/injection.dart';
import '../../core/session/user_session.dart';
import '../../core/supabase/supbase_services.dart';
import '../model/products_model.dart';
import '../model/session_model.dart';
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

  Future<StockItemModel?> findExistingItem(
    String projectId,
    String itemCode,
  ) async {
    final items = await loadItems(projectId);
    try {
      return items.firstWhere((e) => e.itemCode == itemCode && !e.isDeleted);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveNewItem({
    required String projectId,
    required String barcode,
    required ProductModel product,
    required int qty,
    required String unit,
  }) async {
    final numberSubUnit = product.numberSubUnit;

    final subQty = (unit.toLowerCase() == "box") ? qty : qty / numberSubUnit;
    final item = StockItemModel(
      id: const Uuid().v4(),
      projectId: projectId,
      branchName: session.branch!,
      barcode: barcode,
      itemId: product.id,
      itemCode: product.itemCode,
      itemName: product.itemName,
      unit: unit,
      subUnit: product.subUnit,
      quantity: qty,
      subQuantity: subQty,
      isDeleted: false,
      isSynced: false,

      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await local.saveOrUpdate(item);
  }

  Future<void> updateItem({
    required StockItemModel item,
    required int qty,
    required String unit,
    required ProductModel product,
  }) async {
    final numberSubUnit = product.numberSubUnit;

    final subQty = (unit.toLowerCase() == "box") ? qty : qty / numberSubUnit;
    final updated = item.copyWith(
      quantity: qty,
      subQuantity: subQty,
      unit: unit,
      updatedAt: DateTime.now(),
      isSynced: false,
    );

    await local.saveOrUpdate(updated);
  }

  Future<void> delete(String id) async {
    await local.deleteSoft(id);
  }

  Future<void> syncUp(String projectId) async {
    final dirtyItems = await local.getDirty(projectId);
    if (dirtyItems.isEmpty) return;

    await remote.syncUp(dirtyItems);

    for (final item in dirtyItems) {
      await local.saveOrUpdate(
        item.copyWith(isSynced: true, updatedAt: DateTime.now()),
      );
    }
  }

  Future<void> debugPrintAll(String projectId) async {
    final items = await local.loadItems(projectId);

    print("===== DEBUG: ITEMS IN HIVE FOR PROJECT = $projectId =====");

    for (final i in items) {
      print("----------------------------------");
      print("ID: ${i.id}");
      print("Barcode: ${i.barcode}");
      print("Item Code: ${i.itemCode}");
      print("Item Name: ${i.itemName}");
      print("Unit: ${i.unit}");
      print("SubUnit: ${i.subUnit}");
      print("Qty: ${i.quantity}");
      print("Sub QTY: ${i.subQuantity}");
      print("Synced: ${i.isSynced}");
      print("Deleted: ${i.isDeleted}");
      print("Created: ${i.createdAt}");
    }

    print("=========== END DEBUG ===========");
  }

  Future<void> uploadStockItems({
    required String projectId,
    required List<StockItemModel> items,
  }) async {
    final session = getIt<BranchSession>();
    print(session.branchName);
    final payload = items.map((e) {
      return {
        "id": e.id,
        "project_name": projectId,
        "branch": session.branchName,
        "item_code": e.itemCode,
        "item_name": e.itemName,
        "barcode": e.barcode,
        "unit_type": e.unit,
        "quantity": e.quantity,
        "sub_quantity": e.subQuantity,
        "created_at": e.createdAt.toIso8601String(),
        "updated_at": DateTime.now().toIso8601String(),
      };
    }).toList();

    await supabase.from("stock_taking_items").insert(payload);
  }
}
