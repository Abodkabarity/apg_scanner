import 'package:equatable/equatable.dart';

import '../../../data/model/near_expiry_item_model.dart';
import '../../../data/model/products_model.dart';
import '../../../data/model/stock_item_group.dart';

enum NearDuplicateAction { add, edit }

class NearExpiryState extends Equatable {
  final bool loading;
  final List<NearExpiryItemModel> items;
  final List<DateTime> nearExpiryOptions;

  final ProductModel? currentProduct;
  final List<String> units;
  final String? selectedUnit;

  final DateTime? selectedNearExpiry;

  final String? error;
  final String? success;
  final String? editingRowId;

  final List<NearExpiryItemModel> filteredItems;
  final int? selectedIndex;

  final bool productAlreadyExists;
  final bool productExistsDialogShown;

  final bool isUploading;
  final String? uploadMessage;

  final bool isProcessing;
  final String? processingMessage;

  final NearDuplicateAction duplicateAction;

  final List<StockItemGroup> groupedItems;
  final List<StockItemGroup> filteredGroupedItems;

  final List<ProductModel> suggestions;

  const NearExpiryState({
    this.loading = false,
    this.items = const [],
    this.currentProduct,
    this.units = const [],
    this.selectedUnit,
    this.nearExpiryOptions = const [],

    this.selectedNearExpiry,
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
    this.duplicateAction = NearDuplicateAction.edit,
    this.editingRowId,
    this.isProcessing = false,
    this.processingMessage,
  });

  bool get hasUnsyncedItems => items.any((e) => !e.isSynced);

  NearExpiryState copyWith({
    bool? loading,
    List<NearExpiryItemModel>? items,

    ProductModel? currentProduct,
    bool setNullProduct = false,
    List<DateTime>? nearExpiryOptions,

    List<String>? units,

    String? selectedUnit,
    bool setNullSelectedUnit = false,

    DateTime? selectedNearExpiry,
    bool clearSelectedNearExpiry = false,

    String? error,
    String? success,

    List<ProductModel>? suggestions,

    List<NearExpiryItemModel>? filteredItems,

    int? selectedIndex,
    bool setNullSelectedIndex = false,

    bool? productAlreadyExists,
    bool? productExistsDialogShown,

    bool? isUploading,
    String? uploadMessage,

    bool? isProcessing,
    String? processingMessage,
    bool clearProcessingMessage = false,

    NearDuplicateAction? duplicateAction,

    String? editingRowId,
    bool clearEditingRowId = false,

    List<StockItemGroup>? groupedItems,
    List<StockItemGroup>? filteredGroupedItems,
  }) {
    return NearExpiryState(
      loading: loading ?? this.loading,
      items: items ?? this.items,

      currentProduct: setNullProduct
          ? null
          : (currentProduct ?? this.currentProduct),

      units: units ?? this.units,

      selectedUnit: setNullSelectedUnit
          ? null
          : (selectedUnit ?? this.selectedUnit),

      selectedNearExpiry: clearSelectedNearExpiry
          ? null
          : (selectedNearExpiry ?? this.selectedNearExpiry),
      nearExpiryOptions: nearExpiryOptions ?? this.nearExpiryOptions,

      error: error,
      success: success,

      suggestions: suggestions ?? this.suggestions,

      filteredItems: filteredItems ?? this.filteredItems,

      selectedIndex: setNullSelectedIndex
          ? null
          : (selectedIndex ?? this.selectedIndex),

      productAlreadyExists: productAlreadyExists ?? this.productAlreadyExists,
      productExistsDialogShown:
          productExistsDialogShown ?? this.productExistsDialogShown,

      isUploading: isUploading ?? this.isUploading,
      uploadMessage: uploadMessage ?? this.uploadMessage,

      isProcessing: isProcessing ?? this.isProcessing,
      processingMessage: clearProcessingMessage
          ? null
          : (processingMessage ?? this.processingMessage),

      duplicateAction: duplicateAction ?? this.duplicateAction,

      editingRowId: clearEditingRowId
          ? null
          : (editingRowId ?? this.editingRowId),

      groupedItems: groupedItems ?? this.groupedItems,
      filteredGroupedItems: filteredGroupedItems ?? this.filteredGroupedItems,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    items,
    currentProduct,
    units,
    selectedUnit,
    selectedNearExpiry,
    error,
    success,
    suggestions,
    filteredItems,
    selectedIndex,
    isUploading,
    uploadMessage,
    productExistsDialogShown,
    productAlreadyExists,
    isProcessing,
    processingMessage,
    duplicateAction,
    groupedItems,
    filteredGroupedItems,
    editingRowId,
  ];
}
