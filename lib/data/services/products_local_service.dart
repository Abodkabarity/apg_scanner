import 'package:hive/hive.dart';

import '../model/products_model.dart';

class ProductsLocalService {
  static const String boxName = "products_box";

  Future<Box> _openBox() async {
    return await Hive.openBox(boxName);
  }

  /// Save all products (overwrite)
  Future<void> saveProducts(List<ProductModel> products) async {
    final box = await _openBox();

    await box.clear();

    final list = products.map((e) => e.toJson()).toList();
    await box.put("products", list);

    print("SAVED PRODUCTS LOCAL = ${products.length}");
  }

  /// Load products from local Hive
  Future<List<ProductModel>> loadProducts() async {
    final box = await _openBox();
    final data = box.get("products");

    if (data == null) {
      print("NO LOCAL PRODUCTS FOUND");
      return [];
    }

    final list = (data as List)
        .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    print("LOADED LOCAL PRODUCTS = ${list.length}");
    return list;
  }
}
