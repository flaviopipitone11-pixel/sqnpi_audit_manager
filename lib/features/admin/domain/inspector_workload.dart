import '../../../core/storage/app_database.dart';

class InspectorWorkload {
  final Inspector inspector;
  final int plannedCount;
  final int inProgressCount;
  final int completedCount;

  InspectorWorkload({
    required this.inspector,
    required this.plannedCount,
    required this.inProgressCount,
    required this.completedCount,
  });

  int get totalCount => plannedCount + inProgressCount + completedCount;
}
