import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AdminRepository(db);
});

class AdminRepository {
  final AppDatabase _db;
  final _supabase = Supabase.instance.client;
  AdminRepository(this._db);

  /// Carica un singolo ispettore sul Cloud (usato per aggiunte manuali admin)
  Future<void> pushInspectorToCloud(Inspector inspector) async {
    try {
      await _supabase.from('inspectors').upsert({
        'id': inspector.id,
        'full_name': inspector.fullName,
        'email': inspector.email,
        'phone': inspector.phone,
        'region': inspector.region,
        'is_active': inspector.isActive,
        'created_at': inspector.createdAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Errore durante il push dell\'ispettore al Cloud: $e');
    }
  }

  /// Sincronizza la lista degli ispettori dal Cloud al DB locale
  Future<void> syncInspectorsWithCloud() async {
    try {
      final response = await _supabase
          .from('inspectors')
          .select()
          .order('full_name', ascending: true);

      final List<dynamic> data = response;

      if (data.isEmpty) return;

      // Trasforma i dati in oggetti Drift
      final inspectors = data.map((json) {
        return InspectorsCompanion.insert(
          id: json['id'] as String,
          fullName: Value(json['full_name'] as String),
          email: Value(json['email'] as String),
          phone: Value(json['phone'] as String? ?? ''),
          region: Value(json['region'] as String? ?? ''),
          isActive: Value(json['is_active'] as bool? ?? false),
          createdAt: json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
        );
      }).toList();

      // Upsert massivo nel DB locale
      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.inspectors, inspectors);
      });
    } catch (e) {
      // Logga l'errore ma non bloccare l'app
      debugPrint('Errore durante la sincronizzazione ispettori: $e');
    }
  }

  /// Sincronizza la lista delle aziende dal Cloud al DB locale
  Future<void> syncCompaniesWithCloud() async {
    try {
      final response = await _supabase
          .from('companies')
          .select()
          .order('ragione_sociale', ascending: true);

      final List<dynamic> data = response;
      if (data.isEmpty) return;

      final companions = data.map((json) {
        return MasterCompaniesCompanion.insert(
          cuaa: json['cuaa'] as String,
          ragioneSociale: Value(json['ragione_sociale'] as String),
          email: Value(json['email'] as String? ?? ''),
          telefono: Value(json['telefono'] as String? ?? ''),
          indirizzo: Value(json['indirizzo'] as String? ?? ''),
          comune: Value(json['comune'] as String? ?? ''),
          provincia: Value(json['provincia'] as String? ?? ''),
          cap: Value(json['cap'] as String? ?? ''),
          latitude: Value(
            json['latitude'] != null
                ? (json['latitude'] as num).toDouble()
                : null,
          ),
          longitude: Value(
            json['longitude'] != null
                ? (json['longitude'] as num).toDouble()
                : null,
          ),
          updatedAt: json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : DateTime.now(),
        );
      }).toList();

      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.masterCompanies, companions);
      });
    } catch (e) {
      debugPrint('Errore durante la sincronizzazione aziende: $e');
    }
  }

  /// Carica un'azienda sul Cloud
  Future<void> pushCompanyToCloud(MasterCompany company) async {
    try {
      await _supabase.from('companies').upsert({
        'cuaa': company.cuaa,
        'ragione_sociale': company.ragioneSociale,
        'email': company.email,
        'telefono': company.telefono,
        'indirizzo': company.indirizzo,
        'comune': company.comune,
        'provincia': company.provincia,
        'cap': company.cap,
        'latitude': company.latitude,
        'longitude': company.longitude,
        'updated_at': company.updatedAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Errore durante il push dell\'azienda al Cloud: $e');
    }
  }

  /// Invia un messaggio broadcast al Cloud
  Future<void> pushBroadcastMessageToCloud(BroadcastMessage message) async {
    try {
      await _supabase.from('broadcast_messages').upsert({
        'id': message.id,
        'title': message.title,
        'message': message.message,
        'severity': message.severity,
        'target_emails': message.targetEmails,
        'created_at': message.createdAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Errore durante il push del messaggio broadcast: $e');
    }
  }
}
