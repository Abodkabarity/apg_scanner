class ProductUnitMapModel {
  final String id;
  final String itemCode;
  final String itemName;
  final String barcode;
  final String unit;
  final DateTime createdAt;

  ProductUnitMapModel({
    required this.id,
    required this.itemCode,
    required this.itemName,
    required this.barcode,
    required this.unit,
    required this.createdAt,
  });

  factory ProductUnitMapModel.fromJson(Map<String, dynamic> json) {
    return ProductUnitMapModel(
      id: (json['id'] ?? '').toString(),
      itemCode: (json['item_code'] ?? '').toString(),
      itemName: (json['item_name'] ?? '').toString(),
      barcode: (json['barcode'] ?? '').toString(),
      unit: (json['unit_type'] ?? '').toString(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({String? createdBy}) {
    return {
      'item_code': itemCode,
      'item_name': itemName,
      'barcode': barcode,
      'unit_type': unit,
      if (createdBy != null) 'created_by': createdBy,
    };
  }

  String get key => '$itemCode|$barcode|$unit';
}
