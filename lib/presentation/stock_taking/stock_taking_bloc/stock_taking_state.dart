import 'package:equatable/equatable.dart';

import '../../../data/model/products_model.dart';
import '../../../data/model/stock_taking_model.dart';

class StockState extends Equatable {
  final bool loading;
  final List<StockItemModel> items;
  final ProductModel? currentProduct;
  final String? error;

  const StockState({
    this.loading = false,
    this.items = const [],
    this.currentProduct,
    this.error,
  });

  StockState copyWith({
    bool? loading,
    List<StockItemModel>? items,
    ProductModel? currentProduct,
    String? error,
  }) {
    return StockState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      currentProduct: currentProduct,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, items, currentProduct, error];
}
