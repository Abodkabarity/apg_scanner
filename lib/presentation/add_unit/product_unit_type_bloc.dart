import 'package:apg_scanner/presentation/add_unit/product_unit_type_event.dart';
import 'package:apg_scanner/presentation/add_unit/product_unit_type_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/product_unit_repository.dart';
import '../../../data/repositories/products_repository.dart';

class ProductUnitMapBloc
    extends Bloc<ProductUnitMapEvent, ProductUnitMapState> {
  final ProductsRepository productsRepo;
  final ProductUnitRepository unitRepo;

  ProductUnitMapBloc(this.productsRepo, this.unitRepo)
    : super(ProductUnitMapState.initial()) {
    on<InitProductUnitMapEvent>(_onInit);
    on<SearchQueryChangedEvent>(_onSearch);
    on<SelectProductEvent>(_onSelectProduct);
    on<UnitSelectedEvent>(_onUnitSelected);
    on<AddMappingEvent>(_onAdd);
    on<RemoveMappingEvent>(_onRemove);
    on<SyncPendingEvent>(_onSync);
  }

  Future<void> _onInit(
    InitProductUnitMapEvent event,
    Emitter<ProductUnitMapState> emit,
  ) async {
    try {
      emit(state.copyWith(loading: true, clearError: true, clearMessage: true));

      await productsRepo.ensureLoaded();

      final units = await unitRepo.loadUnitsDistinct();
      final pending = await unitRepo.loadPending();

      emit(
        state.copyWith(
          loading: false,
          allUnits: units,
          pending: pending,
          searchResults: [],
        ),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onSearch(
    SearchQueryChangedEvent event,
    Emitter<ProductUnitMapState> emit,
  ) async {
    final q = event.query.trim().toLowerCase();

    if (q.isEmpty) {
      emit(state.copyWith(searchQuery: event.query, searchResults: []));
      return;
    }

    // بحث سريع من الذاكرة (Hive loaded)
    final results = productsRepo.products
        .where((p) {
          final name = p.itemName.toLowerCase();
          final code = p.itemCode.toLowerCase();
          final matchBarcode = p.barcodes.any((b) => b.contains(q));
          return name.contains(q) || code.contains(q) || matchBarcode;
        })
        .take(50)
        .toList();

    emit(
      state.copyWith(
        searchQuery: event.query,
        searchResults: results,
        clearMessage: true,
        clearError: true,
      ),
    );
  }

  Future<void> _onSelectProduct(
    SelectProductEvent event,
    Emitter<ProductUnitMapState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedProduct: event.product,
        selectedBarcode: event.barcode,
        message: "Product selected",
        clearError: true,
      ),
    );
  }

  Future<void> _onUnitSelected(
    UnitSelectedEvent event,
    Emitter<ProductUnitMapState> emit,
  ) async {
    emit(state.copyWith(selectedUnit: event.unit, clearMessage: true));
  }

  Future<void> _onAdd(
    AddMappingEvent event,
    Emitter<ProductUnitMapState> emit,
  ) async {
    final p = state.selectedProduct;
    final b = state.selectedBarcode;
    final u = state.selectedUnit;

    if (p == null || b == null || b.isEmpty) {
      emit(state.copyWith(error: "Select product first"));
      return;
    }

    if (u == null || u.isEmpty) {
      emit(state.copyWith(error: "Select unit first"));
      return;
    }

    await unitRepo.addPending(
      itemCode: p.itemCode,
      itemName: p.itemName,
      barcode: b,
      unit: u,
    );

    final pending = await unitRepo.loadPending();

    emit(state.copyWith(pending: pending, message: "Added"));
  }

  Future<void> _onRemove(
    RemoveMappingEvent event,
    Emitter<ProductUnitMapState> emit,
  ) async {
    await unitRepo.removePendingByKey(event.key);
    final pending = await unitRepo.loadPending();
    emit(state.copyWith(pending: pending, clearMessage: true));
  }

  Future<void> _onSync(
    SyncPendingEvent event,
    Emitter<ProductUnitMapState> emit,
  ) async {
    try {
      emit(state.copyWith(syncing: true, clearError: true, clearMessage: true));
      final count = await unitRepo.syncPending();
      emit(
        state.copyWith(
          syncing: false,
          pending: const [],
          message: "Synced ($count) items",
        ),
      );
    } catch (e) {
      emit(state.copyWith(syncing: false, error: e.toString()));
    }
  }
}
