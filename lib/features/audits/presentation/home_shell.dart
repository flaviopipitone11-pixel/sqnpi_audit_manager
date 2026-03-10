import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sqnpi_audit_manager/core/storage/db_providers.dart';
import '../../../core/sync/sync_controller.dart';
import '../../auth/presentation/auth_controller.dart';
import 'home_page.dart';
import 'visits_page.dart';
import 'map_page.dart';
import 'navigation_providers.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final seed = ref.watch(seedDatabaseProvider);
    final selectedIndex = ref.watch(homeNavigationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50 background
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.username ?? 'Ispettore',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'SQNPI Audit — Ispettore',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final sync = ref.watch(syncStatusProvider);

              final (iconData, iconColor, tooltip) = switch (sync.state) {
                SyncState.online => (
                  Icons.cloud_done,
                  Colors.white70,
                  'Sincronizzato',
                ),
                SyncState.offline => (
                  Icons.cloud_off,
                  Colors.redAccent,
                  'In modalità offline',
                ),
                SyncState.syncing => (
                  Icons.sync,
                  Colors.white,
                  'Sincronizzazione in corso...',
                ),
                SyncState.needsSync => (
                  Icons.cloud_upload,
                  Colors.orangeAccent,
                  '${sync.pendingItems} elementi da sincronizzare',
                ),
              };

              return Tooltip(
                message: tooltip,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Icon(iconData, color: iconColor, size: 20),
                ),
              );
            },
          ),
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
            tooltip: 'Esci',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: seed.when(
        loading: () => Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Errore durante inizializzazione:\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final db = ref.read(appDatabaseProvider);
                      await db.resetChecklistAndReimport();
                      ref.invalidate(seedDatabaseProvider);
                    } catch (err) {
                      if (err.toString().contains('SCHEMA_CORRUPTED')) {
                         if (context.mounted) {
                           showDialog(
                             context: context,
                             builder: (ctx) => AlertDialog(
                               title: const Text('Reset Totale Necessario'),
                               content: const Text('Il database locale è incompatibile o corrotto. È necessario eliminare tutti i dati locali per continuare (le visite andranno risincronizzate).'),
                               actions: [
                                 TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
                                 TextButton(
                                   onPressed: () async {
                                     Navigator.pop(ctx);
                                     final db = ref.read(appDatabaseProvider);
                                     await db.deleteDatabaseFile();
                                     ref.invalidate(seedDatabaseProvider);
                                   },
                                   child: const Text('ELIMINA E RIPRISTINA', style: TextStyle(color: Colors.red)),
                                 ),
                               ],
                             ),
                           );
                         }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Errore durante il reset: $err')),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Checklist e Riprova'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.invalidate(seedDatabaseProvider),
                  child: const Text('Riprova semplicemente'),
                ),
              ],
            ),
          ),
        ),
        data: (_) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;

              if (isWide) {
                return Row(
                  children: [
                    NavigationRail(
                      backgroundColor: Colors.white,
                      selectedIndex: selectedIndex,
                      onDestinationSelected: (i) =>
                          ref.read(homeNavigationProvider.notifier).state = i,
                      extended: constraints.maxWidth > 1000,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          selectedIcon: Icon(Icons.dashboard),
                          label: Text('Dashboard'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.assignment_outlined),
                          selectedIcon: Icon(Icons.assignment),
                          label: Text('Visite'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.map_outlined),
                          selectedIcon: Icon(Icons.map),
                          label: Text('Mappa'),
                        ),
                      ],
                    ),
                    const VerticalDivider(
                      width: 1,
                      color: Color(0xFFE2E8F0),
                    ), // Light border
                    Expanded(
                      child: IndexedStack(
                        index: selectedIndex,
                        children: const [HomePage(), VisitsPage(), MapPage()],
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: IndexedStack(
                      index: selectedIndex,
                      children: const [HomePage(), VisitsPage(), MapPage()],
                    ),
                  ),
                  NavigationBar(
                    backgroundColor: Colors.white,
                    indicatorColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.15),
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (i) =>
                        ref.read(homeNavigationProvider.notifier).state = i,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(
                          Icons.dashboard_outlined,
                          color: Colors.grey,
                        ),
                        selectedIcon: Icon(Icons.dashboard),
                        label: 'Dashboard',
                      ),
                      NavigationDestination(
                        icon: Icon(
                          Icons.assignment_outlined,
                          color: Colors.grey,
                        ),
                        selectedIcon: Icon(Icons.assignment),
                        label: 'Visite',
                      ),
                      NavigationDestination(
                        icon: Icon(
                          Icons.map_outlined,
                          color: Colors.grey,
                        ),
                        selectedIcon: Icon(Icons.map),
                        label: 'Mappa',
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
