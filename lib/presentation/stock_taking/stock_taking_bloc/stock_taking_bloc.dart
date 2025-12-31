import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../data/model/stock_item_group.dart';
import '../../../data/model/stock_taking_model.dart';
import '../../../data/repositories/branch_repository.dart';
import '../../../data/repositories/products_repository.dart';
import '../../../data/repositories/stock_taking_repository.dart';
import '../../../data/services/connectivity_service.dart';
import '../../../data/services/stock_export_service.dart';
import 'stock_taking_event.dart';
import 'stock_taking_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  final StockRepository repo;
  final ProductsRepository productsRepo;

  StockBloc(this.repo, this.productsRepo) : super(const StockState()) {
    on<LoadStockEvent>(_onLoad);
    on<ScanBarcodeEvent>(_onScan);
    on<DeleteStockEvent>(_onDelete);
    on<SyncStockEvent>(_onSync);
    on<SearchScannedItemsEvent>(_onSearchScannedItems);
    on<ChangeSelectedIndexEvent>((event, emit) {
      emit(state.copyWith(selectedIndex: event.index));
    });
    on<ClearProductAlreadyExistsFlagEvent>((event, emit) {
      emit(state.copyWith(productAlreadyExists: false));
    });
    on<SendStockByEmailEvent>(_onSendStockByEmail);
    on<UpdateMultiUnitEvent>(_onUpdateMultiUnit);

    on<ExportExcelEvent>(_onExportExcel);

    on<UploadStockEvent>(_onUploadStock);

    on<ChangeUnitEvent>((event, emit) {
      emit(state.copyWith(selectedUnit: event.unit));
    });
    on<SetDuplicateActionEvent>((event, emit) {
      String? newUnit = state.selectedUnit;

      if (event.forceDefaultBox && state.units.isNotEmpty) {
        final boxUnit = state.units.firstWhere(
          (u) => u.toLowerCase() == 'Box',
          orElse: () => state.units.first,
        );
        newUnit = boxUnit;
      }

      emit(
        state.copyWith(
          duplicateAction: event.action,
          selectedUnit: newUnit,
          setNullSelectedUnit: newUnit == null,
        ),
      );
    });

    on<EditSingleUnitFromListEvent>((event, emit) async {
      await productsRepo.ensureLoaded();

      final product = productsRepo.products.firstWhere(
        (p) => p.itemCode == event.group.itemCode,
        orElse: () => throw Exception("Product not found"),
      );

      emit(
        state.copyWith(
          currentProduct: product,
          units: productsRepo.getUnitsForProduct(product),
          selectedUnit: event.unit,
          setNullSelectedUnit: false,
          editingRowId: event.rowId,
          duplicateAction: DuplicateAction.edit,
          success: null,
          error: null,
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
    on<ProductsRepoUpdatedEvent>((event, emit) async {
      final current = state.currentProduct;
      if (current == null) return;

      final updatedProduct = productsRepo.products.firstWhere(
        (p) => p.itemCode == current.itemCode,
        orElse: () => current,
      );

      final units = productsRepo.getUnitsForProduct(updatedProduct);

      emit(
        state.copyWith(
          currentProduct: updatedProduct,
          units: units,
          selectedUnit: units.contains(state.selectedUnit)
              ? state.selectedUnit
              : (units.any((u) => u.toLowerCase() == 'box')
                    ? units.firstWhere((u) => u.toLowerCase() == 'box')
                    : null),
          setNullSelectedUnit: units.isEmpty,
        ),
      );
    });
  }
  bool isMultiUnit(List<String> units) {
    return units.length > 1;
  }

  Future<void> _onLoad(LoadStockEvent event, Emitter<StockState> emit) async {
    emit(state.copyWith(loading: true));

    await productsRepo.ensureLoaded();

    final allItems = await repo.loadItems(event.projectId);
    allItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final visibleItems = allItems.where((e) => !e.isDeleted).toList();

    final groups = _groupItemsByItemCode(visibleItems);

    emit(
      state.copyWith(
        loading: false,

        items: allItems,

        filteredItems: visibleItems,
        groupedItems: groups,
        filteredGroupedItems: groups,
      ),
    );
  }

  Future<void> _onScan(ScanBarcodeEvent event, Emitter<StockState> emit) async {
    emit(state.copyWith(loading: true, error: null, scannedBarcode: null));

    await productsRepo.ensureLoaded();

    final product = productsRepo.findByBarcode(event.barcode);

    if (product == null) {
      emit(
        state.copyWith(
          loading: false,
          error: "Item not found",
          scannedBarcode: null,
        ),
      );
      return;
    }

    // 🔁 Check if item already exists
    StockItemModel? existingItem;
    try {
      existingItem = state.items
          .where((e) => !e.isDeleted)
          .cast<StockItemModel?>()
          .firstWhere(
            (e) => e?.itemCode == product.itemCode,
            orElse: () => null,
          );
    } catch (_) {
      existingItem = null;
    }

    // 📦 Load units
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
        setNullSelectedUnit: defaultUnit == null,

        productAlreadyExists: existingItem != null,
        error: null,
        productExistsDialogShown: false,
        suggestions: [],

        scannedBarcode: event.barcode,
      ),
    );
  }

  Future<void> _onApprove(
    ApproveItemEvent event,
    Emitter<StockState> emit,
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

    final double newSubQty = _calculateSubQty(
      qty: event.qty,
      unit: event.unit,
      numberSubUnit: product.numberSubUnit,
    );

    final String? editingRowId = state.editingRowId;

    if (state.duplicateAction == DuplicateAction.edit && editingRowId != null) {
      final row = state.items.firstWhere((e) => e.id == editingRowId);

      if (row.unit.toLowerCase() != event.unit.toLowerCase()) {
        final target = await repo.findExistingItemByUnit(
          event.projectId,
          product.itemCode,
          event.unit,
        );

        if (target != null) {
          await repo.updateItemFull(
            item: target,
            unit: target.unit,
            subQty: target.subQuantity + newSubQty,
          );

          await repo.delete(row.id);
        } else {
          await repo.updateItemFull(
            item: row,
            unit: event.unit,
            subQty: newSubQty,
          );
        }
      } else {
        await repo.updateItemFull(item: row, unit: row.unit, subQty: newSubQty);
      }

      final items = await repo.loadItems(event.projectId);
      final groups = _groupItemsByItemCode(items);

      emit(
        state.copyWith(
          items: items,
          filteredItems: items,
          groupedItems: groups,
          filteredGroupedItems: groups,

          clearEditingRowId: true,
          setNullProduct: true,
          units: [],
          selectedUnit: null,
          setNullSelectedUnit: true,

          success: "Item updated",
          error: null,
          productAlreadyExists: false,
          productExistsDialogShown: false,
        ),
      );
      return;
    }

    final existing = await repo.findExistingItemByUnit(
      event.projectId,
      product.itemCode,
      event.unit,
    );

    if (existing != null) {
      final double finalSubQty = existing.subQuantity + newSubQty;

      await repo.updateItemFull(
        item: existing,
        unit: existing.unit,
        subQty: finalSubQty,
      );
    } else {
      await repo.saveNewItem(
        projectId: event.projectId,
        projectName: event.projectName,
        barcode: event.barcode,
        product: product,
        subQty: newSubQty,
        unit: event.unit,
      );
    }

    final items = await repo.loadItems(event.projectId);
    final groups = _groupItemsByItemCode(items);

    emit(
      state.copyWith(
        items: items,
        filteredItems: items,
        groupedItems: groups,
        filteredGroupedItems: groups,

        currentProduct: null,
        setNullProduct: true,

        units: [],
        selectedUnit: null,
        setNullSelectedUnit: true,

        success: "Item saved successfully",
        error: null,
        suggestions: [],
        productAlreadyExists: false,
        productExistsDialogShown: false,
      ),
    );
  }

  Future<void> _onDelete(
    DeleteStockEvent event,
    Emitter<StockState> emit,
  ) async {
    for (final id in event.ids) {
      await repo.delete(id); // isDeleted=true + isSynced=false
    }
    await repo.debugPrintAll(event.projectId);

    final items = await repo.loadItems(event.projectId);

    final visibleItems = items.where((e) => !e.isDeleted).toList();

    final groups = _groupItemsByItemCode(visibleItems);

    emit(
      state.copyWith(
        items: items,
        filteredItems: visibleItems,
        groupedItems: groups,
        filteredGroupedItems: groups,

        currentProduct: null,
        setNullProduct: true,

        selectedUnit: null,
        units: [],
        setNullSelectedUnit: true,

        selectedIndex: null,
        setNullSelectedIndex: true,

        success: "Item deleted successfully",
        error: null,
        productAlreadyExists: false,
        productExistsDialogShown: false,
        suggestions: [],
      ),
    );
  }

  Future<void> _onSync(SyncStockEvent event, Emitter<StockState> emit) async {
    await repo.syncUp(event.projectId);
  }

  Future<void> _onResetForm(
    ResetFormEvent event,
    Emitter<StockState> emit,
  ) async {
    emit(
      state.copyWith(
        setNullProduct: true,
        currentProduct: null,
        selectedUnit: null,
        units: [],
        setNullSelectedUnit: true,
        success: null,
        clearEditingRowId: true,
        setNullSelectedIndex: true,
        productExistsDialogShown: false,
        productAlreadyExists: false,

        error: null,
        selectedIndex: null,
        suggestions: [],
      ),
    );
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<StockState> emit,
  ) async {
    final text = event.query.trim();

    if (text.length < 2) {
      emit(state.copyWith(suggestions: []));
      return;
    }

    await productsRepo.ensureLoaded();

    final lower = text.toLowerCase();

    final matches = productsRepo.products
        .where((p) {
          final name = p.itemName.toLowerCase();
          final code = p.itemCode.toLowerCase();
          final barcodes = p.barcodes;
          return name.contains(lower) ||
              code.contains(lower) ||
              barcodes.any((b) => b.contains(text));
        })
        .take(10)
        .toList();

    emit(state.copyWith(suggestions: matches));
  }

  Future<void> _onProductChosenFromSearch(
    ProductChosenFromSearch event,
    Emitter<StockState> emit,
  ) async {
    final product = event.product;

    StockItemModel? existingItem;

    try {
      existingItem = state.items
          .where((e) => !e.isDeleted)
          .cast<StockItemModel?>()
          .firstWhere(
            (e) => e?.itemCode == product.itemCode,
            orElse: () => null,
          );
    } catch (_) {
      existingItem = null;
    }

    final units = productsRepo.getUnitsForProduct(product);

    String? selectedUnit;

    if (existingItem != null) {
      selectedUnit = existingItem.unit;
    } else {
      selectedUnit = units.any((u) => u.toLowerCase() == 'box')
          ? units.firstWhere((u) => u.toLowerCase() == 'box')
          : null;
    }

    emit(
      state.copyWith(
        currentProduct: product,
        units: units,

        selectedUnit: selectedUnit,
        setNullSelectedUnit: selectedUnit == null,

        productAlreadyExists: existingItem != null,
        suggestions: [],
        productExistsDialogShown: false,

        error: null,
        success: null,
      ),
    );
  }

  void _onSearchScannedItems(
    SearchScannedItemsEvent event,
    Emitter<StockState> emit,
  ) {
    final q = event.query.toLowerCase().trim();

    if (q.isEmpty) {
      emit(state.copyWith(filteredGroupedItems: state.groupedItems));
      return;
    }

    final filtered = state.groupedItems.where((g) {
      return g.itemName.toLowerCase().contains(q) ||
          g.itemCode.toLowerCase().contains(q);
    }).toList();

    emit(state.copyWith(filteredGroupedItems: filtered));
  }

  void _onScannedItemSelected(
    ScannedItemSelectedEvent event,
    Emitter<StockState> emit,
  ) {
    final item = event.item;

    final product = productsRepo.products.firstWhere(
      (p) => p.itemCode == item.itemCode,
      orElse: () {
        throw Exception("Product not found in ProductsRepository");
      },
    );

    emit(
      state.copyWith(
        currentProduct: product,
        units: productsRepo.getUnitsForProduct(product),
        selectedUnit: item.unit,
        setNullSelectedUnit: false,
        error: null,
        success: null,
      ),
    );
  }

  Future<void> _onUploadStock(
    UploadStockEvent event,
    Emitter<StockState> emit,
  ) async {
    emit(
      state.copyWith(
        isUploading: true,
        uploadMessage: "Uploading Data...",
        error: null,
        success: null,
      ),
    );
    final hasNet = await getIt<ConnectivityService>().hasInternet();

    if (!hasNet) {
      emit(
        state.copyWith(
          isUploading: false,
          error: "No internet connection. Data saved locally.",
        ),
      );
      return;
    }

    try {
      final allItems = await repo.loadItems(event.projectId);

      if (allItems.isEmpty) {
        emit(
          state.copyWith(
            isUploading: false,
            error: "No Items to Upload",
            uploadMessage: null,
          ),
        );
        return;
      }

      await repo.uploadStockItems(
        projectId: event.projectId,
        items: allItems, // ✅
      );

      final refreshed = await repo.loadItems(event.projectId);

      emit(
        state.copyWith(
          isUploading: false,
          items: refreshed,
          filteredItems: refreshed.where((e) => !e.isDeleted).toList(),
          groupedItems: _groupItemsByItemCode(
            refreshed.where((e) => !e.isDeleted).toList(),
          ),
          filteredGroupedItems: _groupItemsByItemCode(
            refreshed.where((e) => !e.isDeleted).toList(),
          ),
          success: "Data Uploaded Successfully",
          uploadMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isUploading: false,
          error: e.toString(),
          uploadMessage: null,
        ),
      );
    }
  }

  Future<void> _onExportExcel(
    ExportExcelEvent event,
    Emitter<StockState> emit,
  ) async {
    if (state.hasUnsyncedItems) {
      emit(state.copyWith(error: "Please upload data before exporting"));
      return;
    }

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

  Future<void> _onSendStockByEmail(
    SendStockByEmailEvent event,
    Emitter<StockState> emit,
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
      final exportService = getIt<StockExportService>();

      final email = await branchRepo.getEmailByBranchName(event.branchName);

      if (email == null || email.isEmpty) {
        throw Exception("Branch email not found");
      }

      await exportService.sendExcelByEmail(
        projectId: event.projectId,
        toEmail: email,
        projectName: event.projectName,
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

  double _calculateSubQty({
    required int qty,
    required String unit,
    required num numberSubUnit,
  }) {
    if (unit.toLowerCase() == 'box') {
      return qty.toDouble();
    }

    if (numberSubUnit <= 0) return qty.toDouble();

    return qty / numberSubUnit;
  }

  List<StockItemGroup> _groupItemsByItemCode(List<StockItemModel> items) {
    final visibleItems = items.where((e) => !e.isDeleted).toList();

    final Map<String, List<StockItemModel>> map = {};

    for (final it in visibleItems) {
      map.putIfAbsent(it.itemCode, () => []);
      map[it.itemCode]!.add(it);
    }

    final groups = <StockItemGroup>[];

    for (final entry in map.entries) {
      final rows = entry.value;

      final itemCode = rows.first.itemCode;
      final itemName = rows.first.itemName;
      final barcode = rows.first.barcode;

      final product = productsRepo.products.firstWhere(
        (p) => p.itemCode == itemCode,
        orElse: () =>
            throw Exception("Product not found for grouping: $itemCode"),
      );

      int qtyFromSub(String unit, double subQty) {
        if (unit.toLowerCase() == 'box') {
          return subQty.round();
        }

        if (product.numberSubUnit <= 0) {
          return subQty.round();
        }

        return (subQty * product.numberSubUnit).round();
      }

      double totalSubQty = 0;
      DateTime latestCreatedAt = rows.first.createdAt;

      final unitQty = <String, int>{};
      final unitId = <String, String>{};

      for (final r in rows) {
        final subQty = r.subQuantity.toDouble();
        totalSubQty += subQty;

        if (r.createdAt.isAfter(latestCreatedAt)) {
          latestCreatedAt = r.createdAt;
        }

        final qty = qtyFromSub(r.unit, subQty);
        unitQty[r.unit] = qty;
        unitId[r.unit] = r.id;
      }

      groups.add(
        StockItemGroup(
          itemCode: itemCode,
          itemName: itemName,
          barcode: barcode,
          totalSubQty: totalSubQty,
          unitQty: unitQty,
          totalDisplayQty: totalSubQty.round(),
          unitId: unitId,
          latestCreatedAt: latestCreatedAt,
        ),
      );
    }

    groups.sort((a, b) => b.latestCreatedAt.compareTo(a.latestCreatedAt));

    return groups;
  }

  Future<void> _onUpdateMultiUnit(
    UpdateMultiUnitEvent event,
    Emitter<StockState> emit,
  ) async {
    await productsRepo.ensureLoaded();

    final product = productsRepo.products.firstWhere(
      (p) => p.itemCode == event.group.itemCode,
      orElse: () => throw Exception("Product not found"),
    );

    double subFromQty(String unit, int qty) {
      if (unit.toLowerCase() == 'box') return qty.toDouble();
      if (product.numberSubUnit <= 0) return qty.toDouble();
      return qty / product.numberSubUnit;
    }

    for (final entry in event.newUnitQty.entries) {
      final unit = entry.key;
      final qty = entry.value;

      final existingRowId = event.group.unitId[unit];

      if (qty <= 0) {
        if (existingRowId != null) {
          await repo.delete(existingRowId);
        }
        continue;
      }

      final subQty = subFromQty(unit, qty);

      if (existingRowId != null) {
        final row = state.items.firstWhere((e) => e.id == existingRowId);
        await repo.updateItemFull(item: row, unit: unit, subQty: subQty);
      } else {
        await repo.saveNewItem(
          projectId: event.projectId,
          projectName: event.projectName,
          barcode: event.group.barcode,
          product: product,
          unit: unit,
          subQty: subQty,
        );
      }
    }
    if (event.newUnitQty.isEmpty) {
      for (final rowId in event.group.unitId.values) {
        await repo.delete(rowId);
      }

      final items = await repo.loadItems(event.projectId);
      final groups = _groupItemsByItemCode(items);

      emit(
        state.copyWith(
          items: items,
          filteredItems: items,
          groupedItems: groups,
          filteredGroupedItems: groups,
          success: "Item deleted",
          error: null,
        ),
      );
      return;
    }

    final items = await repo.loadItems(event.projectId);
    final groups = _groupItemsByItemCode(items);

    emit(
      state.copyWith(
        items: items,
        filteredItems: items,
        groupedItems: groups,
        filteredGroupedItems: groups,
        success: "Updated",
        error: null,
      ),
    );
  }
}
