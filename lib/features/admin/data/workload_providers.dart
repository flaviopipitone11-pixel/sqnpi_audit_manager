import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/storage/db_providers.dart';
import '../domain/inspector_workload.dart';

final inspectorsWorkloadProvider =
    StreamProvider.autoDispose<List<InspectorWorkload>>((ref) {
      final db = ref.watch(appDatabaseProvider);

      final inspectorsStream = (db.select(
        db.inspectors,
      )..orderBy([(t) => OrderingTerm.asc(t.fullName)])).watch();
      final visitsStream = db.select(db.visits).watch();

      return inspectorsStream.asyncMap((inspectors) async {
        final visits = await visitsStream.first;

        return inspectors.map((inspector) {
          final inspectorVisits = visits
              .where((v) => v.inspectorName == inspector.fullName)
              .toList();

          final planned = inspectorVisits.where((v) => v.status == 0).length;
          final inProgress = inspectorVisits.where((v) => v.status == 1).length;
          final completed = inspectorVisits.where((v) => v.status >= 2).length;

          return InspectorWorkload(
            inspector: inspector,
            plannedCount: planned,
            inProgressCount: inProgress,
            completedCount: completed,
          );
        }).toList();
      });
    });
