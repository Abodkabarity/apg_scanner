import 'package:equatable/equatable.dart';

import '../../../../data/model/product_with_batch_model.dart';
import '../../../data/model/stock_batch_group.dart';

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
  final bool isManual;

  const ChangeSelectedExpiryEvent({
    required this.itemCode,
    required this.expiry,
    this.isManual = false,
  });

  @override
  List<Object?> get props => [itemCode, expiry, isManual];
}

class ChangeSelectedBatchEvent extends StockBatchEvent {
  final String batch;
  final bool isManual;

  const ChangeSelectedBatchEvent(this.batch, {this.isManual = false});

  @override
  List<Object?> get props => [batch, isManual];
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

class DeleteStockBatchGroupEvent extends StockBatchEvent {
  final String projectId;
  final StockBatchGroup group;

  const DeleteStockBatchGroupEvent({
    required this.projectId,
    required this.group,
  });

  @override
  List<Object?> get props => [projectId, group];
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

// EDIT

class UpdateStockBatchItemEvent extends StockBatchEvent {
  final String projectId;
  final StockBatchGroup group;

  /// unit -> qty (Box / Strip / ...)
  final Map<String, double> newUnitQty;

  final DateTime? newExpiry;
  final String? newBatch;

  const UpdateStockBatchItemEvent({
    required this.projectId,
    required this.group,
    required this.newUnitQty,
    required this.newExpiry,
    required this.newBatch,
  });

  @override
  List<Object?> get props => [
    projectId,
    group,
    newUnitQty,
    newExpiry,
    newBatch,
  ];
}
