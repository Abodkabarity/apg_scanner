import 'package:equatable/equatable.dart';

import '../../../../data/model/product_with_batch_model.dart';
import '../../../../data/model/stock_batch_item_model.dart';
import '../../../data/model/stock_batch_group.dart';

enum SnackType { success, info, error }

class StockBatchState extends Equatable {
  // ---------------------------------------------------------------------------
  // UI STATUS
  // ---------------------------------------------------------------------------
  final bool loading;

  // ---------------------------------------------------------------------------
  // STORED ITEMS
  // ---------------------------------------------------------------------------
  final List<StockBatchItemModel> items;
  final List<StockBatchGroup> groupedItems;
  final List<StockBatchGroup> filteredGroupedItems;
  final DateTime? manualExpiry;
  final String? manualBatch;

  // ---------------------------------------------------------------------------
  // CURRENT PRODUCT
  // ---------------------------------------------------------------------------
  final ProductWithBatchModel? currentProduct;
  bool get isBatch => currentProduct?.isBatch ?? false;

  // ---------------------------------------------------------------------------
  // EXPIRY / BATCH (FOR BATCH PRODUCTS)
  // ---------------------------------------------------------------------------
  final List<DateTime> expiryOptions;
  final DateTime? selectedExpiry;

  final List<String> batchOptions;
  final String? selectedBatch;
  final SnackType? snackType;

  // ---------------------------------------------------------------------------
  // UNIT / QTY
  // ---------------------------------------------------------------------------
  final List<String> units;
  final String? selectedUnit;

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

    this.currentProduct,

    this.expiryOptions = const [],
    this.selectedExpiry,

    this.batchOptions = const [],
    this.selectedBatch,

    this.units = const [],
    this.selectedUnit,

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
  bool get hasUnsyncedItems => items.any((e) => !e.isSynced && !e.isDeleted);

  // ---------------------------------------------------------------------------
  // COPY
  // ---------------------------------------------------------------------------
  StockBatchState copyWith({
    bool? loading,
    List<StockBatchItemModel>? items,
    List<StockBatchGroup>? groupedItems,
    List<StockBatchGroup>? filteredGroupedItems,
    DateTime? manualExpiry,
    String? manualBatch,

    ProductWithBatchModel? currentProduct,
    bool clearCurrentProduct = false,

    List<DateTime>? expiryOptions,
    DateTime? selectedExpiry,

    List<String>? batchOptions,
    String? selectedBatch,
    SnackType? snackType,

    List<String>? units,
    String? selectedUnit,

    List<ProductWithBatchModel>? suggestions,
    String? scannedBarcode,

    String? error,
    String? success,

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
      selectedExpiry: selectedExpiry ?? this.selectedExpiry,
      snackType: snackType ?? this.snackType,

      batchOptions: batchOptions ?? this.batchOptions,

      units: units ?? this.units,
      selectedUnit: selectedUnit ?? this.selectedUnit,
      manualExpiry: manualExpiry ?? this.manualExpiry,
      manualBatch: manualBatch ?? this.manualBatch,

      suggestions: suggestions ?? this.suggestions,
      scannedBarcode: scannedBarcode ?? this.scannedBarcode,

      error: clearError ? null : error ?? this.error,
      success: clearSuccess ? null : success ?? this.success,

      resetForm: resetForm ?? false,
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
    manualBatch,
    suggestions,
    scannedBarcode,
    manualExpiry,
    error,
    success,
    snackType,
    resetForm,
  ];
}
