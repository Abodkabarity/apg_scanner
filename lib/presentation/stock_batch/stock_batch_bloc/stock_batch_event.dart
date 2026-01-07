import 'package:equatable/equatable.dart';

import '../../../../data/model/product_with_batch_model.dart';

// ---------------------------------------------------------------------------
// BASE
// ---------------------------------------------------------------------------
abstract class StockBatchEvent extends Equatable {
  const StockBatchEvent();

  @override
  List<Object?> get props => [];
}

// ---------------------------------------------------------------------------
// LOAD
// ---------------------------------------------------------------------------
class LoadStockBatchEvent extends StockBatchEvent {
  final String projectId;
  const LoadStockBatchEvent(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

// ---------------------------------------------------------------------------
// SCAN / SEARCH
// ---------------------------------------------------------------------------
class ScanBatchBarcodeEvent extends StockBatchEvent {
  final String projectId;
  final String barcode;

  const ScanBatchBarcodeEvent({required this.projectId, required this.barcode});

  @override
  List<Object?> get props => [projectId, barcode];
}

class SearchBatchQueryChanged extends StockBatchEvent {
  final String query;
  const SearchBatchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class ProductChosenFromSearchEvent extends StockBatchEvent {
  final ProductWithBatchModel product;
  const ProductChosenFromSearchEvent(this.product);

  @override
  List<Object?> get props => [product];
}

// ---------------------------------------------------------------------------
// SELECTORS
// ---------------------------------------------------------------------------
class ChangeSelectedExpiryEvent extends StockBatchEvent {
  final String itemCode;
  final DateTime expiry;

  const ChangeSelectedExpiryEvent({
    required this.itemCode,
    required this.expiry,
  });

  @override
  List<Object?> get props => [itemCode, expiry];
}

class ChangeSelectedBatchEvent extends StockBatchEvent {
  final String batch;
  const ChangeSelectedBatchEvent(this.batch);

  @override
  List<Object?> get props => [batch];
}

class ChangeUnitEvent extends StockBatchEvent {
  final String unit;
  const ChangeUnitEvent(this.unit);

  @override
  List<Object?> get props => [unit];
}

// ---------------------------------------------------------------------------
// APPROVE / DELETE
// ---------------------------------------------------------------------------
class ApproveBatchItemEvent extends StockBatchEvent {
  final String projectId;
  final String projectName;
  final String barcode;
  final String unit;
  final double qty;

  const ApproveBatchItemEvent({
    required this.projectId,
    required this.projectName,
    required this.barcode,
    required this.unit,
    required this.qty,
  });

  @override
  List<Object?> get props => [projectId, projectName, barcode, unit, qty];
}

class DeleteBatchItemEvent extends StockBatchEvent {
  final String id;
  final String projectId;

  const DeleteBatchItemEvent({required this.id, required this.projectId});

  @override
  List<Object?> get props => [id, projectId];
}

// ---------------------------------------------------------------------------
// RESET
// ---------------------------------------------------------------------------
class ResetBatchFormEvent extends StockBatchEvent {
  const ResetBatchFormEvent();
}

class ExportStockBatchExcelEvent extends StockBatchEvent {
  final String projectId;
  final String projectName;

  const ExportStockBatchExcelEvent({
    required this.projectId,
    required this.projectName,
  });

  @override
  List<Object?> get props => [projectId, projectName];
}

class SendStockBatchByEmailEvent extends StockBatchEvent {
  final String projectId;
  final String projectName;

  const SendStockBatchByEmailEvent({
    required this.projectId,
    required this.projectName,
  });

  @override
  List<Object?> get props => [projectId, projectName];
}

class UploadStockBatchEvent extends StockBatchEvent {
  final String projectId;

  const UploadStockBatchEvent({required this.projectId});

  @override
  List<Object?> get props => [projectId];
}
