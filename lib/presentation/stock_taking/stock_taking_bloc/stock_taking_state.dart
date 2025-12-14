import 'package:equatable/equatable.dart';

import '../../../data/model/products_model.dart';
import '../../../data/model/stock_taking_model.dart';

class StockState extends Equatable {
  final bool loading;
  final List<StockItemModel> items;
  final ProductModel? currentProduct;
  final List<String> units;
  final String? selectedUnit;
  final String? error;
  final String? success;
  final List<StockItemModel> filteredItems;
  final int? selectedIndex;
  final bool productAlreadyExists;
  final bool productExistsDialogShown;
  final bool isUploading;
  final String? uploadMessage;
  final bool isProcessing;
  final String? processingMessage;

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
    this.productAlreadyExists = false,
    this.productExistsDialogShown = false,
    this.isUploading = false,
    this.uploadMessage,
  });

  StockState copyWith({
    bool? loading,
    List<StockItemModel>? items,
    ProductModel? currentProduct,
    bool setNullProduct = false,
    List<String>? units,
    String? selectedUnit,
    bool? isUploading,
    bool? isProcessing,
    String? processingMessage,
    bool clearProcessingMessage = false,
    String? uploadMessage,
    bool setNullSelectedUnit = false,
    bool setNullSelectedIndex = false,
    String? error,
    bool? productAlreadyExists,
    String? success,

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
      suggestions: suggestions ?? this.suggestions,
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
  ];
}
