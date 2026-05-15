import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeNavigationProvider = StateProvider<int>((ref) => 0);
final isRailExtendedProvider = StateProvider<bool>((ref) => true);
final visitFilterStatusProvider = StateProvider<int?>((ref) => null);
