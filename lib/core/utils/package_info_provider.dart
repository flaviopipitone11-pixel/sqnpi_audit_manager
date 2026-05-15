import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Provider for application package information.
/// Must be overridden in ProviderScope in main.dart.
final packageInfoProvider = Provider<PackageInfo>((ref) {
  throw UnimplementedError('packageInfoProvider must be overridden in main.dart');
});
