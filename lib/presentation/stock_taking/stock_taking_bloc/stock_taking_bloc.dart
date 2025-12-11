import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/products_repository.dart';
import '../../../data/repositories/stock_taking_repository.dart';
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

    on<ChangeUnitEvent>((event, emit) {
      emit(state.copyWith(selectedUnit: event.unit));
    });

    on<ApproveItemEvent>(_onApprove);
    on<ResetFormEvent>(_onResetForm);

    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<ProductChosenFromSearch>(_onProductChosenFromSearch);
  }

  Future<void> _onLoad(LoadStockEvent event, Emitter<StockState> emit) async {
    emit(state.copyWith(loading: true));

    await productsRepo.ensureLoaded();
    final items = await repo.loadItems(event.projectId);

    emit(state.copyWith(loading: false, items: items, filteredItems: items));
  }

  Future<void> _onScan(ScanBarcodeEvent event, Emitter<StockState> emit) async {
    emit(state.copyWith(loading: true, error: null));

    await productsRepo.ensureLoaded();

    final product = productsRepo.findByBarcode(event.barcode);

    if (product == null) {
      emit(state.copyWith(loading: false, error: "Item not found"));
      return;
    }

    final units = productsRepo.getUnitsForProduct(product);

    emit(
      state.copyWith(
        loading: false,
        currentProduct: product,
        units: units,
        setNullSelectedUnit: true,
        selectedUnit: null,
        error: null,
        suggestions: [],
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

    final existing = await repo.findExistingItem(
      event.projectId,
      product.itemCode,
    );

    if (existing != null) {
      await repo.updateItem(
        item: existing,
        qty: event.qty,
        unit: event.unit,
        product: product,
      );
    } else {
      await repo.saveNewItem(
        projectId: event.projectId,
        barcode: event.barcode,
        product: product,
        qty: event.qty,
        unit: event.unit,
      );
    }

    final items = await repo.loadItems(event.projectId);

    emit(
      state.copyWith(
        items: items,
        currentProduct: null,
        units: [],
        setNullSelectedUnit: true,
        selectedUnit: null,
        filteredItems: items,
        success: "Item saved successfully",
        error: null,
        suggestions: [],
      ),
    );
  }

  Future<void> _onDelete(
    DeleteStockEvent event,
    Emitter<StockState> emit,
  ) async {
    await repo.delete(event.id);

    final updated = state.items.where((e) => e.id != event.id).toList();

    emit(state.copyWith(items: updated));
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
        error: null,
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
    final units = productsRepo.getUnitsForProduct(product);

    emit(
      state.copyWith(
        currentProduct: product,
        units: units,
        selectedUnit: null,
        setNullSelectedUnit: true,
        suggestions: [],
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
      emit(state.copyWith(filteredItems: state.items));
      return;
    }

    final filtered = state.items.where((item) {
      return item.itemName.toLowerCase().contains(q) ||
          item.itemCode.toLowerCase().contains(q);
    }).toList();

    emit(state.copyWith(filteredItems: filtered));
  }
}
