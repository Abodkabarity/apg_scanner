import 'package:hive/hive.dart';

import '../model/product_unit_map_model.dart';

class ProductUnitLocalService {
  static const String boxName = 'product_unit_map_box';
  static const String keyItems = 'items';

  Future<Box> _open() async {
    return Hive.openBox(boxName);
  }

  Future<List<ProductUnitMapModel>> loadPending() async {
    final box = await _open();
    final raw = box.get(keyItems, defaultValue: <dynamic>[]) as List;
    return raw
        .map((e) => ProductUnitMapModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> savePending(List<ProductUnitMapModel> items) async {
    final box = await _open();
    final raw = items
        .map(
          (e) => {
            'id': e.id,
            'item_code': e.itemCode,
            'item_name': e.itemName,
            'barcode': e.barcode,
            'unit': e.unit,
            'created_at': e.createdAt.toIso8601String(),
          },
        )
        .toList();
    await box.put(keyItems, raw);
  }

  Future<void> clear() async {
    final box = await _open();
    await box.delete(keyItems);
  }
}
