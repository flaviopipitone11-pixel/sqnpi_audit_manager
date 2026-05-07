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
        'first_name': inspector.firstName,
        'last_name': inspector.lastName,
        'inspector_code': inspector.inspectorCode,
        'email': inspector.email,
        'phone': inspector.phone,
        'region': inspector.region,
        'is_active': inspector.isActive,
        'created_at': inspector.createdAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Errore durante il push dell\'ispettore al Cloud: $e');
      // Tentativo di fallback se le colonne nuove non esistono ancora sul server
      if (e.toString().contains('column') &&
          e.toString().contains('does not exist')) {
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
        } catch (e2) {
          debugPrint('Errore anche nel fallback push: $e2');
        }
      }
    }
  }

  /// Elimina un ispettore dal Cloud
  Future<void> deleteInspectorFromCloud(String id) async {
    try {
      final response = await _supabase
          .from('inspectors')
          .delete()
          .eq('id', id)
          .select();
      if (response.isEmpty) {
        debugPrint(
          'Attenzione: Nessun ispettore eliminato dal Cloud. Possibile blocco RLS.',
        );
      }
    } catch (e) {
      debugPrint(
        'Errore durante l\'eliminazione dell\'ispettore dal Cloud: $e',
      );
    }
  }

  /// Sincronizza i log di sistema dal Cloud al DB locale
  Future<void> syncActivityLogsWithCloud() async {
    try {
      final response = await _supabase
          .from('activity_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(500); // Fetch latest 500 logs to prevent enormous payloads

      final logs = response.map((data) {
        return ActivityLogsCompanion.insert(
          id: data['id'],
          action: data['action'],
          description: data['description'],
          actor: data['actor'],
          createdAt: DateTime.parse(data['created_at']),
        );
      }).toList();

      await _db.batch((batch) {
        batch.insertAll(
          _db.activityLogs,
          logs,
          mode: InsertMode.insertOrReplace,
        );
      });
    } catch (e) {
      debugPrint('Errore durante la sincronizzazione dei log dal Cloud: $e');
    }
  }

  /// Elimina tutti i log di sistema (sia localmente che sul Cloud)
  Future<void> clearAllActivityLogs() async {
    try {
      // Elimina dal Cloud (se RLS lo permette)
      await _supabase.from('activity_logs').delete().neq('id', '0');

      // Elimina dal DB locale
      await _db.delete(_db.activityLogs).go();
    } catch (e) {
      debugPrint('Errore durante la pulizia dei log: $e');
      rethrow;
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
          firstName: Value(json['first_name'] as String? ?? ''),
          lastName: Value(json['last_name'] as String? ?? ''),
          fullName: Value(json['full_name'] as String? ?? ''),
          inspectorCode: Value(json['inspector_code'] as String? ?? ''),
          email: Value(json['email'] as String? ?? ''),
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

      // Elimina localmente gli ispettori non più presenti sul Cloud
      final cloudIds = data.map((json) => json['id'] as String).toList();
      if (cloudIds.isNotEmpty) {
        await (_db.delete(
          _db.inspectors,
        )..where((t) => t.id.isNotIn(cloudIds))).go();
      } else {
        // Se il cloud è vuoto, svuota la tabella locale
        await _db.delete(_db.inspectors).go();
      }
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

      // Elimina localmente le aziende non più presenti sul Cloud
      final cloudCuaas = data.map((json) => json['cuaa'] as String).toList();
      if (cloudCuaas.isNotEmpty) {
        await (_db.delete(
          _db.masterCompanies,
        )..where((t) => t.cuaa.isNotIn(cloudCuaas))).go();
      } else {
        // Se il cloud è vuoto, svuota la tabella locale
        await _db.delete(_db.masterCompanies).go();
      }
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
    await _supabase.from('broadcast_messages').upsert({
      'id': message.id,
      'title': message.title,
      'message': message.message,
      'severity': message.severity,
      'target_emails': message.targetEmails,
      'created_at': message.createdAt.toIso8601String(),
    });
  }

  /// Elimina un messaggio broadcast dal Cloud e dal database locale
  Future<void> deleteBroadcastMessage(String id) async {
    // 1. Elimina da Supabase
    await _supabase.from('broadcast_messages').delete().eq('id', id);
    // 2. Elimina dal DB locale
    await (_db.delete(
      _db.broadcastMessages,
    )..where((t) => t.id.equals(id))).go();
  }

  /// Gestisce l'eliminazione avanzata di un'azienda e/o delle sue visite
  Future<void> advancedDeleteCompany(
    String cuaa, {
    required bool deleteCompany,
    required bool deleteVisits,
  }) async {
    try {
      if (deleteVisits) {
        // 1. Trova tutte le visite associate all'azienda nel Cloud
        final visitCompanies = await _supabase
            .from('visit_companies')
            .select('visit_id')
            .eq('cuaa', cuaa);

        final List<String> visitIds = visitCompanies
            .map((e) => e['visit_id'] as String)
            .toList();

        // Elimina le visite dal Cloud (il cascading si occuperà di visit_companies etc se impostato)
        if (visitIds.isNotEmpty) {
          await _supabase.from('visits').delete().inFilter('id', visitIds);
        }

        // Elimina le visite dal database locale
        final localVisitIds = await _db.getVisitIdsByCuaa(cuaa);
        await _db.deleteVisitsByIds(localVisitIds);
      }

      if (deleteCompany) {
        // Elimina l'azienda dal Cloud
        await _supabase.from('companies').delete().eq('cuaa', cuaa);

        // Elimina l'azienda localmente
        await (_db.delete(
          _db.masterCompanies,
        )..where((t) => t.cuaa.equals(cuaa))).go();
      }
    } catch (e) {
      debugPrint('Errore durante l\'eliminazione avanzata: $e');
      rethrow;
    }
  }
}
