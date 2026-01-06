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
  }

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

    final product = productsRepo.findByBarcode(event.barcode);

    if (product == null) {
      emit(state.copyWith(loading: false, error: "Item not found"));
      return;
    }

    if (!product.isBatch) {
      emit(
        state.copyWith(
          loading: false,
          error: "This product is not batch controlled",
        ),
      );
      return;
    }

    final expiries = productsRepo.getNearExpiriesForProduct(product.itemCode);

    emit(
      state.copyWith(
        loading: false,
        currentProduct: product,
        expiryOptions: expiries,
        selectedExpiry: null,
        batchOptions: const [],
        selectedBatch: null,
        scannedBarcode: event.barcode,
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
        selectedBatch: null,
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

    if (product == null) {
      emit(state.copyWith(error: "Scan product first"));
      return;
    }

    if (event.qty <= 0) {
      emit(state.copyWith(error: "Quantity required"));
      return;
    }

    if (state.selectedBatch == null || state.selectedBatch!.isEmpty) {
      emit(state.copyWith(error: "Batch required"));
      return;
    }

    final existing = await repo.findExistingItem(
      projectId: event.projectId,
      itemCode: product.itemCode,
      unit: event.unit,
      batch: state.selectedBatch!,
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
        unit: event.unit,
        qty: event.qty,
        expiry: state.selectedExpiry,
        batch: state.selectedBatch!,
      );
    }

    final items = await repo.loadItems(event.projectId);
    final visible = items.where((e) => !e.isDeleted).toList();
    final groups = _groupByItemAndBatch(visible);

    emit(
      state.copyWith(
        items: items,
        groupedItems: groups,
        filteredGroupedItems: groups,
        success: "Item saved successfully",
        resetForm: true,
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
  void _onSearch(SearchBatchQueryChanged event, Emitter<StockBatchState> emit) {
    final q = event.query.toLowerCase().trim();

    if (q.isEmpty) {
      emit(state.copyWith(filteredGroupedItems: state.groupedItems));
      return;
    }

    emit(
      state.copyWith(
        filteredGroupedItems: state.groupedItems.where((g) {
          final code = g.itemCode.toLowerCase();
          final name = g.itemName.toLowerCase();
          final batch = g.batch.toLowerCase();

          return code.contains(q) || name.contains(q) || batch.contains(q);
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  void _onReset(ResetBatchFormEvent event, Emitter<StockBatchState> emit) {
    emit(
      state.copyWith(
        resetForm: true,
        currentProduct: null,
        selectedExpiry: null,
        selectedBatch: null,
        expiryOptions: const [],
        batchOptions: const [],
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

  // ---------------------------------------------------------------------------
}
