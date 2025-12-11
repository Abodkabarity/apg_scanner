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

  /// suggestions for search (auto-complete)
  final List<ProductModel> suggestions;

  const StockState({
    this.loading = false,
    this.items = const [],
    this.currentProduct,
    this.units = const [],
    this.selectedUnit,
    this.error,
    this.success,
    this.suggestions = const [],
    this.filteredItems = const [],
    this.selectedIndex,
  });

  StockState copyWith({
    bool? loading,
    List<StockItemModel>? items,
    ProductModel? currentProduct,
    bool setNullProduct = false,
    List<String>? units,
    String? selectedUnit,
    bool setNullSelectedUnit = false,
    String? error,
    String? success,
    List<StockItemModel>? filteredItems,
    int? selectedIndex,

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
      selectedIndex: selectedIndex ?? this.selectedIndex,

      error: error,
      success: success,
      suggestions: suggestions ?? this.suggestions,
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
  ];
}
