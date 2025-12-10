class ProductModel {
  final String id;
  final String itemCode;
  final List<String> barcodes;
  final String itemName;
  final String unit;
  final String subUnit;
  final bool useBatch;
  final bool useExpiry;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.itemCode,
    required this.barcodes,
    required this.itemName,
    required this.unit,
    required this.subUnit,
    required this.useBatch,
    required this.useExpiry,
    required this.updatedAt,
  });

  // -------------------------
  // باركود ذكي يقبل أي نوع
  // -------------------------
  static List<String> _parseBarcodes(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    if (value is int) {
      return [value.toString()];
    }

    if (value is String) {
      if (value.contains(",")) {
        return value.split(",").map((e) => e.trim()).toList();
      }
      return [value];
    }

    return [];
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: (json['id'] ?? "").toString(),
      itemCode: (json['item_code'] ?? "").toString(),
      barcodes: _parseBarcodes(json['barcodes']),
      itemName: (json['item_name'] ?? "").toString(),
      unit: (json['unit'] ?? "").toString(),
      subUnit: (json['subunit'] ?? "").toString(),

      // smart bool handling
      useBatch: json['use_batch'] is bool
          ? json['use_batch']
          : json['use_batch'] == "true",

      useExpiry: json['use_expiry'] is bool
          ? json['use_expiry']
          : json['use_expiry'] == "true",

      updatedAt: DateTime.tryParse(json['updated_at'] ?? "") ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_code': itemCode,
      'barcodes': barcodes,
      'item_name': itemName,
      'unit': unit,
      'subunit': subUnit,
      'use_batch': useBatch,
      'use_expiry': useExpiry,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
