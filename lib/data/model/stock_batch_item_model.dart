class StockBatchItemModel {
  final String id;

  final String projectId;
  final String projectName;
  final String branchName;
  final double? subUnitQty;

  final String itemCode;
  final String itemName;
  final String barcode;

  final String unitType; // column: unit
  final double quantity; // column: qty

  final DateTime? nearExpiry; // optional
  final String? batch; // optional

  final bool isSynced;
  final bool isDeleted;

  final DateTime createdAt;

  const StockBatchItemModel({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.branchName,
    required this.itemCode,
    required this.itemName,
    required this.barcode,
    required this.unitType,
    required this.quantity,
    required this.nearExpiry,
    required this.batch,
    required this.isSynced,
    required this.isDeleted,
    required this.createdAt,
    this.subUnitQty,
  });

  StockBatchItemModel copyWith({
    String? id,
    String? projectId,
    String? projectName,
    String? branchName,
    String? itemCode,
    String? itemName,
    String? barcode,
    String? unitType,
    double? quantity,
    DateTime? nearExpiry,
    String? batch,
    bool? isSynced,
    bool? isDeleted,
    double? subUnitQty,

    DateTime? createdAt,
    bool clearNearExpiry = false,
    bool clearBatch = false,
  }) {
    return StockBatchItemModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      branchName: branchName ?? this.branchName,
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      barcode: barcode ?? this.barcode,
      unitType: unitType ?? this.unitType,
      quantity: quantity ?? this.quantity,
      nearExpiry: clearNearExpiry ? null : (nearExpiry ?? this.nearExpiry),
      batch: clearBatch ? null : (batch ?? this.batch),
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      subUnitQty: subUnitQty ?? this.subUnitQty,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'project_id': projectId,
    'project_name': projectName,
    'branch_name': branchName,
    'item_code': itemCode,
    'item_name': itemName,
    'barcode': barcode,
    'unit': unitType,
    'qty': quantity,
    'sub_unit_qty': subUnitQty,

    'near_expiry': nearExpiry?.toIso8601String(),
    'batch': batch,
    'is_synced': isSynced,
    'is_deleted': isDeleted,
    'created_at': createdAt.toIso8601String(),
  };

  factory StockBatchItemModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return StockBatchItemModel(
      id: (json['id'] ?? '').toString(),
      projectId: (json['project_id'] ?? '').toString(),
      projectName: (json['project_name'] ?? '').toString(),
      branchName: (json['branch_name'] ?? '').toString(),
      itemCode: (json['item_code'] ?? '').toString(),
      itemName: (json['item_name'] ?? '').toString(),
      barcode: (json['barcode'] ?? '').toString(),
      unitType: (json['unit'] ?? json['unit_type'] ?? '').toString(),
      quantity: (json['qty'] is num)
          ? (json['qty'] as num).toDouble()
          : double.tryParse((json['qty'] ?? '0').toString()) ?? 0.0,
      subUnitQty: (json['sub_unit_qty'] is num)
          ? (json['sub_unit_qty'] as num).toDouble()
          : double.tryParse('${json['sub_unit_qty']}'),

      nearExpiry: parseDt(json['near_expiry']),
      batch: json['batch']?.toString(),
      isSynced: json['is_synced'] == true,
      isDeleted: json['is_deleted'] == true,
      createdAt: parseDt(json['created_at']) ?? DateTime.now(),
    );
  }
}
