import 'package:equatable/equatable.dart';

import '../../../data/model/products_model.dart';

abstract class ProductUnitMapEvent extends Equatable {
  const ProductUnitMapEvent();
  @override
  List<Object?> get props => [];
}

class InitProductUnitMapEvent extends ProductUnitMapEvent {}

class SearchQueryChangedEvent extends ProductUnitMapEvent {
  final String query;
  const SearchQueryChangedEvent(this.query);
  @override
  List<Object?> get props => [query];
}

class SelectProductEvent extends ProductUnitMapEvent {
  final ProductModel product;
  final String barcode;
  const SelectProductEvent({required this.product, required this.barcode});
  @override
  List<Object?> get props => [product, barcode];
}

class UnitSelectedEvent extends ProductUnitMapEvent {
  final String unit;
  const UnitSelectedEvent(this.unit);
  @override
  List<Object?> get props => [unit];
}

class AddMappingEvent extends ProductUnitMapEvent {}

class RemoveMappingEvent extends ProductUnitMapEvent {
  final String key;
  const RemoveMappingEvent(this.key);
  @override
  List<Object?> get props => [key];
}

class ScanBarcodeAndSelectEvent extends ProductUnitMapEvent {}

class SyncPendingEvent extends ProductUnitMapEvent {}
