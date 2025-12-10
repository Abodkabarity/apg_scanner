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
  }

  Future<void> _onLoad(LoadStockEvent event, Emitter<StockState> emit) async {
    emit(state.copyWith(loading: true, error: null));

    await productsRepo.ensureLoaded();

    final items = await repo.loadItems(event.projectId);

    emit(state.copyWith(loading: false, items: items, error: null));
  }

  Future<void> _onScan(ScanBarcodeEvent event, Emitter<StockState> emit) async {
    emit(state.copyWith(loading: true, error: null));

    await productsRepo.ensureLoaded();

    final product = productsRepo.findByBarcode(event.barcode);

    if (product == null) {
      emit(state.copyWith(loading: false, error: "Item not found"));
      return;
    }

    await repo.scanAndAdd(
      projectId: event.projectId,
      barcode: event.barcode,
      product: product,
      qty: 1,
    );

    final items = await repo.loadItems(event.projectId);

    emit(state.copyWith(loading: false, items: items, currentProduct: product));
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
}
