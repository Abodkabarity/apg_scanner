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

  const StockState({
    this.loading = false,
    this.items = const [],
    this.currentProduct,
    this.units = const [],
    this.selectedUnit,
    this.error,
    this.success,
  });

  StockState copyWith({
    bool? loading,
    List<StockItemModel>? items,
    ProductModel? currentProduct,
    List<String>? units,
    String? selectedUnit,
    String? error,
    String? success,
  }) {
    return StockState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      // 👇 أهم سطرين في الدنيا الآن
      currentProduct: currentProduct ?? this.currentProduct,
      units: units ?? this.units,
      selectedUnit: selectedUnit ?? this.selectedUnit,
      // نخلي error / success يُستبدلوا بالكامل (نحب نمسحهم أحيانًا)
      error: error,
      success: success,
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
  ];
}
