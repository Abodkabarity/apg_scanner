class StockItemGroup {
  final String itemCode;
  final String itemName;
  final String barcode;
  final DateTime latestCreatedAt;

  final double totalSubQty;
  final int totalDisplayQty;

  final Map<String, int> unitQty;
  final Map<String, String> unitId;

  StockItemGroup({
    required this.itemCode,
    required this.itemName,
    required this.barcode,
    required this.totalSubQty,
    required this.totalDisplayQty,
    required this.unitQty,
    required this.unitId,
    required this.latestCreatedAt,
  });

  bool get isMultiUnit => unitQty.length > 1;
}
