import 'package:hive/hive.dart';

part 'stock_taking_model.g.dart';

@HiveType(typeId: 5)
class StockItemModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String projectId;

  @HiveField(2)
  final String branchName;

  @HiveField(3)
  final String itemId;

  @HiveField(4)
  final String itemCode;

  @HiveField(5)
  final String itemName;

  @HiveField(6)
  final String unit;

  @HiveField(7)
  final String subUnit;

  @HiveField(8)
  final int quantity;

  @HiveField(9)
  final num subQuantity;

  @HiveField(10)
  final String barcode;

  @HiveField(11)
  final bool isDeleted;

  @HiveField(12)
  final bool isSynced;

  @HiveField(13)
  final DateTime createdAt;

  @HiveField(14)
  final DateTime updatedAt;

  StockItemModel({
    required this.id,
    required this.projectId,
    required this.branchName,
    required this.itemId,
    required this.itemCode,
    required this.itemName,
    required this.unit,
    required this.subUnit,
    required this.quantity,
    required this.subQuantity, // 👈 تمت إضافته
    required this.barcode,
    required this.isDeleted,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
  });

  StockItemModel copyWith({
    String? id,
    String? projectId,
    String? branchName,
    String? itemId,
    String? itemCode,
    String? itemName,
    String? unit,
    String? subUnit,
    int? quantity,
    num? subQuantity,
    String? barcode,
    bool? isDeleted,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StockItemModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      branchName: branchName ?? this.branchName,
      itemId: itemId ?? this.itemId,
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      unit: unit ?? this.unit,
      subUnit: subUnit ?? this.subUnit,
      quantity: quantity ?? this.quantity,
      subQuantity: subQuantity ?? this.subQuantity, // 👈 تمت إضافته
      barcode: barcode ?? this.barcode,
      isDeleted: isDeleted ?? this.isDeleted,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory StockItemModel.fromJson(Map<String, dynamic> json) {
    return StockItemModel(
      id: json['id'],
      projectId: json['project_name'],
      branchName: json['branch_name'] ?? '',
      itemId: json['item_id'],
      itemCode: json['item_code'],
      itemName: json['item_name'],
      unit: json['unit'] ?? '',
      subUnit: json['subunit'] ?? '',
      quantity: json['quantity'] ?? 0,
      subQuantity: json['sub_quantity'] ?? 0, // 👈 تمت إضافته
      barcode: json['barcode'] ?? '',
      isDeleted: json['is_deleted'] ?? false,
      isSynced: json['is_synced'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_name': projectId,
      'branch_name': branchName,
      'item_id': itemId,
      'item_code': itemCode,
      'item_name': itemName,
      'unit': unit,
      'subunit': subUnit,
      'quantity': quantity,
      'sub_quantity': subQuantity, // 👈 تمت إضافته
      'barcode': barcode,
      'is_deleted': isDeleted,
      'is_synced': isSynced,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
