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
  // BARCODE NORMALIZATION (🔥 مهم جداً)
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
          log('[BatchProducts] delta: no changes');
          return;
        }

        await local.saveAll(changed);
        await local.setLastSync(DateTime.now().toUtc().toIso8601String());
        await _reloadCacheFromLocal();

        log(
          '[BatchProducts] delta saved rows=${changed.length} '
          'total=${DateTime.now().difference(start).inSeconds}s',
        );
      } catch (e, st) {
        log('[BatchProducts] Delta sync failed: $e');
        log(st.toString());
      }
    });
  }

  // ---------------------------------------------------------------------------
  // PUBLIC API (USED BY BLOCS)
  // ---------------------------------------------------------------------------

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await _reloadCacheFromLocal();
  }

  ProductWithBatchModel? findByBarcode(String barcode) {
    final key = _normalizeBarcode(barcode);

    log('[BatchProducts] LOOKUP BARCODE = [$key]');
    log(
      '[BatchProducts] INDEX SAMPLE = ${_barcodeIndex.keys.take(5).toList()}',
    );

    if (key.isEmpty) return null;
    return _barcodeIndex[key];
  }

  /// Convert string date safely to DateTime
  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  /// Near expiry list (DateTime) for product
  List<DateTime> getNearExpiriesForProduct(String itemCode) {
    final rows = _byItemCode[itemCode] ?? [];
    final Map<String, DateTime> uniq = {};

    for (final r in rows) {
      final dt = _parseDate(r.nearExpiryDate);
      if (dt == null) continue;

      final key = '${dt.year}-${dt.month}-${dt.day}';
      uniq[key] = DateTime(dt.year, dt.month, dt.day);
    }

    final list = uniq.values.toList();
    list.sort();
    return list;
  }

  List<String> getBatchesForProductAndExpiry(String itemCode, DateTime expiry) {
    final rows = _byItemCode[itemCode] ?? [];
    final Set<String> uniqueBatches = {};

    bool sameMonth(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month;

    for (final r in rows) {
      final DateTime? dt = _parseDate(r.nearExpiryDate);
      if (dt == null) continue;
      if (!sameMonth(dt, expiry)) continue;

      final List<String> batches = r.batches ?? const [];
      for (final b in batches) {
        final v = b.trim();
        if (v.isNotEmpty) {
          uniqueBatches.add(v);
        }
      }
    }

    final list = uniqueBatches.toList()..sort();
    return list;
  }

  // ---------------------------------------------------------------------------
  // CACHE BUILDERS
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // OPTIONAL
  // ---------------------------------------------------------------------------
  Future<List<ProductWithBatchModel>> loadCachedProducts() {
    return local.loadAll();
  }

  Future<List<ProductWithBatchModel>> searchByItemCode(String code) async {
    final all = await local.loadAll();
    return all.where((p) => p.itemCode == code).toList();
  }

  List<String> getUnitsForProduct(ProductWithBatchModel product) {
    if (product.units.isNotEmpty) {
      return product.units;
    }
    return const ['BOX'];
  }
}
