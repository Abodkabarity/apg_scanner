import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../data/model/near_expiry_item_model.dart';
import '../../../data/model/stock_item_group.dart';
import '../../../data/repositories/branch_repository.dart';
import '../../../data/repositories/near_expiry_repository.dart';
import '../../../data/repositories/products_repository.dart';
import '../../../data/services/connectivity_service.dart';
import '../../../data/services/stock_export_service.dart';
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

    on<SetDuplicateActionEvent>((event, emit) {
      emit(state.copyWith(duplicateAction: event.action));
    });

    on<ChangeNearExpiryDateEvent>((event, emit) {
      emit(state.copyWith(selectedNearExpiry: event.nearExpiry));
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

  // ---------------------------------------------------------------------------
  Future<void> _onScan(
    ScanBarcodeEvent event,
    Emitter<NearExpiryState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));

    await productsRepo.ensureLoaded();

    final product = productsRepo.findByBarcode(event.barcode);

    if (product == null) {
      emit(state.copyWith(loading: false, error: "Item not found"));
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

    // 🔥 ONLY CHANGE: expiry required
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

  // ---------------------------------------------------------------------------
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
    Emitter<NearExpiryState> emit,
  ) async {
    final product = event.product;

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

    String? selectedUnit;
    if (existingItem != null) {
      selectedUnit = existingItem.unitType;
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
    Emitter<NearExpiryState> emit,
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
    Emitter<NearExpiryState> emit,
  ) {
    final item = event.item;

    final product = productsRepo.products.firstWhere(
      (p) => p.itemCode == item.itemCode,
      orElse: () => throw Exception("Product not found in ProductsRepository"),
    );

    emit(
      state.copyWith(
        currentProduct: product,
        units: productsRepo.getUnitsForProduct(product),
        selectedUnit: item.unitType,
        selectedNearExpiry: item.nearExpiry,
        error: null,
        success: null,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  Future<void> _onUpload(
    UploadNearExpiryEvent event,
    Emitter<NearExpiryState> emit,
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

      await repo.uploadNearExpiryItems(
        projectId: event.projectId,
        items: allItems,
      );

      final refreshed = await repo.loadItems(event.projectId);
      final visible = refreshed.where((e) => !e.isDeleted).toList();
      final groups = _groupItemsByItemCodeAndExpiry(visible);

      emit(
        state.copyWith(
          isUploading: false,
          items: refreshed,
          filteredItems: visible,
          groupedItems: groups,
          filteredGroupedItems: groups,
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
    Emitter<NearExpiryState> emit,
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

  Future<void> _onUpdateMultiUnit(
    UpdateMultiUnitEvent event,
    Emitter<NearExpiryState> emit,
  ) async {}

  // ---------------------------------------------------------------------------
  // 🔥 ONLY CHANGE: grouping by itemCode + nearExpiry (so different dates become different groups)
  List<StockItemGroup> _groupItemsByItemCodeAndExpiry(
    List<NearExpiryItemModel> items,
  ) {
    final visibleItems = items.where((e) => !e.isDeleted).toList();

    final Map<String, List<NearExpiryItemModel>> map = {};

    for (final it in visibleItems) {
      final key =
          '${it.itemCode}__${it.nearExpiry.year}-${it.nearExpiry.month}-${it.nearExpiry.day}';
      map.putIfAbsent(key, () => []);
      map[key]!.add(it);
    }

    final groups = <StockItemGroup>[];

    for (final entry in map.entries) {
      final rows = entry.value;

      final itemCode = rows.first.itemCode;
      final itemName = rows.first.itemName;
      final barcode = rows.first.barcode;

      DateTime latestCreatedAt = rows.first.createdAt;

      final unitQty = <String, int>{};
      final unitId = <String, String>{};

      for (final r in rows) {
        if (r.createdAt.isAfter(latestCreatedAt)) {
          latestCreatedAt = r.createdAt;
        }

        unitQty[r.unitType] = r.quantity;
        unitId[r.unitType] = r.id;
      }

      groups.add(
        StockItemGroup(
          itemCode: itemCode,
          itemName: itemName,
          barcode: barcode,
          totalSubQty: rows.fold<double>(
            0,
            (s, e) => s + e.quantity.toDouble(),
          ),
          unitQty: unitQty,
          totalDisplayQty: rows.fold<int>(0, (s, e) => s + e.quantity),
          unitId: unitId,
          latestCreatedAt: latestCreatedAt,
        ),
      );
    }

    groups.sort((a, b) => b.latestCreatedAt.compareTo(a.latestCreatedAt));
    return groups;
  }
}
