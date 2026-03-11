import 'dart:io';

import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

final mapCacheStoreProvider = FutureProvider<CacheStore>((ref) async {
  final dir = await getApplicationSupportDirectory();
  final cachePath = p.join(dir.path, 'map_tiles_cache');
  final cacheDir = Directory(cachePath);
  if (!cacheDir.existsSync()) {
    cacheDir.createSync(recursive: true);
  }
  return FileCacheStore(cachePath);
});

final mapCacheOptionsProvider = FutureProvider<CacheOptions>((ref) async {
  final store = await ref.watch(mapCacheStoreProvider.future);
  return CacheOptions(
    store: store,
    policy: CachePolicy.forceCache, // Prefer cache for offline usage
    hitCacheOnErrorExcept: [401, 403],
    maxStale: const Duration(days: 30), // Keep tiles for 30 days
    priority: CachePriority.high,
  );
});
