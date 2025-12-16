import 'package:apg_scanner/data/model/stock_taking_model.dart';
import 'package:apg_scanner/presentation/stock_taking/stock_taking_bloc/stock_taking_state.dart';

import '../../../data/model/products_model.dart';
import '../../../data/model/stock_item_group.dart';

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
  final String projectName;

  const ApproveItemEvent({
    required this.projectId,

    required this.barcode,
    required this.unit,
    required this.qty,
    required this.projectName,
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
  final String projectName;
  const ExportExcelEvent(this.projectId, {required this.projectName});
}

class SendStockByEmailEvent extends StockEvent {
  final String projectId;
  final String projectName;
  final String branchName;

  const SendStockByEmailEvent({
    required this.projectId,
    required this.branchName,
    required this.projectName,
  });
}

class SetDuplicateActionEvent extends StockEvent {
  final DuplicateAction action;

  SetDuplicateActionEvent(this.action);
}

class UpdateMultiUnitEvent extends StockEvent {
  final String projectId;
  final String projectName;
  final StockItemGroup group;
  final Map<String, int> newUnitQty;

  UpdateMultiUnitEvent({
    required this.projectId,
    required this.group,
    required this.newUnitQty,
    required this.projectName,
  });
}

class EditSingleUnitFromListEvent extends StockEvent {
  final StockItemGroup group;

  final String rowId;

  final String unit;

  final int qty;

  EditSingleUnitFromListEvent({
    required this.group,
    required this.rowId,
    required this.unit,
    required this.qty,
  });
}
