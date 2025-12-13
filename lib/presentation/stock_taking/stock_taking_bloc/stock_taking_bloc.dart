import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/model/stock_taking_model.dart';
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
    on<ClearProductAlreadyExistsFlagEvent>((event, emit) {
      emit(state.copyWith(productAlreadyExists: false));
    });
    on<UploadStockEvent>(_onUploadStock);

    on<ChangeUnitEvent>((event, emit) {
      emit(state.copyWith(selectedUnit: event.unit));
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

    StockItemModel? existingItem;

    try {
      existingItem = state.items.firstWhere(
        (e) => e.itemCode == product.itemCode,
      );
    } catch (_) {
      existingItem = null;
    }

    emit(
      state.copyWith(
        loading: false,
        currentProduct: product,
        units: productsRepo.getUnitsForProduct(product),
        selectedUnit: existingItem?.unit,
        setNullSelectedUnit: existingItem == null,
        productAlreadyExists: existingItem != null,
        error: null,
        productExistsDialogShown: false,
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
        productExistsDialogShown: false,
      ),
    );
  }

  Future<void> _onDelete(
    DeleteStockEvent event,
    Emitter<StockState> emit,
  ) async {
    await repo.delete(event.id);

    final updatedItems = state.items.where((e) => e.id != event.id).toList();

    emit(
      state.copyWith(
        items: updatedItems,
        filteredItems: updatedItems,

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
        setNullSelectedIndex: true,

        error: null,
        selectedIndex: null,
        productExistsDialogShown: false,
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
      existingItem = state.items.firstWhere(
        (e) => e.itemCode == product.itemCode,
      );
    } catch (_) {
      existingItem = null;
    }

    emit(
      state.copyWith(
        currentProduct: product,
        units: productsRepo.getUnitsForProduct(product),
        selectedUnit: existingItem?.unit,
        setNullSelectedUnit: existingItem == null,
        productAlreadyExists: existingItem != null,
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

    try {
      final items = state.items;

      if (items.isEmpty) {
        emit(
          state.copyWith(
            isUploading: false,
            error: "No Items to Upload",
            uploadMessage: null,
          ),
        );
        return;
      }

      await repo.uploadStockItems(projectId: event.projectId, items: items);

      emit(
        state.copyWith(
          isUploading: false,
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
}
