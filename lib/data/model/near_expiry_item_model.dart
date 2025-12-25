import 'package:hive/hive.dart';

part 'near_expiry_item_model.g.dart';

@HiveType(typeId: 6)
class NearExpiryItemModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String projectId;

  @HiveField(2)
  final String projectName;

  @HiveField(3)
  final String branchName;

  @HiveField(4)
  final String barcode;

  @HiveField(5)
  final String itemCode;

  @HiveField(6)
  final String itemName;

  @HiveField(7)
  final String unitType;

  @HiveField(8)
  final int quantity;

  @HiveField(9)
  final DateTime nearExpiry;

  @HiveField(10)
  final bool isDeleted;

  @HiveField(11)
  final bool isSynced;

  @HiveField(12)
  final DateTime createdAt;

  @HiveField(13)
  final DateTime updatedAt;

  NearExpiryItemModel({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.branchName,
    required this.barcode,
    required this.itemCode,
    required this.itemName,
    required this.unitType,
    required this.quantity,
    required this.nearExpiry,
    required this.isDeleted,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
  });

  NearExpiryItemModel copyWith({
    String? id,
    String? projectId,
    String? projectName,
    String? branchName,
    String? barcode,
    String? itemCode,
    String? itemName,
    String? unitType,
    int? quantity,
    DateTime? nearExpiry,
    bool? isDeleted,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NearExpiryItemModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      branchName: branchName ?? this.branchName,
      barcode: barcode ?? this.barcode,
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      unitType: unitType ?? this.unitType,
      quantity: quantity ?? this.quantity,
      nearExpiry: nearExpiry ?? this.nearExpiry,
      isDeleted: isDeleted ?? this.isDeleted,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory NearExpiryItemModel.fromJson(Map<String, dynamic> json) {
    return NearExpiryItemModel(
      id: json['id'],
      projectId: json['project_id'],
      projectName: json['project_name'] ?? 'New Project',
      branchName: json['branch_name'] ?? '',
      barcode: json['barcode'] ?? '',
      itemCode: json['item_code'],
      itemName: json['item_name'],
      unitType: json['unit_type'],
      quantity: json['qty'] ?? 0,
      nearExpiry: DateTime.parse(json['near_expiry']),
      isDeleted: json['is_deleted'] ?? false,
      isSynced: json['is_synced'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'project_name': projectName,
      'branch_name': branchName,
      'barcode': barcode,
      'item_code': itemCode,
      'item_name': itemName,
      'unit_type': unitType,
      'qty': quantity,
      'near_expiry': nearExpiry.toIso8601String(),
      'is_deleted': isDeleted,
      'is_synced': isSynced,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
