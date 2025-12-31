import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/di/injection.dart';
import '../../presentation/stock_taking/stock_taking_bloc/stock_taking_bloc.dart';
import '../../presentation/stock_taking/stock_taking_bloc/stock_taking_event.dart';
import '../model/products_model.dart';
import '../repositories/products_repository.dart';

class ProductsSyncService {
  final ProductsRepository repo;
  final SupabaseClient client;

  RealtimeChannel? _subscription;
  bool _started = false;

  ProductsSyncService(this.repo, this.client);

  // ======================================================
  // INITIAL SYNC
  // ======================================================
  Future<void> initialSync() async {
    if (_started) return;
    _started = true;

    print("INITIAL SYNC STARTED");

    // 1) Load local Hive data
    await repo.getAllLocal();

    if (repo.products.isNotEmpty) {
      print("📦 Local cache found: ${repo.products.length} products");
      print("🔄 Doing DELTA SYNC only...");
      await syncDelta();
    } else {
      print("❌ Local cache empty. Doing FULL SYNC...");
      await fullSync();
    }

    // 🔔 Notify UI that products are ready
    _notifyProductsUpdated();

    // 🔌 Start realtime listener
    subscribeRealtime();
  }

  // ======================================================
  // FULL SYNC (FIRST RUN)
  // ======================================================
  Future<void> fullSync() async {
    print("START FULL SYNC...");

    final remoteProducts = await fetchAllPaged();

    await repo.local.saveProducts(remoteProducts);
    repo.setProducts(remoteProducts);

    print("FULL SYNC COMPLETED: ${remoteProducts.length} products");
  }

  // ======================================================
  // DELTA SYNC
  // ======================================================
  Future<void> syncDelta() async {
    if (repo.products.isEmpty) return;

    repo.products.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final lastUpdated = repo.products.first.updatedAt;

    print("⏱ Last updated at: $lastUpdated");

    final response = await client
        .from('products')
        .select()
        .gt('updated_at', lastUpdated.toIso8601String());

    if (response.isEmpty) {
      print("No delta updates.");
      return;
    }

    print("📥 DELTA RECEIVED = ${response.length}");

    final updates = response.map((e) => ProductModel.fromJson(e)).toList();

    repo.mergeUpdatedProducts(updates);
    await repo.local.saveProducts(repo.products);

    print("💾 Hive updated (delta), total = ${repo.products.length}");
  }

  // ======================================================
  // PAGINATION FETCH
  // ======================================================
  Future<List<ProductModel>> fetchAllPaged() async {
    print("START PAGINATION FETCH...");

    List<ProductModel> all = [];
    const int pageSize = 1000;
    int from = 0;
    int to = pageSize - 1;

    while (true) {
      final batch = await client
          .from('products')
          .select()
          .order('id', ascending: true)
          .range(from, to);

      if (batch.isEmpty) break;

      all.addAll(batch.map((e) => ProductModel.fromJson(e)).toList());

      print("Loaded: ${all.length}");

      from += pageSize;
      to += pageSize;
    }

    print("FINISHED PAGINATION FETCH → TOTAL = ${all.length}");
    return all;
  }

  // ======================================================
  // REALTIME LISTENER (FINAL FIX)
  // ======================================================
  void subscribeRealtime() {
    _subscription?.unsubscribe();

    final channel = client.channel('public:products');

    print("🔌 Activating realtime listener...");

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'products',
      callback: (payload) async {
        try {
          print("REALTIME UPDATE: ${payload.eventType}");

          final record = payload.newRecord;
          if (record.isEmpty) return;

          final productId = record['id'];
          if (productId == null) return;

          // 🔥 IMPORTANT:
          // Re-fetch FULL product (Realtime payload is NOT reliable)
          final full = await client
              .from('products')
              .select()
              .eq('id', productId)
              .single();

          final product = ProductModel.fromJson(
            Map<String, dynamic>.from(full),
          );

          repo.mergeUpdatedProducts([product]);
          await repo.local.saveProducts(repo.products);

          _notifyProductsUpdated();

          print("✔ FULL PRODUCT UPDATED via REALTIME");
        } catch (e) {
          print("❌ REALTIME ERROR: $e");
        }
      },
    );

    channel.subscribe();
    _subscription = channel;

    print("REALTIME SYNC ACTIVATED");
  }

  // ======================================================
  // NOTIFY UI
  // ======================================================
  void _notifyProductsUpdated() {
    if (getIt.isRegistered<StockBloc>()) {
      getIt<StockBloc>().add(ProductsRepoUpdatedEvent());
    }
  }

  // ======================================================
  // CLEANUP
  // ======================================================
  void dispose() {
    _subscription?.unsubscribe();
  }
}
