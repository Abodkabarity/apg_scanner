import '../model/products_model.dart';
import '../remote/products_remote_service.dart';
import '../services/products_local_service.dart';

class ProductsRepository {
  final ProductsLocalService local;
  final ProductsRemoteService remote;

  List<ProductModel> _products = [];
  Map<String, List<String>> unitIndex = {};

  ProductsRepository({required this.local, required this.remote});

  List<ProductModel> get products => _products;

  /// Load products from Hive
  Future<List<ProductModel>> getAllLocal() async {
    _products = await local.loadProducts();
    print("LOADED LOCAL PRODUCTS = ${_products.length}");
    _buildUnitIndex();
    return _products;
  }

  /// Sync from server with pagination
  Future<void> syncProducts() async {
    print("FETCHING FROM SUPABASE WITH PAGINATION...");

    List<ProductModel> remoteList = [];
    const int pageSize = 1000;
    int from = 0;
    int to = pageSize - 1;

    while (true) {
      final batch = await remote.fetchRange(from, to);
      print("Fetched batch = ${batch.length}");

      if (batch.isEmpty) break;
      remoteList.addAll(batch);

      from += pageSize;
      to += pageSize;
    }

    print("REMOTE COUNT = ${remoteList.length}");

    // Save to local Hive
    await local.saveProducts(remoteList);
    _products = remoteList;
    _buildUnitIndex();
    print("SYNC DONE");
  }

  Future<void> ensureLoaded() async {
    if (_products.isNotEmpty) {
      print("Products already in memory, skip loading.");
      return;
    }

    // جرّب تحمل من Hive
    final local = await getAllLocal();

    if (local.isNotEmpty) {
      print("Using local Hive products.");
      return;
    }

    print("No local products, doing first sync from Supabase...");
    await syncProducts();
  }

  void _buildUnitIndex() {
    unitIndex.clear();

    for (final p in _products) {
      final List<String> units = [];

      if (p.unit.isNotEmpty) units.add(p.unit);
      if (p.subUnit.isNotEmpty) units.add(p.subUnit);

      unitIndex[p.itemCode] = units;
      print("BUILD: ${p.itemCode} -> ${p.unit}, ${p.subUnit}");
    }

    print("Unit Index Built → ${unitIndex.length} products");
  }

  /// Search product by barcode (Sync lookup)
  ProductModel? findByBarcode(String barcode) {
    if (_products.isEmpty) {
      print("WARNING: PRODUCTS LIST IS EMPTY — Did you call ensureLoaded?");
    }

    for (final p in _products) {
      if (p.barcodes.contains(barcode)) {
        return p;
      }
    }
    return null;
  }

  List<String> getUnitsForProduct(ProductModel p) {
    return unitIndex[p.itemCode] ?? [];
  }
}
