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
  });

  StockState copyWith({
    bool? loading,
    List<StockItemModel>? items,
    ProductModel? currentProduct,
    bool setNullProduct = false, // <-- المفتاح هنا
    List<String>? units,
    String? selectedUnit,
    String? error,
    String? success,
    List<ProductModel>? suggestions,
  }) {
    return StockState(
      loading: loading ?? this.loading,
      items: items ?? this.items,

      currentProduct: setNullProduct
          ? null
          : (currentProduct ?? this.currentProduct),

      units: units ?? this.units,
      selectedUnit: selectedUnit ?? this.selectedUnit,
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
  ];
}
