import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sqnpi_audit_manager/core/storage/db_providers.dart';
import '../../../core/sync/sync_controller.dart';
import '../../auth/presentation/auth_controller.dart';
import 'home_page.dart';
import 'visits_page.dart';
import 'map_page.dart';
import '../../notes/presentation/personal_notes_page.dart';
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
          const SizedBox(width: 16),
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
                              content: const Text(
                                'Il database locale è incompatibile o corrotto. È necessario eliminare tutti i dati locali per continuare (le visite andranno risincronizzate).',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Annulla'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    final db = ref.read(appDatabaseProvider);
                                    await db.deleteDatabaseFile();
                                    ref.invalidate(seedDatabaseProvider);
                                  },
                                  child: const Text(
                                    'ELIMINA E RIPRISTINA',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Errore durante il reset: $err'),
                            ),
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
                    Container(
                      width: constraints.maxWidth > 1000 ? 280 : 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // App Logo / Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 32,
                              horizontal: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF059669),
                                        Color(0xFF10B981),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome_motion_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                if (constraints.maxWidth > 1000) ...[
                                  const SizedBox(width: 12),
                                  const Text(
                                    'SQNPI Audit',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Divider(indent: 16, endIndent: 16),
                          const SizedBox(height: 16),
                          // Custom Navigation
                          Expanded(
                            child: NavigationRail(
                              backgroundColor: Colors.transparent,
                              selectedIndex: selectedIndex,
                              onDestinationSelected: (i) =>
                                  ref
                                          .read(homeNavigationProvider.notifier)
                                          .state =
                                      i,
                              extended: constraints.maxWidth > 1000,
                              minExtendedWidth: 280,
                              labelType: NavigationRailLabelType.none,
                              indicatorColor: const Color(
                                0xFF10B981,
                              ).withOpacity(0.1),
                              selectedLabelTextStyle: const TextStyle(
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              unselectedLabelTextStyle: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                              ),
                              destinations: [
                                _buildNavItem(
                                  Icons.grid_view_rounded,
                                  Icons.grid_view_outlined,
                                  'Dashboard',
                                ),
                                _buildNavItem(
                                  Icons.assignment_rounded,
                                  Icons.assignment_outlined,
                                  'Le Mie Visite',
                                ),
                                _buildNavItem(
                                  Icons.map_rounded,
                                  Icons.map_outlined,
                                  'Mappa Controlli',
                                ),
                                _buildNavItem(
                                  Icons.note_alt_rounded,
                                  Icons.note_alt_outlined,
                                  'Note e Promemoria',
                                ),
                              ],
                            ),
                          ),
                          // Bottom Profile / Info
                          if (constraints.maxWidth > 1000)
                            Container(
                              padding: const EdgeInsets.all(24),
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: const Color(
                                          0xFF059669,
                                        ),
                                        child: Text(
                                          (auth.username ?? 'I')
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              auth.username ?? 'Ispettore',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const Text(
                                              'Ispettore Qualificato',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => ref
                                          .read(authControllerProvider.notifier)
                                          .logout(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.red,
                                        elevation: 0,
                                        side: BorderSide(
                                          color: Colors.red.withValues(
                                            alpha: 0.1,
                                          ),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Disconnetti'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: selectedIndex,
                        children: const [
                          HomePage(),
                          VisitsPage(),
                          MapPage(),
                          PersonalNotesPage(),
                        ],
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
                      children: const [
                        HomePage(),
                        VisitsPage(),
                        MapPage(),
                        PersonalNotesPage(),
                      ],
                    ),
                  ),
                  NavigationBar(
                    backgroundColor: Colors.white,
                    indicatorColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.15),
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
                        icon: Icon(Icons.map_outlined, color: Colors.grey),
                        selectedIcon: Icon(Icons.map),
                        label: 'Mappa',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.note_alt_outlined, color: Colors.grey),
                        selectedIcon: Icon(Icons.note_alt),
                        label: 'Note',
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

  NavigationRailDestination _buildNavItem(
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    return NavigationRailDestination(
      icon: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Icon(icon, color: const Color(0xFF64748B)),
      ),
      selectedIcon: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Icon(selectedIcon, color: const Color(0xFF059669)),
      ),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}
