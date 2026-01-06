import 'package:equatable/equatable.dart';

import '../../../data/model/product_unit_map_model.dart';
import '../../../data/model/products_model.dart';

class ProductUnitMapState extends Equatable {
  final bool loading;
  final bool syncing;

  final List<String> allUnits;
  final String searchQuery;

  final ProductModel? selectedProduct;
  final String? selectedBarcode;
  final String? selectedUnit;

  final List<ProductModel> searchResults;
  final List<ProductUnitMapModel> pending;

  final String? message;
  final String? error;

  const ProductUnitMapState({
    required this.loading,
    required this.syncing,
    required this.allUnits,
    required this.searchQuery,
    required this.selectedProduct,
    required this.selectedBarcode,
    required this.selectedUnit,
    required this.searchResults,
    required this.pending,
    required this.message,
    required this.error,
  });

  factory ProductUnitMapState.initial() => const ProductUnitMapState(
    loading: true,
    syncing: false,
    allUnits: [],
    searchQuery: '',
    selectedProduct: null,
    selectedBarcode: null,
    selectedUnit: null,
    searchResults: [],
    pending: [],
    message: null,
    error: null,
  );

  ProductUnitMapState copyWith({
    bool? loading,
    bool? syncing,
    List<String>? allUnits,
    String? searchQuery,
    ProductModel? selectedProduct,
    String? selectedBarcode,
    String? selectedUnit,
    List<ProductModel>? searchResults,
    List<ProductUnitMapModel>? pending,
    String? message,
    String? error,
    bool clearMessage = false,
    bool clearError = false,
  }) {
    return ProductUnitMapState(
      loading: loading ?? this.loading,
      syncing: syncing ?? this.syncing,
      allUnits: allUnits ?? this.allUnits,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedProduct: selectedProduct ?? this.selectedProduct,
      selectedBarcode: selectedBarcode ?? this.selectedBarcode,
      selectedUnit: selectedUnit ?? this.selectedUnit,
      searchResults: searchResults ?? this.searchResults,
      pending: pending ?? this.pending,
      message: clearMessage ? null : (message ?? this.message),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    loading,
    syncing,
    allUnits,
    searchQuery,
    selectedProduct,
    selectedBarcode,
    selectedUnit,
    searchResults,
    pending,
    message,
    error,
  ];
}
