import 'package:equatable/equatable.dart';

class StockItemGroup extends Equatable {
  final String itemCode;
  final String itemName;
  final String barcode;
  final DateTime latestCreatedAt;
  final DateTime? nearExpiry;

  final double totalSubQty;
  final int totalDisplayQty;

  final Map<String, int> unitQty;
  final Map<String, String> unitId;

  const StockItemGroup({
    required this.itemCode,
    required this.itemName,
    required this.barcode,
    required this.totalSubQty,
    required this.totalDisplayQty,
    required this.unitQty,
    required this.unitId,
    required this.latestCreatedAt,
    this.nearExpiry,
  });

  bool get isMultiUnit => unitQty.length > 1;

  @override
  List<Object?> get props => [
    itemCode,
    nearExpiry,

    totalSubQty,

    totalDisplayQty,

    unitQty,
    unitId,
  ];
}
