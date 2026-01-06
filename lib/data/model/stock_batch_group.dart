import 'package:equatable/equatable.dart';

class StockBatchGroup extends Equatable {
  final String itemCode;
  final String itemName;
  final String barcode;

  final String batch;
  final DateTime? nearExpiry;

  final double totalQty;
  final DateTime latestCreatedAt;

  const StockBatchGroup({
    required this.itemCode,
    required this.itemName,
    required this.barcode,
    required this.batch,
    required this.nearExpiry,
    required this.totalQty,
    required this.latestCreatedAt,
  });

  @override
  List<Object?> get props => [
    itemCode,
    itemName,
    barcode,
    batch,
    nearExpiry,
    totalQty,
    latestCreatedAt,
  ];
}
