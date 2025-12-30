import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../data/model/near_expiry_item_model.dart';
import '../../../../data/model/stock_item_group.dart';
import '../../../../data/repositories/branch_repository.dart';
import '../../../../data/repositories/near_expiry_repository.dart';
import '../../../../data/repositories/products_repository.dart';
import '../../../core/session/user_session.dart';
import '../../../data/model/products_model.dart';
import '../../../data/services/near_expiry_export_service.dart';
import 'near_expiry_event.dart';
import 'near_expiry_state.dart';

class NearExpiryBloc extends Bloc<NearExpiryEvent, NearExpiryState> {
  final NearExpiryRepository repo;
  final ProductsRepository productsRepo;

  NearExpiryBloc(this.repo, this.productsRepo)
    : super(const NearExpiryState()) {
    on<LoadNearExpiryEvent>(_onLoad);
    on<ScanBarcodeEvent>(_onScan);
    on<DeleteNearExpiryEvent>(_onDelete);
    on<SyncNearExpiryEvent>(_onSync);
    on<SearchScannedItemsEvent>(_onSearchScannedItems);

    on<ChangeSelectedIndexEvent>((event, emit) {
      emit(state.copyWith(selectedIndex: event.index));
    });

    on<ClearProductAlreadyExistsFlagEvent>((event, emit) {
      emit(state.copyWith(productAlreadyExists: false));
    });

    on<SendByEmailEvent>(_onSendByEmail);
    on<UpdateMultiUnitEvent>(_onUpdateMultiUnit);

    on<ExportExcelEvent>(_onExportExcel);
    on<UploadNearExpiryEvent>(_onUpload);

    on<ChangeUnitEvent>((event, emit) {
      emit(state.copyWith(selectedUnit: event.unit));
    });

    // ✅ FIXED HERE
    on<SetDuplicateActionEvent>((event, emit) {
      emit(state.copyWith(duplicateAction: event.action));
    });

    on<ChangeNearExpiryDateEvent>((event, emit) {
      emit(
        state.copyWith(
          selectedNearExpiry: DateTime(
            event.nearExpiry.year,
            event.nearExpiry.month,
            1,
          ),
        ),
      );
    });

    on<EditSingleUnitFromListEvent>((event, emit) async {
      await productsRepo.ensureLoaded();

      final matching = productsRepo.products
          .where((p) => p.itemCode == event.group.itemCode)
          .toList();

      if (matching.isEmpty) {
        emit(
          state.copyWith(
            error: "Product not found in master data",
            success: null,
          ),
        );
        return;
      }

      final product = matching.first;

      emit(
        state.copyWith(
          currentProduct: product,
          units: productsRepo.getUnitsForProduct(product),
          selectedUnit: event.unit,
          editingRowId: event.rowId,
          duplicateAction: NearDuplicateAction.edit,

          editingUnitQty: Map<String, int>.from(event.group.unitQty),
          editingNearExpiry: event.group.nearExpiry,

          error: null,
          success: null,
        ),
      );
    });

    on<UpdateEditingUnitQtyEvent>((event, emit) {
      final Map<String, int> base = {};

      if (state.editingUnitQty.isEmpty) {
        final group = state.groupedItems.firstWhere(
          (g) => g.unitQty.containsKey(event.unit),
          orElse: () => state.groupedItems.first,
        );

        base.addAll(group.unitQty);
      } else {
        base.addAll(state.editingUnitQty);
      }

      if (event.qty > 0) {
        base[event.unit] = event.qty;
      } else {
        base[event.unit] = 0;
      }

      emit(state.copyWith(editingUnitQty: base));
    });

    on<UpdateEditingNearExpiryEvent>((event, emit) {
      emit(
        state.copyWith(
          editingNearExpiry: DateTime(
            event.nearExpiry.year,
            event.nearExpiry.month,
            1,
          ),
        ),
      );
    });

    on<ApproveItemEvent>(_onApprove);
    on<ResetFormEvent>(_onResetForm);

    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<ProductChosenFromSearch>(_onProductChosenFromSearch);
    on<ScannedItemSelectedEvent>(_onScannedItemSelected);

    on<MarkProductExistsDialogShownEvent>((event, emit) {
      emit(state.copyWith(productExistsDialogShown: true));
    });
  }
  final session = getIt<UserSession>();

  List<DateTime> _generateNearExpiryMonths() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month + 2, 1);

    return List.generate(8, (i) => DateTime(start.year, start.month + i, 1));
  }

  double _toBoxQtyLocal({
    required int qty,
    required String unitType,
    required ProductModel product,
  }) {
    final unit = unitType.trim().toUpperCase();

    if (unit == 'BOX') {
      return qty.toDouble();
    }

    final num subUnitCount = product.numberSubUnit;

    if (subUnitCount <= 0) {
      return qty.toDouble();
    }

    return qty / subUnitCount;
  }

  // ---------------------------------------------------------------------------
  Future<void> _onLoad(
    LoadNearExpiryEvent event,
    Emitter<NearExpiryState> emit,
  ) async {
    emit(state.copyWith(loading: true));

    await productsRepo.ensureLoaded();

    final allItems = await repo.loadItems(event.projectId);
    allItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final visibleItems = allItems.where((e) => !e.isDeleted).toList();

    final groups = _groupItemsByItemCodeAndExpiry(visibleItems);

    final options = _generateNearExpiryMonths();

    emit(
      state.copyWith(
        loading: false,
        items: allItems,
        filteredItems: visibleItems,
        groupedItems: groups,
        filteredGroupedItems: groups,

        nearExpiryOptions: options,
        selectedNearExpiry: null,
      ),
    );
  }

  Future<void> _onScannedItemSelected(
    ScannedItemSelectedEvent event,
    Emitter<NearExpiryState> emit,
  ) async {
    await productsRepo.ensureLoaded();

    final product = productsRepo.products.firstWhere(
      (p) => p.itemCode == event.item.itemCode,
    );

    emit(
      state.copyWith(
        currentProduct: product,
        units: productsRepo.getUnitsForProduct(product),
        selectedUnit: event.item.unitType,
        selectedNearExpiry: event.item.nearExpiry,
        duplicateAction: NearDuplicateAction.edit,
        error: null,
        success: null,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  Future<void> _onScan(
    ScanBarcodeEvent event,
    Emitter<NearExpiryState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null, scannedBarcode: null));

    await productsRepo.ensureLoaded();

    final product = productsRepo.findByBarcode(event.barcode);

    if (product == null) {
      emit(
        state.copyWith(
          loading: false,
          error: "Item not found",
          scannedBarcode: null, // لا نخزن الباركود
        ),
      );
      return;
    }

    NearExpiryItemModel? existingItem;
    try {
      existingItem = state.items
          .where((e) => !e.isDeleted)
          .cast<NearExpiryItemModel?>()
          .firstWhere(
            (e) => e?.itemCode == product.itemCode,
            orElse: () => null,
          );
    } catch (_) {
      existingItem = null;
    }

    final units = productsRepo.getUnitsForProduct(product);

    final String? defaultUnit = units.any((u) => u.toLowerCase() == 'box')
        ? units.firstWhere((u) => u.toLowerCase() == 'box')
        : null;

    emit(
      state.copyWith(
        loading: false,
        currentProduct: product,
        units: units,
        selectedUnit: defaultUnit,
        productAlreadyExists: existingItem != null,
        error: null,
        productExistsDialogShown: false,
        suggestions: [],

        scannedBarcode: event.barcode,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  Future<void> _onApprove(
    ApproveItemEvent event,
    Emitter<NearExpiryState> emit,
  ) async {
    final product = state.currentProduct;

    if (product == null) {
      emit(state.copyWith(error: "Scan product first"));
      return;
    }

    if (event.qty <= 0) {
      emit(state.copyWith(error: "Quantity required"));
      return;
    }

    if (event.unit.isEmpty) {
      emit(state.copyWith(error: "Unit type required"));
      return;
    }

    final expiry = event.nearExpiry;

    final existing = await repo.findExistingItem(
      projectId: event.projectId,
      itemCode: product.itemCode,
      unitType: event.unit,
      nearExpiry: expiry,
    );

    if (existing != null) {
      await repo.updateItemQty(
        item: existing,
        qty: existing.quantity + event.qty,
      );
    } else {
      await repo.saveNewItem(
        projectId: event.projectId,
        projectName: event.projectName,
        barcode: event.barcode,
        product: product,
        qty: event.qty,
        unitType: event.unit,
        nearExpiry: expiry,
      );
    }

    final items = await repo.loadItems(event.projectId);
    final visible = items.where((e) => !e.isDeleted).toList();
    final groups = _groupItemsByItemCodeAndExpiry(visible);

    emit(
      state.copyWith(
        items: items,
        filteredItems: visible,
        groupedItems: groups,
        filteredGroupedItems: groups,
        setNullProduct: true,
        units: const [],
        setNullSelectedUnit: true,
        clearSelectedNearExpiry: true,
        success: "Item saved successfully",
        error: null,
        suggestions: [],
        productAlreadyExists: false,
        productExistsDialogShown: false,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  Future<void> _onDelete(
    DeleteNearExpiryEvent event,
    Emitter<NearExpiryState> emit,
  ) async {
    for (final id in event.ids) {
      await repo.delete(id);
    }

    final items = await repo.loadItems(event.projectId);
    final visible = items.where((e) => !e.isDeleted).toList();
    final groups = _groupItemsByItemCodeAndExpiry(visible);

    emit(
      state.copyWith(
        items: items,
        filteredItems: visible,
        groupedItems: groups,
        filteredGroupedItems: groups,
        setNullProduct: true,
        setNullSelectedUnit: true,
        clearSelectedNearExpiry: true,
        units: const [],
        setNullSelectedIndex: true,
        selectedIndex: null,
        success: "Item deleted successfully",
        error: null,
        productAlreadyExists: false,
        productExistsDialogShown: false,
        suggestions: [],
      ),
    );
  }

  List<StockItemGroup> _groupItemsByItemCodeAndExpiry(
    List<NearExpiryItemModel> items,
  ) {
    final visibleItems = items.where((e) => !e.isDeleted).toList();

    final Map<String, List<NearExpiryItemModel>> map = {};

    for (final it in visibleItems) {
      final expiryMonth = DateTime(it.nearExpiry.year, it.nearExpiry.month);
      final key = '${it.itemCode}__${expiryMonth.year}-${expiryMonth.month}';

      map.putIfAbsent(key, () => []);
      map[key]!.add(it);
    }

    final groups = <StockItemGroup>[];

    // --------------------------------------------------
    for (final entry in map.entries) {
      final rows = entry.value;

      DateTime latestCreatedAt = rows.first.createdAt;

      final Map<String, int> unitQty = {};
      final Map<String, String> unitId = {};

      for (final r in rows) {
        if (r.createdAt.isAfter(latestCreatedAt)) {
          latestCreatedAt = r.createdAt;
        }

        unitQty[r.unitType] = r.quantity;
        unitId[r.unitType] = r.id;
      }

      final bool isEditingGroup =
          state.editingRowId != null &&
          rows.any((r) => r.id == state.editingRowId);

      final Map<String, int> effectiveUnitQty = isEditingGroup
          ? {...unitQty, ...state.editingUnitQty}
          : unitQty;

      final DateTime effectiveNearExpiry =
          isEditingGroup && state.editingNearExpiry != null
          ? DateTime(
              state.editingNearExpiry!.year,
              state.editingNearExpiry!.month,
              1,
            )
          : rows.first.nearExpiry;

      double totalSubQty = 0;

      for (final entry in effectiveUnitQty.entries) {
        final unit = entry.key;
        final qty = entry.value;

        if (qty <= 0) continue;

        if (unit.toLowerCase() == 'box') {
          totalSubQty += qty.toDouble();
        } else {
          final product = productsRepo.products.firstWhere(
            (p) => p.itemCode == rows.first.itemCode,
          );

          final subUnitCount = product.numberSubUnit;
          if (subUnitCount > 0) {
            totalSubQty += qty / subUnitCount;
          } else {
            totalSubQty += qty.toDouble();
          }
        }
      }

      // --------------------------------------------------
      groups.add(
        StockItemGroup(
          itemCode: rows.first.itemCode,
          itemName: rows.first.itemName,
          barcode: rows.first.barcode,

          nearExpiry: effectiveNearExpiry,

          totalSubQty: totalSubQty,
          totalDisplayQty: effectiveUnitQty.values.fold<int>(
            0,
            (s, e) => s + e,
          ),

          unitQty: Map<String, int>.from(effectiveUnitQty),
          unitId: unitId,
          latestCreatedAt: latestCreatedAt,
        ),
      );
    }

    // --------------------------------------------------
    groups.sort((a, b) => b.latestCreatedAt.compareTo(a.latestCreatedAt));
    return groups;
  }

  // ---------------------------------------------------------------------------
  Future<void> _onSync(
    SyncNearExpiryEvent event,
    Emitter<NearExpiryState> emit,
  ) async {
    await repo.syncUp(event.projectId);
  }

  Future<void> _onResetForm(
    ResetFormEvent event,
    Emitter<NearExpiryState> emit,
  ) async {
    emit(
      state.copyWith(
        setNullProduct: true,
        currentProduct: null,
        setNullSelectedUnit: true,
        selectedUnit: null,
        clearSelectedNearExpiry: true,
        units: const [],
        success: null,
        clearEditingRowId: true,
        setNullSelectedIndex: true,
        selectedIndex: null,
        productExistsDialogShown: false,
        productAlreadyExists: false,
        error: null,
        suggestions: const [],
      ),
    );
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<NearExpiryState> emit,
  ) async {
    final text = event.query.trim();
    if (text.length < 2) {
      emit(state.copyWith(suggestions: []));
      return;
    }

    await productsRepo.ensureLoaded();

    final lower = text.toLowerCase();
    final matches = productsRepo.products
        .where(
          (p) =>
              p.itemName.toLowerCase().contains(lower) ||
              p.itemCode.toLowerCase().contains(lower) ||
              p.barcodes.any((b) => b.contains(text)),
        )
        .take(10)
        .toList();

    emit(state.copyWith(suggestions: matches));
  }

  Future<void> _onProductChosenFromSearch(
    ProductChosenFromSearch event,
    Emitter<NearExpiryState> emit,
  ) async {
    final product = event.product;
    final units = productsRepo.getUnitsForProduct(product);

    emit(
      state.copyWith(
        currentProduct: product,
        units: units,
        selectedUnit: units.contains('BOX') ? 'BOX' : units.first,
        productAlreadyExists: false,
        suggestions: [],
        productExistsDialogShown: false,
        error: null,
        success: null,
      ),
    );
  }

  void _onSearchScannedItems(
    SearchScannedItemsEvent event,
    Emitter<NearExpiryState> emit,
  ) {
    final q = event.query.toLowerCase().trim();
    if (q.isEmpty) {
      emit(state.copyWith(filteredGroupedItems: state.groupedItems));
      return;
    }

    emit(
      state.copyWith(
        filteredGroupedItems: state.groupedItems
            .where(
              (g) =>
                  g.itemName.toLowerCase().contains(q) ||
                  g.itemCode.toLowerCase().contains(q),
            )
            .toList(),
      ),
    );
  }

  Future<void> _onUpload(
    UploadNearExpiryEvent event,
    Emitter<NearExpiryState> emit,
  ) async {
    emit(
      state.copyWith(
        isUploading: true,
        uploadMessage: "Uploading data...",
        error: null,
        success: null,
      ),
    );

    try {
      if (state.items.isEmpty) {
        emit(
          state.copyWith(
            isUploading: false,
            error: "No items to upload",
            uploadMessage: null,
          ),
        );
        return;
      }

      await productsRepo.ensureLoaded();

      final Map<String, double> totalBoxByKey = {};
      final Map<String, NearExpiryItemModel> sampleRow = {};

      for (final item in state.items.where((e) => !e.isDeleted)) {
        final expiryMonth = DateTime(
          item.nearExpiry.year,
          item.nearExpiry.month,
          1,
        );

        final key =
            '${item.itemCode}__${expiryMonth.year}-${expiryMonth.month}';

        final product = productsRepo.products.firstWhere(
          (p) => p.itemCode == item.itemCode,
        );

        final double boxQty = _toBoxQtyLocal(
          qty: item.quantity,
          unitType: item.unitType,
          product: product,
        );

        totalBoxByKey[key] = (totalBoxByKey[key] ?? 0) + boxQty;
        sampleRow.putIfAbsent(key, () => item);
      }

      final List<Map<String, dynamic>> payload = [];

      totalBoxByKey.forEach((key, totalBoxQty) {
        final base = sampleRow[key]!;

        payload.add({
          'project_id': event.projectId,
          'project_name': base.projectName,
          'item_code': base.itemCode,
          'item_name': base.itemName,
          'barcode': base.barcode,
          'branch_name': session.branch,
          'near_expiry': DateTime(
            base.nearExpiry.year,
            base.nearExpiry.month,
            1,
          ).toIso8601String(),

          'qty': totalBoxQty,

          'unit_type': 'BOX',
        });
      });

      await repo.uploadNearExpiryPayload(payload);

      final syncedItems = state.items
          .map((item) => item.copyWith(isSynced: true))
          .toList();

      emit(
        state.copyWith(
          isUploading: false,
          uploadMessage: null,
          success: "Uploaded successfully",
          items: syncedItems,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isUploading: false,
          uploadMessage: null,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onExportExcel(
    ExportExcelEvent event,
    Emitter<NearExpiryState> emit,
  ) async {
    emit(
      state.copyWith(
        isProcessing: true,
        processingMessage: "Saving file to device...",
        error: null,
        success: null,
      ),
    );

    try {
      await repo.exportExcel(
        projectId: event.projectId,
        projectName: event.projectName,
      );

      emit(
        state.copyWith(
          isProcessing: false,
          clearProcessingMessage: true,
          success: "File saved successfully",
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isProcessing: false,
          clearProcessingMessage: true,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSendByEmail(
    SendByEmailEvent event,
    Emitter<NearExpiryState> emit,
  ) async {
    emit(
      state.copyWith(
        isProcessing: true,
        processingMessage: "Sending email...",
        error: null,
        success: null,
      ),
    );

    try {
      final branchRepo = getIt<BranchRepository>();
      final exportService = getIt<NearExpiryExportService>();

      final email = await branchRepo.getEmailByBranchName(event.branchName);

      if (email == null || email.isEmpty) {
        throw Exception("Branch email not found");
      }

      await exportService.sendExcelByEmail(
        projectId: event.projectId,
        projectName: event.projectName,
        toEmail: email,
      );

      emit(
        state.copyWith(
          isProcessing: false,
          clearProcessingMessage: true,
          success: "Email sent to $email",
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isProcessing: false,
          clearProcessingMessage: true,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateMultiUnit(
    UpdateMultiUnitEvent event,
    Emitter<NearExpiryState> emit,
  ) async {
    emit(
      state.copyWith(isProcessing: true, processingMessage: "Updating item..."),
    );

    final oldExpiry = DateTime(
      event.group.nearExpiry!.year,
      event.group.nearExpiry!.month,
      1,
    );

    final newExpiry = DateTime(
      event.newNearExpiry.year,
      event.newNearExpiry.month,
      1,
    );

    final bool expiryChanged = oldExpiry != newExpiry;

    if (expiryChanged) {
      for (final id in event.group.unitId.values) {
        await repo.delete(id);
      }
    }

    for (final entry in event.newUnitQty.entries) {
      final unit = entry.key;
      final qty = entry.value;

      final existingId = event.group.unitId[unit];

      if (qty <= 0) {
        if (existingId != null) {
          await repo.delete(existingId);
        }
        continue;
      }

      if (!expiryChanged && existingId != null) {
        final item = state.items.firstWhere((e) => e.id == existingId);

        await repo.updateItemQty(item: item, qty: qty);
      } else {
        final product = productsRepo.products.firstWhere(
          (p) => p.itemCode == event.group.itemCode,
        );

        await repo.saveNewItem(
          projectId: event.projectId,
          projectName: event.projectName,
          barcode: event.group.barcode,
          product: product,
          qty: qty,
          unitType: unit,
          nearExpiry: newExpiry,
        );
      }
    }

    final items = await repo.loadItems(event.projectId);
    final visibleItems = items.where((e) => !e.isDeleted).toList();
    final groups = _groupItemsByItemCodeAndExpiry(visibleItems);

    emit(
      state.copyWith(
        isProcessing: false,
        processingMessage: null,
        items: items,
        filteredItems: visibleItems,
        groupedItems: groups,
        filteredGroupedItems: groups,
        success: "Item updated successfully",
        error: null,

        editingUnitQty: const {},
        clearEditingNearExpiry: true,
        clearEditingRowId: true,
      ),
    );
  }
}
