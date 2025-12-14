import 'package:apg_scanner/data/model/stock_taking_model.dart';

import '../../../data/model/products_model.dart';

abstract class StockEvent {
  const StockEvent();
}

class LoadStockEvent extends StockEvent {
  final String projectId;
  const LoadStockEvent(this.projectId);
}

class ScanBarcodeEvent extends StockEvent {
  final String projectId;
  final String barcode;
  const ScanBarcodeEvent({required this.projectId, required this.barcode});
}

class DeleteStockEvent extends StockEvent {
  final String id;
  const DeleteStockEvent(this.id);
}

class SyncStockEvent extends StockEvent {
  final String projectId;
  const SyncStockEvent(this.projectId);
}

class ChangeUnitEvent extends StockEvent {
  final String? unit;
  const ChangeUnitEvent(this.unit);
}

class ApproveItemEvent extends StockEvent {
  final String projectId;
  final String barcode;
  final String unit;
  final int qty;

  const ApproveItemEvent({
    required this.projectId,
    required this.barcode,
    required this.unit,
    required this.qty,
  });
}

class ResetFormEvent extends StockEvent {
  const ResetFormEvent();
}

class SearchQueryChanged extends StockEvent {
  final String query;
  const SearchQueryChanged(this.query);
}

class ProductChosenFromSearch extends StockEvent {
  final ProductModel product;
  const ProductChosenFromSearch(this.product);
}

class SearchScannedItemsEvent extends StockEvent {
  final String query;
  SearchScannedItemsEvent(this.query);
}

class ChangeSelectedIndexEvent extends StockEvent {
  final int index;
  ChangeSelectedIndexEvent(this.index);
}

class ScannedItemSelectedEvent extends StockEvent {
  final StockItemModel item;

  ScannedItemSelectedEvent(this.item);
}

class MarkProductExistsDialogShownEvent extends StockEvent {
  const MarkProductExistsDialogShownEvent();
}

class ClearProductAlreadyExistsFlagEvent extends StockEvent {
  const ClearProductAlreadyExistsFlagEvent();
}

class UploadStockEvent extends StockEvent {
  final String projectId;
  const UploadStockEvent({required this.projectId});
}

class ExportExcelEvent extends StockEvent {
  final String projectId;
  const ExportExcelEvent(this.projectId);
}

class SendStockByEmailEvent extends StockEvent {
  final String projectId;
  final String branchName;

  const SendStockByEmailEvent({
    required this.projectId,
    required this.branchName,
  });
}
