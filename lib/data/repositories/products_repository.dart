import 'dart:async';

import '../model/products_model.dart';
import '../remote/products_remote_service.dart';
import '../services/products_local_service.dart';

class ProductsRepository {
  final ProductsLocalService local;
  final ProductsRemoteService remote;

  List<ProductModel> _products = [];
  Map<String, List<String>> unitIndex = {};

  // =====================================================
  // 🔔 CHANGE NOTIFIER (VERY IMPORTANT)
  // =====================================================
  final StreamController<int> _revisionController =
      StreamController<int>.broadcast();
  int _revision = 0;

  Stream<int> get revisionStream => _revisionController.stream;

  void _notifyChanged() {
    _revision++;
    _revisionController.add(_revision);
    print("📢 ProductsRepository changed → revision=$_revision");
  }

  // =====================================================
  ProductsRepository({required this.local, required this.remote});

  List<ProductModel> get products => _products;

  // =====================================================
  // Load products from Hive
  // =====================================================
  Future<List<ProductModel>> getAllLocal() async {
    _products = await local.loadProducts();
    print("LOADED LOCAL PRODUCTS = ${_products.length}");
    _buildUnitIndex();

    _notifyChanged(); // ✅ IMPORTANT
    return _products;
  }

  // =====================================================
  // Sync from server with pagination
  // =====================================================
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

    _notifyChanged(); // ✅ IMPORTANT
    print("SYNC DONE");
  }

  // =====================================================
  Future<void> ensureLoaded() async {
    if (_products.isNotEmpty) {
      print("Products already in memory, skip loading.");
      return;
    }

    // Try load from Hive
    final localList = await getAllLocal();

    if (localList.isNotEmpty) {
      print("Using local Hive products.");
      return;
    }

    print("No local products, doing first sync from Supabase...");
    await syncProducts();
  }

  // =====================================================
  void _buildUnitIndex() {
    unitIndex.clear();

    for (final p in _products) {
      final Set<String> units = {};

      units.add('Box');

      if (p.unit.isNotEmpty) {
        final u = _normalizeUnit(p.unit);
        if (u.toLowerCase() != 'box') {
          units.add(u);
        }
      }

      if (p.subUnit.isNotEmpty) {
        units.add(_normalizeUnit(p.subUnit));
      }

      unitIndex[p.itemCode] = units.toList();
    }

    print("Unit Index Built → ${unitIndex.length} products");
  }

  // =====================================================
  String _normalizeUnit(String u) {
    u = u.trim();
    if (u.isEmpty) return "";

    return u[0].toUpperCase() + u.substring(1).toLowerCase();
  }

  String normalize(String value) {
    value = value.trim().toLowerCase();
    if (value.isEmpty) return "";
    return value[0].toUpperCase() + value.substring(1);
  }

  // =====================================================
  // Search product by barcode
  // =====================================================
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

  // =====================================================
  void mergeUpdatedProducts(List<ProductModel> updates) {
    final map = {for (var p in _products) p.id: p};

    for (var u in updates) {
      map[u.id] = u;
    }

    _products = map.values.toList();
    _buildUnitIndex();

    _notifyChanged(); // ✅ IMPORTANT
  }

  void setProducts(List<ProductModel> list) {
    _products = list;
    _buildUnitIndex();

    _notifyChanged(); // ✅ IMPORTANT
  }

  // =====================================================
  void dispose() {
    _revisionController.close();
  }
}
