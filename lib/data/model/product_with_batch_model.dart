import 'dart:convert';

class ProductWithBatchModel {
  final String itemCode;
  final String itemName;

  final List<String> barcodes; // jsonb array
  final List<String> units; // jsonb array

  final double? subunitQty; // nullable
  final bool isBatch;

  final String nearExpiryDate;

  final List<String>? batches; // nullable

  ProductWithBatchModel({
    required this.itemCode,
    required this.itemName,
    required this.barcodes,
    required this.units,
    required this.subunitQty,
    required this.isBatch,
    required this.nearExpiryDate,
    required this.batches,
  });

  factory ProductWithBatchModel.fromMap(Map<String, dynamic> map) {
    List<String> _toStringList(dynamic v) {
      if (v == null) return <String>[];
      if (v is List) return v.map((e) => e.toString()).toList();
      if (v is String) {
        final decoded = jsonDecode(v);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      }
      return <String>[];
    }

    String _dateToYmd(dynamic v) {
      if (v == null) return '';
      return v.toString().substring(0, 10);
    }

    return ProductWithBatchModel(
      itemCode: (map['item_code'] ?? '').toString(),
      itemName: (map['item_name'] ?? '').toString(),
      barcodes: _toStringList(map['barcodes']),
      units: _toStringList(map['units']),
      subunitQty: map['subunit_qty'] == null
          ? null
          : (map['subunit_qty'] as num).toDouble(),
      isBatch: (map['is_batch'] == true),
      nearExpiryDate: _dateToYmd(map['near_expiry_date']),
      batches: map['batches'] == null ? null : _toStringList(map['batches']),
    );
  }

  Map<String, dynamic> toMap() => {
    'item_code': itemCode,
    'item_name': itemName,
    'barcodes': barcodes,
    'units': units,
    'subunit_qty': subunitQty,
    'is_batch': isBatch,
    'near_expiry_date': nearExpiryDate,
    'batches': batches,
  };

  ///
  String get cacheKey => '$itemCode|$nearExpiryDate';
}
