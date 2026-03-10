import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/audits_repository.dart';
import 'widgets/visits_map_view.dart';

class MapPage extends ConsumerWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsWithCompanyAsync = ref.watch(visitsWithCompanyProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: visitsWithCompanyAsync.when(
        data: (data) => VisitsMapView(visits: data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Errore caricamento mappa: $e'),
            ],
          ),
        ),
      ),
    );
  }
}
