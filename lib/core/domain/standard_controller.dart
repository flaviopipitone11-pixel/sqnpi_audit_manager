import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/app_storage.dart';
import 'audit_standard.dart';

class StandardNotifier extends StateNotifier<AuditStandard> {
  StandardNotifier() : super(AuditStandard.sqnpi) {
    _loadSavedStandard();
  }

  static const _kSavedStandardKey = 'selected_audit_standard';

  Future<void> _loadSavedStandard() async {
    try {
      final saved = await AppStorage.read(_kSavedStandardKey);
      if (saved != null && saved.isNotEmpty) {
        state = AuditStandard.fromString(saved);
      }
    } catch (_) {}
  }

  Future<void> setStandard(
    AuditStandard standard, {
    bool persist = true,
  }) async {
    state = standard;
    if (persist) {
      try {
        await AppStorage.write(_kSavedStandardKey, standard.name);
      } catch (_) {}
    }
  }

  Future<void> clearSavedStandard() async {
    try {
      await AppStorage.delete(_kSavedStandardKey);
    } catch (_) {}
  }
}

/// Provider globale per lo standard attualmente selezionato (SQNPI / BIO).
final currentStandardProvider =
    StateNotifierProvider<StandardNotifier, AuditStandard>((ref) {
      return StandardNotifier();
    });
