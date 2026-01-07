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

  // ---------------------------------------------------------------------------
  // FACTORY
  // ---------------------------------------------------------------------------
  factory ProductWithBatchModel.fromMap(Map<String, dynamic> map) {
    List<String> _toStringList(dynamic v) {
      try {
        if (v == null) return <String>[];

        if (v is List) {
          return v.map((e) => e.toString()).toList();
        }

        if (v is String && v.isNotEmpty) {
          final decoded = jsonDecode(v);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        }
      } catch (_) {
        // ignore invalid json
      }
      return <String>[];
    }

    String _safeDate(dynamic v) {
      if (v == null) return '';
      final s = v.toString();
      if (s.isEmpty) return '';
      return s.length >= 10 ? s.substring(0, 10) : s;
    }

    return ProductWithBatchModel(
      itemCode: (map['item_code'] ?? '').toString(),
      itemName: (map['item_name'] ?? '').toString(),

      barcodes: _toStringList(map['barcodes']),
      units: _toStringList(map['units']),

      subunitQty: map['subunit_qty'] == null
          ? null
          : (map['subunit_qty'] as num).toDouble(),

      isBatch: map['is_batch'] == true,

      nearExpiryDate: _safeDate(map['near_expiry_date']),

      batches: map['batches'] == null ? null : _toStringList(map['batches']),
    );
  }

  // ---------------------------------------------------------------------------
  // MAP
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // CACHE
  // ---------------------------------------------------------------------------
  String get cacheKey => '$itemCode|$nearExpiryDate';
}
