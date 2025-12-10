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
    on<ResetFormEvent>(_onResetForm);

    on<ChangeUnitEvent>((event, emit) {
      emit(state.copyWith(selectedUnit: event.unit));
    });

    on<ApproveItemEvent>(_onApprove);
  }

  // -----------------------------
  // LOAD ITEMS
  // -----------------------------
  Future<void> _onLoad(LoadStockEvent event, Emitter<StockState> emit) async {
    emit(state.copyWith(loading: true));

    await productsRepo.ensureLoaded();
    final items = await repo.loadItems(event.projectId);

    emit(state.copyWith(loading: false, items: items));
  }

  // -----------------------------
  // SCAN BARCODE
  // -----------------------------
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
        selectedUnit: null,
        error: null,
      ),
    );
  }

  // -----------------------------
  // APPROVE & SAVE / UPDATE ITEM
  // -----------------------------
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
      await repo.updateItem(item: existing, qty: event.qty, unit: event.unit);
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
        currentProduct: product,
        units: state.units,
        selectedUnit: state.selectedUnit,
        success: "Item saved successfully",
      ),
    );
  }

  // -----------------------------
  // DELETE ITEM
  // -----------------------------
  Future<void> _onDelete(
    DeleteStockEvent event,
    Emitter<StockState> emit,
  ) async {
    await repo.delete(event.id);

    final updated = state.items.where((e) => e.id != event.id).toList();

    emit(state.copyWith(items: updated));
  }

  // -----------------------------
  // SYNC TO SERVER
  // -----------------------------
  Future<void> _onSync(SyncStockEvent event, Emitter<StockState> emit) async {
    await repo.syncUp(event.projectId);
  }

  Future<void> _onResetForm(
    ResetFormEvent event,
    Emitter<StockState> emit,
  ) async {
    emit(
      state.copyWith(
        currentProduct: null,
        selectedUnit: null,
        units: [],
        success: null,
        error: null,
      ),
    );
  }
}
