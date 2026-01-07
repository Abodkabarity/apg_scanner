import 'dart:developer';

import '../model/product_with_batch_model.dart';
import '../remote/products_with_batch_remote_service.dart';
import '../services/products_with_batch_local_service.dart';

class ProductsWithBatchRepository {
  final ProductsWithBatchLocalService local;
  final ProductsWithBatchRemoteService remote;

  ProductsWithBatchRepository(this.local, this.remote);

  // ---------------------------------------------------------------------------
  // INTERNAL CACHE
  // ---------------------------------------------------------------------------
  bool _loaded = false;
  List<ProductWithBatchModel> _cache = [];

  /// barcode -> product
  final Map<String, ProductWithBatchModel> _barcodeIndex = {};

  /// itemCode -> rows (same product can repeat by expiry/batch)
  final Map<String, List<ProductWithBatchModel>> _byItemCode = {};

  // ---------------------------------------------------------------------------
  // BARCODE NORMALIZATION
  // ---------------------------------------------------------------------------
  String _normalizeBarcode(dynamic v) {
    return v.toString().trim().replaceAll(' ', '');
  }

  // ---------------------------------------------------------------------------
  // LOGIN WARMUP
  // ---------------------------------------------------------------------------
  Future<void> warmUpAfterLogin() async {
    final start = DateTime.now();
    final cachedCount = await local.count();
    log('[BatchProducts] cache count = $cachedCount');

    if (cachedCount > 0) {
      _runDeltaSyncInBackground(start);
      return;
    }

    _runFullDownloadInBackground(start);
  }

  List<ProductWithBatchModel> searchLocal(
    bool Function(ProductWithBatchModel) test,
  ) {
    return _cache.where(test).toList();
  }

  void _runFullDownloadInBackground(DateTime start) {
    Future<void>(() async {
      try {
        log('[BatchProducts] Full download started');

        final list = await remote.fetchAllPaged(
          pageSize: 5000,
          onProgress: (n) => log('[BatchProducts] downloading... $n rows'),
        );

        await local.saveAll(list);
        await local.setLastSync(DateTime.now().toUtc().toIso8601String());

        _buildCache(list);

        log(
          '[BatchProducts] Full download finished rows=${list.length} '
          'total=${DateTime.now().difference(start).inSeconds}s',
        );
      } catch (e, st) {
        log('[BatchProducts] Full download failed: $e');
        log(st.toString());
      }
    });
  }

  void _runDeltaSyncInBackground(DateTime start) {
    Future<void>(() async {
      try {
        final last = await local.getLastSync();
        if (last == null) {
          _runFullDownloadInBackground(start);
          return;
        }

        log('[BatchProducts] Delta sync since=$last');

        final changed = await remote.fetchChangedSince(
          sinceIso: last,
          pageSize: 5000,
          onProgress: (n) => log('[BatchProducts] delta... $n rows'),
        );

        if (changed.isEmpty) {
          await local.setLastSync(DateTime.now().toUtc().toIso8601String());
          return;
        }

        await local.saveAll(changed);
        await local.setLastSync(DateTime.now().toUtc().toIso8601String());
        await _reloadCacheFromLocal();
      } catch (e, st) {
        log('[BatchProducts] Delta sync failed: $e');
        log(st.toString());
      }
    });
  }

  // ---------------------------------------------------------------------------
  // PUBLIC API
  // ---------------------------------------------------------------------------
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await _reloadCacheFromLocal();
  }

  ProductWithBatchModel? findByBarcode(String barcode) {
    final key = _normalizeBarcode(barcode);
    return _barcodeIndex[key];
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  List<DateTime> getNearExpiriesForProduct(String itemCode) {
    final rows = _byItemCode[itemCode] ?? [];
    final Map<String, DateTime> uniq = {};

    for (final r in rows) {
      final dt = _parseDate(r.nearExpiryDate);
      if (dt == null) continue;
      uniq['${dt.year}-${dt.month}'] = DateTime(dt.year, dt.month, 1);
    }

    final list = uniq.values.toList()..sort();
    return list;
  }

  List<String> getBatchesForProductAndExpiry(String itemCode, DateTime expiry) {
    final rows = _byItemCode[itemCode] ?? [];
    final Set<String> batches = {};

    for (final r in rows) {
      final dt = _parseDate(r.nearExpiryDate);
      if (dt == null) continue;
      if (dt.year != expiry.year || dt.month != expiry.month) continue;

      for (final b in r.batches ?? []) {
        if (b.trim().isNotEmpty) batches.add(b.trim());
      }
    }

    return batches.toList()..sort();
  }

  Future<void> _reloadCacheFromLocal() async {
    final list = await local.loadAll();
    _buildCache(list);
  }

  void _buildCache(List<ProductWithBatchModel> list) {
    _cache = list;
    _barcodeIndex.clear();
    _byItemCode.clear();

    for (final p in list) {
      _byItemCode.putIfAbsent(p.itemCode, () => []);
      _byItemCode[p.itemCode]!.add(p);

      for (final b in p.barcodes) {
        final key = _normalizeBarcode(b);
        if (key.isNotEmpty) {
          _barcodeIndex[key] = p;
        }
      }
    }

    _loaded = true;
  }

  /// ✅ Get product rows by itemCode
  /// (same product can repeat by expiry / batch)
  List<ProductWithBatchModel> getByItemCode(String itemCode) {
    return _byItemCode[itemCode] ?? const [];
  }

  List<String> getUnitsForProduct(ProductWithBatchModel product) {
    return product.units.isNotEmpty ? product.units : const ['BOX'];
  }

  /// ✅ Search suggestions UNIQUE by itemCode (no duplicates in UI)
  /// ✅ Search products UNIQUE by itemCode (for search UI only)
  List<ProductWithBatchModel> searchUniqueByQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final Map<String, ProductWithBatchModel> unique = {};

    for (final p in _cache) {
      final match =
          p.itemName.toLowerCase().contains(q) ||
          p.itemCode.toLowerCase().contains(q) ||
          p.barcodes.any(
            (b) => _normalizeBarcode(b).contains(_normalizeBarcode(q)),
          );

      if (!match) continue;

      // keep only ONE row per itemCode
      unique.putIfAbsent(p.itemCode, () => p);
    }

    return unique.values.toList();
  }
}
