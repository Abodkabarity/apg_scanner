import 'package:apg_scanner/data/repositories/products_repository.dart';
import 'package:uuid/uuid.dart';

import '../../core/session/user_session.dart';
import '../../core/supabase/supbase_services.dart';
import '../../core/utils/excel_exporter.dart';
import '../model/near_expiry_item_model.dart';
import '../model/products_model.dart';
import '../remote/near_expiry_remote_service.dart';
import '../services/near_expiry_local_service.dart';

class NearExpiryRepository {
  final NearExpiryLocalService local;
  final NearExpiryRemoteService remote;
  final UserSession session;
  final ProductsRepository productsRepo;

  double _toBoxQty({
    required int qty,
    required String unitType,
    required ProductModel product,
  }) {
    if (unitType.toUpperCase() == 'BOX') {
      return qty.toDouble();
    }

    final subUnitCount = product.numberSubUnit;
    if (subUnitCount <= 0) {
      return qty.toDouble();
    }

    return qty / subUnitCount;
  }

  NearExpiryRepository(
    this.local,
    this.remote,
    this.session,
    this.productsRepo,
  );

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------
  Future<List<NearExpiryItemModel>> loadItems(String projectId) {
    return local.loadItems(projectId);
  }

  // ---------------------------------------------------------------------------
  // Find existing item (IMPORTANT LOGIC)
  // same itemCode + same nearExpiry = same row
  // ---------------------------------------------------------------------------
  Future<NearExpiryItemModel?> findExistingItem({
    required String projectId,
    required String itemCode,
    required DateTime nearExpiry,
    required String unitType,
  }) async {
    final items = await loadItems(projectId);

    try {
      return items.firstWhere(
        (e) =>
            e.itemCode == itemCode &&
            e.unitType.toLowerCase() == unitType.toLowerCase() &&
            _sameDate(e.nearExpiry, nearExpiry) &&
            !e.isDeleted,
      );
    } catch (_) {
      return null;
    }
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ---------------------------------------------------------------------------
  // Save new item (NEW ROW ALWAYS if date different)
  // ---------------------------------------------------------------------------
  Future<void> saveNewItem({
    required String projectId,
    required String projectName,
    required String barcode,
    required ProductModel product,
    required int qty,
    required String unitType,
    required DateTime nearExpiry,
  }) async {
    final item = NearExpiryItemModel(
      id: const Uuid().v4(),
      projectId: projectId,
      projectName: projectName,
      branchName: session.branch!,
      barcode: barcode,
      itemCode: product.itemCode,
      itemName: product.itemName,
      unitType: unitType,
      quantity: qty,
      nearExpiry: nearExpiry,
      isDeleted: false,
      isSynced: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await local.saveOrUpdate(item);
  }

  // ---------------------------------------------------------------------------
  // Update quantity only
  // ---------------------------------------------------------------------------
  Future<void> updateItemQty({
    required NearExpiryItemModel item,
    required int qty,
  }) async {
    final updated = item.copyWith(
      quantity: qty,
      updatedAt: DateTime.now(),
      isSynced: false,
    );

    await local.saveOrUpdate(updated);
  }

  // ---------------------------------------------------------------------------
  // Soft delete
  // ---------------------------------------------------------------------------
  Future<void> delete(String id) async {
    await local.deleteSoft(id);
  }

  // ---------------------------------------------------------------------------
  // Sync
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Upload (Supabase)
  // ---------------------------------------------------------------------------
  Future<void> uploadNearExpiryItems({
    required String projectId,
    required List<NearExpiryItemModel> items,
  }) async {
    final branchName = session.branch;
    if (branchName == null) {
      throw Exception("Branch not found in session");
    }

    final modifiedItems = items.where((item) {
      return !item.isSynced || item.isDeleted;
    }).toList();

    if (modifiedItems.isEmpty) {
      throw Exception("No modified items to upload");
    }

    final payload = modifiedItems
        .map(
          (e) => {
            "id": e.id,
            "project_id": e.projectId,
            "project_name": e.projectName,
            "branch_name": branchName,
            "barcode": e.barcode,
            "item_code": e.itemCode,
            "item_name": e.itemName,
            "unit_type": e.unitType,
            "qty": e.quantity,
            "near_expiry": e.nearExpiry.toIso8601String(),
            "is_deleted": e.isDeleted,
            "updated_at": DateTime.now().toIso8601String(),
          },
        )
        .toList();

    await supabase.from("near_expiry_items").upsert(payload, onConflict: 'id');

    for (final item in modifiedItems) {
      await local.saveOrUpdate(item.copyWith(isSynced: true));
    }
  }

  Future<void> exportExcel({
    required String projectId,
    required String projectName,
  }) async {
    final items = (await loadItems(
      projectId,
    )).where((e) => !e.isDeleted).toList();

    if (items.isEmpty) {
      throw Exception("No items to export");
    }

    await productsRepo.ensureLoaded();

    final Map<String, double> totalBoxByKey = {};
    final Map<String, NearExpiryItemModel> sampleRow = {};

    for (final item in items) {
      final expiryMonth = DateTime(
        item.nearExpiry.year,
        item.nearExpiry.month,
        1,
      );

      final key = '${item.itemCode}__${expiryMonth.year}-${expiryMonth.month}';

      final product = productsRepo.products.firstWhere(
        (p) => p.itemCode == item.itemCode,
      );

      final boxQty = _toBoxQty(
        qty: item.quantity,
        unitType: item.unitType,
        product: product,
      );

      totalBoxByKey[key] = (totalBoxByKey[key] ?? 0) + boxQty;
      sampleRow.putIfAbsent(key, () => item);
    }

    final List<Map<String, dynamic>> data = [];

    totalBoxByKey.forEach((key, totalBoxQty) {
      final base = sampleRow[key]!;

      data.add({
        'branch': base.branchName,
        'item_code': base.itemCode,
        'item_name': base.itemName,
        'unit_type': 'BOX',
        'quantity': totalBoxQty,
        'near_expiry':
            '${base.nearExpiry.year}-${base.nearExpiry.month.toString().padLeft(2, '0')}',
      });
    });

    final safeName = projectName
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim();

    await ExcelExporter.saveExcelWithSystemPicker(
      data,
      fileName: 'near_expiry_$safeName.xlsx',
    );
  }

  Future<void> updateItemQtyAndExpiry({
    required NearExpiryItemModel item,
    required int qty,
    required DateTime nearExpiry,
  }) async {
    final updated = item.copyWith(
      quantity: qty,
      nearExpiry: DateTime(nearExpiry.year, nearExpiry.month, 1),
      updatedAt: DateTime.now(),
      isSynced: false,
    );

    await local.saveOrUpdate(updated);
  }

  Future<void> uploadNearExpiryPayload(
    List<Map<String, dynamic>> payload,
  ) async {
    await supabase.from("near_expiry_items").insert(payload);
  }

  Future<List<Map<String, dynamic>>> buildMergedNearExpiryExcelData(
    String projectId,
  ) async {
    final items = (await loadItems(
      projectId,
    )).where((e) => !e.isDeleted).toList();

    await productsRepo.ensureLoaded();

    final Map<String, double> totalBoxByKey = {};
    final Map<String, NearExpiryItemModel> sampleRow = {};

    for (final item in items) {
      final expiryMonth = DateTime(
        item.nearExpiry.year,
        item.nearExpiry.month,
        1,
      );

      final key = '${item.itemCode}__${expiryMonth.year}-${expiryMonth.month}';

      final product = productsRepo.products.firstWhere(
        (p) => p.itemCode == item.itemCode,
      );

      final boxQty = _toBoxQty(
        qty: item.quantity,
        unitType: item.unitType,
        product: product,
      );

      totalBoxByKey[key] = (totalBoxByKey[key] ?? 0) + boxQty;
      sampleRow.putIfAbsent(key, () => item);
    }

    final List<Map<String, dynamic>> data = [];

    totalBoxByKey.forEach((key, totalBoxQty) {
      final base = sampleRow[key]!;

      data.add({
        'branch': base.branchName,
        'item_code': base.itemCode,
        'item_name': base.itemName,
        'unit_type': 'BOX',
        'quantity': totalBoxQty,
        'near_expiry':
            '${base.nearExpiry.year}-${base.nearExpiry.month.toString().padLeft(2, '0')}',
      });
    });

    return data;
  }
}
