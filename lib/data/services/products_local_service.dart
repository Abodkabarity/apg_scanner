import 'package:hive/hive.dart';

import '../../core/di/injection.dart';
import '../../core/session/user_session.dart';
import '../model/products_model.dart';

class ProductsLocalService {
  Future<Box> _openBox() async {
    final userId = getIt<UserSession>().userId;

    if (userId == null || userId.isEmpty) {
      throw Exception("User not logged in - userId is null");
    }

    final boxName = "products_box_$userId";
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
