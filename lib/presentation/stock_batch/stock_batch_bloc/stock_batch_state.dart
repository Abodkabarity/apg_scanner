import 'package:equatable/equatable.dart';

import '../../../../data/model/product_with_batch_model.dart';
import '../../../../data/model/stock_batch_item_model.dart';
import '../../../data/model/stock_batch_group.dart';

enum SnackType { success, info, error }

class StockBatchState extends Equatable {
  // ---------------------------------------------------------------------------
  // INTERNAL (for nullable reset)
  // ---------------------------------------------------------------------------
  static const Object _unset = Object();

  // ---------------------------------------------------------------------------
  // UI STATUS
  // ---------------------------------------------------------------------------
  final bool loading;
  final bool isProcessing;
  final String? processingMessage;
  final bool autoFocusScan;

  // ---------------------------------------------------------------------------
  // STORED ITEMS
  // ---------------------------------------------------------------------------
  final List<StockBatchItemModel> items;
  final List<StockBatchGroup> groupedItems;
  final List<StockBatchGroup> filteredGroupedItems;
  final DateTime? manualExpiry;
  final String? manualBatch;
  final bool hasPendingItem;

  // ---------------------------------------------------------------------------
  // CURRENT PRODUCT
  // ---------------------------------------------------------------------------
  final ProductWithBatchModel? currentProduct;
  bool get isBatch => currentProduct?.isBatch ?? true;

  // ---------------------------------------------------------------------------
  // EXPIRY / BATCH (FOR BATCH PRODUCTS)
  // ---------------------------------------------------------------------------
  final List<DateTime> expiryOptions;
  final DateTime? selectedExpiry;

  final List<String> batchOptions;
  final String? selectedBatch;
  final SnackType? snackType;
  final bool autoFocusQty;
  final int snackId;

  // ---------------------------------------------------------------------------
  // UNIT / QTY
  // ---------------------------------------------------------------------------
  final List<String> units;
  final String? selectedUnit;
  final int scanId;

  // ---------------------------------------------------------------------------
  // SEARCH / SCAN
  // ---------------------------------------------------------------------------
  final List<ProductWithBatchModel> suggestions;
  final String? scannedBarcode;

  // ---------------------------------------------------------------------------
  // FEEDBACK
  // ---------------------------------------------------------------------------
  final String? error;
  final String? success;

  // ---------------------------------------------------------------------------
  // CONTROL FLAGS
  // ---------------------------------------------------------------------------
  final bool resetForm;

  const StockBatchState({
    this.loading = false,
    this.items = const [],
    this.groupedItems = const [],
    this.filteredGroupedItems = const [],
    this.autoFocusQty = false,
    this.hasPendingItem = false,
    this.autoFocusScan = false,
    this.snackId = 0,
    this.currentProduct,

    this.expiryOptions = const [],
    this.selectedExpiry,

    this.batchOptions = const [],
    this.selectedBatch,
    this.scanId = 0,

    this.units = const [],
    this.selectedUnit,
    this.isProcessing = false,
    this.processingMessage,
    this.suggestions = const [],
    this.scannedBarcode,

    this.error,
    this.success,

    this.resetForm = false,
    this.snackType,
    this.manualExpiry,
    this.manualBatch,
  });

  // ---------------------------------------------------------------------------
  // SYNC STATUS
  // ---------------------------------------------------------------------------
  bool get hasUnsyncedItems => items.any((e) => !e.isSynced);

  StockBatchState copyWith({
    bool? loading,
    List<StockBatchItemModel>? items,
    List<StockBatchGroup>? groupedItems,
    List<StockBatchGroup>? filteredGroupedItems,
    bool? autoFocusQty,

    Object? manualExpiry = _unset,
    Object? manualBatch = _unset,

    ProductWithBatchModel? currentProduct,
    bool clearCurrentProduct = false,
    bool? isProcessing,
    String? processingMessage,
    int? scanId,
    List<DateTime>? expiryOptions,
    Object? selectedExpiry = _unset,
    bool? autoFocusScan,

    List<String>? batchOptions,
    Object? selectedBatch = _unset,
    SnackType? snackType,
    bool? hasPendingItem,

    List<String>? units,
    String? selectedUnit,

    List<ProductWithBatchModel>? suggestions,
    String? scannedBarcode,

    String? error,
    String? success,
    int? snackId,

    bool? resetForm,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return StockBatchState(
      loading: loading ?? this.loading,

      items: items ?? this.items,
      groupedItems: groupedItems ?? this.groupedItems,
      filteredGroupedItems: filteredGroupedItems ?? this.filteredGroupedItems,

      currentProduct: clearCurrentProduct
          ? null
          : currentProduct ?? this.currentProduct,

      expiryOptions: expiryOptions ?? this.expiryOptions,
      selectedExpiry: selectedExpiry == _unset
          ? this.selectedExpiry
          : selectedExpiry as DateTime?,
      isProcessing: isProcessing ?? this.isProcessing,
      processingMessage: processingMessage ?? this.processingMessage,
      batchOptions: batchOptions ?? this.batchOptions,
      selectedBatch: selectedBatch == _unset
          ? this.selectedBatch
          : selectedBatch as String?,
      autoFocusQty: autoFocusQty ?? this.autoFocusQty,

      units: units ?? this.units,
      selectedUnit: selectedUnit ?? this.selectedUnit,

      manualExpiry: manualExpiry == _unset
          ? this.manualExpiry
          : manualExpiry as DateTime?,
      snackId: snackId ?? this.snackId,

      manualBatch: manualBatch == _unset
          ? this.manualBatch
          : manualBatch as String?,

      suggestions: suggestions ?? this.suggestions,
      scannedBarcode: scannedBarcode ?? this.scannedBarcode,

      error: clearError ? null : error ?? this.error,
      success: clearSuccess ? null : success ?? this.success,
      hasPendingItem: hasPendingItem ?? this.hasPendingItem,
      autoFocusScan: autoFocusScan ?? this.autoFocusScan,
      scanId: scanId ?? this.scanId,

      resetForm: resetForm ?? false,
      snackType: snackType ?? this.snackType,
    );
  }

  // ---------------------------------------------------------------------------
  // EQUATABLE
  // ---------------------------------------------------------------------------
  @override
  List<Object?> get props => [
    loading,
    items,
    groupedItems,
    filteredGroupedItems,

    currentProduct,

    expiryOptions,
    selectedExpiry,

    batchOptions,
    selectedBatch,

    units,
    selectedUnit,
    scanId,
    manualExpiry,
    manualBatch,
    autoFocusScan,
    suggestions,
    scannedBarcode,
    isProcessing,
    processingMessage,
    error,
    success,
    snackType,
    resetForm,
    autoFocusQty,
    hasPendingItem,
    snackId,
  ];
}
