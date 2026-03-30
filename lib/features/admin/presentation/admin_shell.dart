import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_dashboard_page.dart';
import 'admin_map_page.dart';
import 'admin_calendar_page.dart';
import 'admin_import_page.dart';
import 'admin_inspectors_page.dart';
import 'admin_companies_page.dart';
import 'admin_create_visit_page.dart';
import 'admin_checklist_page.dart';
import 'admin_logs_page.dart';
import '../application/activity_logger.dart';
import '../../auth/presentation/auth_controller.dart';

final adminNavbarIndexProvider = StateProvider<int>((ref) => 0);

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(adminNavbarIndexProvider);

    final pages = [
      const AdminDashboardPage(),
      const AdminMapPage(),
      const AdminCalendarPage(),
      const AdminImportPage(),
      const AdminCreateVisitPage(),
      const AdminInspectorsPage(),
      const AdminCompaniesPage(),
      const AdminChecklistPage(),
      const AdminLogsPage(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        if (isMobile) {
          return Scaffold(
            body: IndexedStack(index: selectedIndex, children: pages),
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                ref.read(adminNavbarIndexProvider.notifier).state = index;
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dash',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'Mappa',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: 'Cal',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: 'Ispett.',
                ),
                NavigationDestination(
                  icon: Icon(Icons.more_horiz),
                  label: 'Altro',
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              _AdminNavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) {
                  ref.read(adminNavbarIndexProvider.notifier).state = index;
                },
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: IndexedStack(index: selectedIndex, children: pages),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminNavigationRail extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _AdminNavigationRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isExtended = MediaQuery.of(context).size.width > 1200;

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: isExtended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      extended: isExtended,
      minWidth: 80,
      minExtendedWidth: 200,
      backgroundColor: const Color(0xFF1A237E),
      unselectedIconTheme: const IconThemeData(color: Colors.white60),
      selectedIconTheme: const IconThemeData(color: Colors.white),
      unselectedLabelTextStyle: const TextStyle(
        color: Colors.white60,
        fontSize: 12,
      ),
      selectedLabelTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      indicatorColor: Colors.white24,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            if (isExtended) ...[
              const SizedBox(height: 16),
              const Text(
                'SQNPI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 2,
                ),
              ),
              const Text(
                'MANAGER',
                style: TextStyle(
                  color: Colors.white60,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
          label: Text('Mappa'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: Text('Calendario'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.file_upload_outlined),
          selectedIcon: Icon(Icons.file_upload),
          label: Text('Importa'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.add_circle_outline_rounded),
          selectedIcon: Icon(Icons.add_circle_rounded),
          label: Text('Nuova'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: Text('Ispettori'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.business_outlined),
          selectedIcon: Icon(Icons.business),
          label: Text('Aziende'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.checklist_rtl_rounded),
          selectedIcon: Icon(Icons.checklist_rtl_rounded),
          label: Text('Checklist'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: Text('Log'),
        ),
      ],
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: IconButton(
              icon: const Icon(
                Icons.exit_to_app_rounded,
                color: Colors.white70,
              ),
              onPressed: () async {
                final logger = ref.read(activityLoggerProvider);
                final auth = ref.read(authControllerProvider.notifier);

                await logger.log(
                  action: 'ADMIN_LOGOUT',
                  description: 'Uscita dal pannello di amministrazione',
                );

                await auth.logout();
                // GoRouter will automatically redirect to /login due to auth state change
              },
              tooltip: 'Esci dal Pannello',
            ),
          ),
        ),
      ),
    );
  }
}
