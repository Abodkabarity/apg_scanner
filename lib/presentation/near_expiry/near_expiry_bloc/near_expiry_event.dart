import '../../../data/model/near_expiry_item_model.dart';
import '../../../data/model/products_model.dart';
import '../../../data/model/stock_item_group.dart';
import 'near_expiry_state.dart';

abstract class NearExpiryEvent {
  const NearExpiryEvent();
}

class LoadNearExpiryEvent extends NearExpiryEvent {
  final String projectId;
  const LoadNearExpiryEvent(this.projectId);
}

class ScanBarcodeEvent extends NearExpiryEvent {
  final String projectId;
  final String barcode;
  const ScanBarcodeEvent({required this.projectId, required this.barcode});
}

class DeleteNearExpiryEvent extends NearExpiryEvent {
  final List<String> ids;
  final String projectId;
  const DeleteNearExpiryEvent({required this.ids, required this.projectId});
}

class SyncNearExpiryEvent extends NearExpiryEvent {
  final String projectId;
  const SyncNearExpiryEvent(this.projectId);
}

class ChangeUnitEvent extends NearExpiryEvent {
  final String? unit;
  const ChangeUnitEvent(this.unit);
}

class ChangeNearExpiryDateEvent extends NearExpiryEvent {
  final DateTime nearExpiry;

  const ChangeNearExpiryDateEvent(this.nearExpiry);
}

class ApproveItemEvent extends NearExpiryEvent {
  final String projectId;
  final String barcode;
  final String unit;
  final int qty;
  final String projectName;
  final DateTime nearExpiry;

  const ApproveItemEvent({
    required this.projectId,
    required this.barcode,
    required this.unit,
    required this.qty,
    required this.projectName,
    required this.nearExpiry,
  });
}

class ResetFormEvent extends NearExpiryEvent {
  const ResetFormEvent();
}

class SearchQueryChanged extends NearExpiryEvent {
  final String query;
  const SearchQueryChanged(this.query);
}

class ProductChosenFromSearch extends NearExpiryEvent {
  final ProductModel product;
  const ProductChosenFromSearch(this.product);
}

class SearchScannedItemsEvent extends NearExpiryEvent {
  final String query;
  SearchScannedItemsEvent(this.query);
}

class ChangeSelectedIndexEvent extends NearExpiryEvent {
  final int index;
  ChangeSelectedIndexEvent(this.index);
}

class ScannedItemSelectedEvent extends NearExpiryEvent {
  final NearExpiryItemModel item;
  ScannedItemSelectedEvent(this.item);
}

class MarkProductExistsDialogShownEvent extends NearExpiryEvent {
  const MarkProductExistsDialogShownEvent();
}

class ClearProductAlreadyExistsFlagEvent extends NearExpiryEvent {
  const ClearProductAlreadyExistsFlagEvent();
}

class UploadNearExpiryEvent extends NearExpiryEvent {
  final String projectId;
  const UploadNearExpiryEvent({required this.projectId});
}

class ExportExcelEvent extends NearExpiryEvent {
  final String projectId;
  final String projectName;
  const ExportExcelEvent(this.projectId, {required this.projectName});
}

class SendByEmailEvent extends NearExpiryEvent {
  final String projectId;
  final String projectName;
  final String branchName;

  const SendByEmailEvent({
    required this.projectId,
    required this.branchName,
    required this.projectName,
  });
}

class SetDuplicateActionEvent extends NearExpiryEvent {
  final NearDuplicateAction action;
  SetDuplicateActionEvent(this.action);
}

class UpdateMultiUnitEvent extends NearExpiryEvent {
  final String projectId;
  final String projectName;
  final StockItemGroup group;
  final Map<String, int> newUnitQty;
  final DateTime newNearExpiry;

  UpdateMultiUnitEvent({
    required this.projectId,
    required this.projectName,
    required this.group,
    required this.newUnitQty,
    required this.newNearExpiry,
  });
}

class EditSingleUnitFromListEvent extends NearExpiryEvent {
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
