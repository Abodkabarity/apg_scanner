import 'package:apg_scanner/data/services/stock_batch_export_service.dart'
    show StockBatchExportService;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/session/user_session.dart';
import '../../../../data/repositories/products_with_batch_repository.dart';
import '../../../data/model/stock_batch_group.dart';
import '../../../data/model/stock_batch_item_model.dart';
import '../../../data/repositories/stock_batch_repository.dart';
import 'stock_batch_event.dart';
import 'stock_batch_state.dart';

class StockBatchBloc extends Bloc<StockBatchEvent, StockBatchState> {
  final StockBatchRepository repo;
  final ProductsWithBatchRepository productsRepo;

  StockBatchBloc(this.repo, this.productsRepo)
    : super(const StockBatchState()) {
    on<LoadStockBatchEvent>(_onLoad);
    on<ScanBatchBarcodeEvent>(_onScan);
    on<ChangeSelectedExpiryEvent>(_onChangeExpiry);
    on<ChangeSelectedBatchEvent>(_onChangeBatch);
    on<ApproveBatchItemEvent>(_onApprove);
    on<DeleteBatchItemEvent>(_onDelete);
    on<SearchBatchQueryChanged>(_onSearch);
    on<ResetBatchFormEvent>(_onReset);
    on<ProductChosenFromSearchEvent>(_onProductChosenFromSearch);
    on<ChangeUnitEvent>(_onChangeUnit);
    on<ExportStockBatchExcelEvent>(_onExportExcel);
    on<SendStockBatchByEmailEvent>(_onSendByEmail);
    on<UploadStockBatchEvent>(_onUpload);
  }
  final exportService = getIt<StockBatchExportService>();

  final session = getIt<UserSession>();

  // ---------------------------------------------------------------------------
  Future<void> _onLoad(
    LoadStockBatchEvent event,
    Emitter<StockBatchState> emit,
  ) async {
    emit(state.copyWith(loading: true));

    await productsRepo.ensureLoaded();

    final items = await repo.loadItems(event.projectId);
    final visible = items.where((e) => !e.isDeleted).toList();

    final groups = _groupByItemAndBatch(visible);

    emit(
      state.copyWith(
        loading: false,
        items: items,
        groupedItems: groups,
        filteredGroupedItems: groups,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  Future<void> _onScan(
    ScanBatchBarcodeEvent event,
    Emitter<StockBatchState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));

    await productsRepo.ensureLoaded();
    print('SCANNED BARCODE = [${event.barcode}]');

    final product = productsRepo.findByBarcode(event.barcode);

    if (product == null) {
      emit(state.copyWith(loading: false, error: "Item not found"));
      return;
    }

    final units = productsRepo.getUnitsForProduct(product);

    // ---------------- NON-BATCH PRODUCT ----------------
    if (!product.isBatch) {
      emit(
        state.copyWith(
          loading: false,

          currentProduct: product,

          expiryOptions: const [],
          selectedExpiry: null,
          batchOptions: const [],
          selectedBatch: null,

          units: units,
          selectedUnit: units.isNotEmpty ? units.first : null,

          scannedBarcode: event.barcode,
          clearError: true,
        ),
      );
      return;
    }

    // ---------------- BATCH PRODUCT ----------------
    final expiries = productsRepo.getNearExpiriesForProduct(product.itemCode);

    DateTime? selectedExpiry;
    List<String> batchOptions = const [];
    String? selectedBatch;

    if (expiries.length == 1) {
      selectedExpiry = expiries.first;

      batchOptions = productsRepo.getBatchesForProductAndExpiry(
        product.itemCode,
        selectedExpiry,
      );

      if (batchOptions.length == 1) {
        selectedBatch = batchOptions.first;
      }
    }

    emit(
      state.copyWith(
        loading: false,

        currentProduct: product,

        expiryOptions: expiries,
        selectedExpiry: selectedExpiry,

        batchOptions: batchOptions,
        selectedBatch: selectedBatch,

        units: units,
        selectedUnit: units.isNotEmpty ? units.first : null,

        scannedBarcode: event.barcode,
        clearError: true,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  void _onChangeExpiry(
    ChangeSelectedExpiryEvent event,
    Emitter<StockBatchState> emit,
  ) {
    final batches = productsRepo.getBatchesForProductAndExpiry(
      event.itemCode,
      event.expiry,
    );

    emit(
      state.copyWith(
        selectedExpiry: event.expiry,
        batchOptions: batches,

        selectedBatch: batches.length == 1 ? batches.first : null,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  void _onChangeBatch(
    ChangeSelectedBatchEvent event,
    Emitter<StockBatchState> emit,
  ) {
    emit(state.copyWith(selectedBatch: event.batch));
  }

  // ---------------------------------------------------------------------------
  Future<void> _onApprove(
    ApproveBatchItemEvent event,
    Emitter<StockBatchState> emit,
  ) async {
    final product = state.currentProduct;

    // ---------------- BASIC VALIDATION ----------------
    if (product == null) {
      emit(state.copyWith(error: "Select product first"));
      return;
    }

    if (event.qty <= 0) {
      emit(state.copyWith(error: "Quantity required"));
      return;
    }

    if (state.selectedUnit == null || state.selectedUnit!.isEmpty) {
      emit(state.copyWith(error: "Unit required"));
      return;
    }

    // ---------------- BATCH VALIDATION ----------------
    if (product.isBatch) {
      if (state.selectedExpiry == null) {
        emit(state.copyWith(error: "Near expiry required"));
        return;
      }

      if (state.selectedBatch == null || state.selectedBatch!.isEmpty) {
        emit(state.copyWith(error: "Batch required"));
        return;
      }
    }

    // ---------------- SAVE / UPDATE ----------------
    final existing = await repo.findExistingItem(
      projectId: event.projectId,
      itemCode: product.itemCode,
      unit: state.selectedUnit!,
      batch: product.isBatch ? state.selectedBatch : null,
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
        branchName: session.branch ?? "",
        product: product,
        barcode: event.barcode,
        unit: state.selectedUnit!,
        qty: event.qty,
        expiry: product.isBatch ? state.selectedExpiry : null,
        batch: product.isBatch ? state.selectedBatch : null,
      );
    }

    // ---------------- REFRESH LIST ----------------
    final items = await repo.loadItems(event.projectId);
    final visible = items.where((e) => !e.isDeleted).toList();
    final groups = _groupByItemAndBatch(visible);

    // ---------------- RESET FORM ----------------
    emit(
      state.copyWith(
        items: items,
        groupedItems: groups,
        filteredGroupedItems: groups,

        clearCurrentProduct: true,
        scannedBarcode: null,

        expiryOptions: const [],
        selectedExpiry: null,

        batchOptions: const [],
        selectedBatch: null,

        units: const [],
        selectedUnit: null,

        suggestions: const [],
        success: "Item saved successfully",
        resetForm: true,
        clearError: true,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  Future<void> _onDelete(
    DeleteBatchItemEvent event,
    Emitter<StockBatchState> emit,
  ) async {
    await repo.delete(event.id);

    final items = await repo.loadItems(event.projectId);
    final visible = items.where((e) => !e.isDeleted).toList();
    final groups = _groupByItemAndBatch(visible);

    emit(
      state.copyWith(
        items: items,
        groupedItems: groups,
        filteredGroupedItems: groups,
        success: "Item deleted successfully",
      ),
    );
  }

  // ---------------------------------------------------------------------------
  Future<void> _onSearch(
    SearchBatchQueryChanged event,
    Emitter<StockBatchState> emit,
  ) async {
    final q = event.query.trim().toLowerCase();

    if (q.length < 2) {
      emit(state.copyWith(suggestions: []));
      return;
    }

    await productsRepo.ensureLoaded();

    final results = productsRepo.searchLocal((p) {
      return p.itemName.toLowerCase().contains(q) ||
          p.itemCode.toLowerCase().contains(q) ||
          p.barcodes.any((b) => b.contains(q));
    });

    emit(state.copyWith(suggestions: results.take(10).toList()));
  }

  // ---------------------------------------------------------------------------
  void _onReset(ResetBatchFormEvent event, Emitter<StockBatchState> emit) {
    emit(
      state.copyWith(
        resetForm: false,

        currentProduct: null,
        scannedBarcode: null,

        expiryOptions: const [],
        selectedExpiry: null,

        batchOptions: const [],
        selectedBatch: null,

        units: const [],
        selectedUnit: null,

        clearError: true,
        clearSuccess: true,
      ),
    );
  }

  List<StockBatchGroup> _groupByItemAndBatch(List<StockBatchItemModel> items) {
    final Map<String, List<StockBatchItemModel>> map = {};

    for (final it in items) {
      final batchKey = it.batch ?? '-';
      final key = '${it.itemCode}__$batchKey';

      map.putIfAbsent(key, () => []);
      map[key]!.add(it);
    }

    final groups = <StockBatchGroup>[];

    for (final entry in map.entries) {
      final rows = entry.value;

      double totalQty = 0;
      DateTime latest = rows.first.createdAt;

      for (final r in rows) {
        totalQty += r.quantity;
        if (r.createdAt.isAfter(latest)) {
          latest = r.createdAt;
        }
      }

      groups.add(
        StockBatchGroup(
          itemCode: rows.first.itemCode,
          itemName: rows.first.itemName,
          barcode: rows.first.barcode,

          batch: rows.first.batch ?? '-',

          nearExpiry: rows.first.nearExpiry,

          totalQty: totalQty,
          latestCreatedAt: latest,
        ),
      );
    }

    groups.sort((a, b) => b.latestCreatedAt.compareTo(a.latestCreatedAt));
    return groups;
  }

  Future<void> _onProductChosenFromSearch(
    ProductChosenFromSearchEvent event,
    Emitter<StockBatchState> emit,
  ) async {
    final product = event.product;

    await productsRepo.ensureLoaded();

    final units = productsRepo.getUnitsForProduct(product);

    // ---------------- RESET DEFAULT ----------------
    List<DateTime> expiryOptions = const [];
    DateTime? selectedExpiry;

    List<String> batchOptions = const [];
    String? selectedBatch;

    // ---------------- BATCH LOGIC ----------------
    if (product.isBatch) {
      expiryOptions = productsRepo.getNearExpiriesForProduct(product.itemCode);

      if (expiryOptions.length == 1) {
        selectedExpiry = expiryOptions.first;

        batchOptions = productsRepo.getBatchesForProductAndExpiry(
          product.itemCode,
          selectedExpiry,
        );

        if (batchOptions.length == 1) {
          selectedBatch = batchOptions.first;
        }
      }
    }

    emit(
      state.copyWith(
        currentProduct: product,

        expiryOptions: product.isBatch ? expiryOptions : const [],
        selectedExpiry: product.isBatch ? selectedExpiry : null,

        batchOptions: product.isBatch ? batchOptions : const [],
        selectedBatch: product.isBatch ? selectedBatch : null,

        units: units,
        selectedUnit: units.isNotEmpty ? units.first : null,

        suggestions: const [],
        clearError: true,
      ),
    );
  }

  void _onChangeUnit(ChangeUnitEvent event, Emitter<StockBatchState> emit) {
    emit(state.copyWith(selectedUnit: event.unit));
  }

  Future<void> _onExportExcel(
    ExportStockBatchExcelEvent event,
    Emitter<StockBatchState> emit,
  ) async {
    try {
      emit(state.copyWith(loading: true));

      await exportService.exportAndSaveExcel(
        projectId: event.projectId,
        projectName: event.projectName,
      );

      emit(
        state.copyWith(
          loading: false,
          success: "Stock Batch Excel saved successfully",
        ),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onSendByEmail(
    SendStockBatchByEmailEvent event,
    Emitter<StockBatchState> emit,
  ) async {
    try {
      emit(state.copyWith(loading: true));

      await exportService.sendExcelByEmail(
        projectId: event.projectId,
        projectName: event.projectName,
        toEmail: session.email!,
      );

      emit(
        state.copyWith(
          loading: false,
          success: "Stock Batch report sent to ${session.email}",
        ),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onUpload(
    UploadStockBatchEvent event,
    Emitter<StockBatchState> emit,
  ) async {
    try {
      emit(state.copyWith(loading: true));

      await repo.syncUp(event.projectId);

      final items = await repo.loadItems(event.projectId);

      emit(
        state.copyWith(
          loading: false,
          items: items,
          success: "Stock Batch uploaded successfully",
        ),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
