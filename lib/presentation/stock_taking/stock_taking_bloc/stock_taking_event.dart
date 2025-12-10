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
  final String unit;
  ChangeUnitEvent(this.unit);
}

class ApproveItemEvent extends StockEvent {
  final String projectId;
  final String barcode;
  final String unit;
  final int qty;

  ApproveItemEvent({
    required this.projectId,
    required this.barcode,
    required this.unit,
    required this.qty,
  });
}

class ResetFormEvent extends StockEvent {}
