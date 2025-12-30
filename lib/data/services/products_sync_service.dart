import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/products_model.dart';
import '../repositories/products_repository.dart';

class ProductsSyncService {
  final ProductsRepository repo;
  final SupabaseClient client;

  RealtimeChannel? _subscription;

  ProductsSyncService(this.repo, this.client);

  Future<void> initialSync() async {
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

    subscribeRealtime();
  }

  /// ======================================================
  /// FULL SYNC (FIRST RUN ONLY)
  /// ======================================================
  Future<void> fullSync() async {
    print("START FULL SYNC...");

    final remoteProducts = await fetchAllPaged();

    await repo.local.saveProducts(remoteProducts);
    repo.setProducts(remoteProducts);

    print("FULL SYNC COMPLETED: ${remoteProducts.length} products");
  }

  /// ======================================================
  /// DELTA SYNC (UPDATED ITEMS ONLY)
  /// ======================================================
  Future<void> syncDelta() async {
    if (repo.products.isEmpty) return;

    // Get last updated time
    repo.products.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final lastUpdated = repo.products.first.updatedAt;

    print("⏱ Last updated at: $lastUpdated");

    final response = await client
        .from("products")
        .select()
        .gt("updated_at", lastUpdated.toIso8601String());

    if (response.isEmpty) {
      print("No delta updates.");
      return;
    }

    print("📥 DELTA RECEIVED = ${response.length}");

    final updates = response.map((e) => ProductModel.fromJson(e)).toList();

    repo.mergeUpdatedProducts(updates);

    await repo.local.saveProducts(repo.products);

    print(
      "💾 Hive saved updated products, new total = ${repo.products.length}",
    );
  }

  /// ======================================================
  /// PAGINATION FETCH (20K+ ITEMS)
  /// ======================================================
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

      final mapped = batch.map((e) => ProductModel.fromJson(e)).toList();

      all.addAll(mapped);

      print("Loaded: ${all.length}");

      from += pageSize;
      to += pageSize;
    }

    print("FINISHED PAGINATION FETCH → TOTAL = ${all.length}");
    return all;
  }

  /// ======================================================
  /// REALTIME LISTENER
  /// ======================================================
  void subscribeRealtime() {
    _subscription?.unsubscribe();

    final channel = client.channel('public:products');

    print("🔌 Activating realtime listener...");

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'products',
      callback: (payload) async {
        print("REALTIME UPDATE: ${payload.eventType}");

        final data = payload.newRecord;

        final product = ProductModel.fromJson(Map<String, dynamic>.from(data));

        repo.mergeUpdatedProducts([product]);
        await repo.local.saveProducts(repo.products);

        print("✔ LOCAL PRODUCT UPDATED via REALTIME");
      },
    );

    channel.subscribe();
    _subscription = channel;

    print("REALTIME SYNC ACTIVATED");
  }

  void dispose() {
    _subscription?.unsubscribe();
  }
}
