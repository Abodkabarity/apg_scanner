import 'package:equatable/equatable.dart';

import '../../../data/model/products_model.dart';
import '../../../data/model/stock_item_group.dart';
import '../../../data/model/stock_taking_model.dart';

enum DuplicateAction { add, edit }

class StockState extends Equatable {
  final bool loading;
  final List<StockItemModel> items;
  final ProductModel? currentProduct;
  final List<String> units;
  final String? selectedUnit;
  final String? error;
  final String? success;
  final String? editingRowId;
  final String? scannedBarcode;

  final List<StockItemModel> filteredItems;
  final int? selectedIndex;
  final bool productAlreadyExists;
  final bool productExistsDialogShown;
  final bool isUploading;
  final String? uploadMessage;
  final bool isProcessing;
  final String? processingMessage;
  final DuplicateAction duplicateAction;
  final double subUnit;
  final List<StockItemGroup> groupedItems;
  final List<StockItemGroup> filteredGroupedItems;

  /// suggestions for search (auto-complete)
  final List<ProductModel> suggestions;

  const StockState({
    this.loading = false,
    this.items = const [],
    this.currentProduct,
    this.isProcessing = false,
    this.processingMessage,
    this.units = const [],
    this.selectedUnit,
    this.error,

    this.success,
    this.suggestions = const [],
    this.filteredItems = const [],
    this.selectedIndex,
    this.groupedItems = const [],
    this.filteredGroupedItems = const [],
    this.productAlreadyExists = false,
    this.productExistsDialogShown = false,
    this.isUploading = false,
    this.uploadMessage,
    this.duplicateAction = DuplicateAction.edit,
    this.subUnit = 1,
    this.editingRowId,
    this.scannedBarcode,
  });
  bool get hasUnsyncedItems => items.any((e) => !e.isSynced);

  StockState copyWith({
    bool? loading,
    List<StockItemModel>? items,
    ProductModel? currentProduct,
    bool setNullProduct = false,
    List<String>? units,
    String? selectedUnit,
    bool? isUploading,
    String? scannedBarcode,

    bool? isProcessing,
    String? processingMessage,
    bool clearProcessingMessage = false,
    String? uploadMessage,
    bool setNullSelectedUnit = false,
    bool setNullSelectedIndex = false,
    String? error,
    bool? productAlreadyExists,
    String? success,
    DuplicateAction? duplicateAction,
    double? subUnit,
    String? editingRowId,
    bool clearEditingRowId = false,

    List<StockItemGroup>? groupedItems,
    List<StockItemGroup>? filteredGroupedItems,
    List<StockItemModel>? filteredItems,
    int? selectedIndex,
    bool? productExistsDialogShown,

    List<ProductModel>? suggestions,
  }) {
    return StockState(
      loading: loading ?? this.loading,
      items: items ?? this.items,

      currentProduct: setNullProduct
          ? null
          : (currentProduct ?? this.currentProduct),

      units: units ?? this.units,
      selectedUnit: setNullSelectedUnit
          ? null
          : (selectedUnit ?? this.selectedUnit),
      filteredItems: filteredItems ?? this.filteredItems,
      productAlreadyExists: productAlreadyExists ?? this.productAlreadyExists,
      selectedIndex: setNullSelectedIndex
          ? null
          : (selectedIndex ?? this.selectedIndex),
      error: error,
      isProcessing: isProcessing ?? this.isProcessing,
      processingMessage: clearProcessingMessage
          ? null
          : processingMessage ?? this.processingMessage,
      isUploading: isUploading ?? this.isUploading,
      uploadMessage: uploadMessage ?? this.uploadMessage,
      success: success,
      scannedBarcode: scannedBarcode ?? this.scannedBarcode,

      duplicateAction: duplicateAction ?? this.duplicateAction,
      subUnit: subUnit ?? this.subUnit,
      groupedItems: groupedItems ?? this.groupedItems,
      filteredGroupedItems: filteredGroupedItems ?? this.filteredGroupedItems,
      suggestions: suggestions ?? this.suggestions,
      editingRowId: clearEditingRowId
          ? null
          : (editingRowId ?? this.editingRowId),

      productExistsDialogShown:
          productExistsDialogShown ?? this.productExistsDialogShown,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    items,
    currentProduct,
    units,
    selectedUnit,
    error,
    success,
    suggestions,
    filteredItems,
    selectedIndex,
    isUploading,
    productExistsDialogShown,
    productAlreadyExists,
    isProcessing,
    processingMessage,
    duplicateAction,
    subUnit,
    groupedItems,
    filteredGroupedItems,
    editingRowId,
    scannedBarcode,
  ];
}
