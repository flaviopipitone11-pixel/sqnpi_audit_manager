import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../audits/data/audits_repository.dart';
import '../../audits/domain/visit_with_company.dart';
import '../application/admin_export_service.dart';
import '../../audits/presentation/visit_workspace_page.dart';

final adminSearchQueryProvider = StateProvider<String>((ref) => '');
final adminStatusFilterProvider = StateProvider<int?>((ref) => null);

final filteredAdminVisitsProvider = Provider<AsyncValue<List<VisitWithCompany>>>((ref) {
  final visitsAsync = ref.watch(visitsWithCompanyProvider);
  final query = ref.watch(adminSearchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(adminStatusFilterProvider);

  return visitsAsync.whenData((visits) {
    return visits.where((v) {
      final matchesQuery = v.visit.companyName.toLowerCase().contains(query) ||
          v.visit.crop.toLowerCase().contains(query) ||
          v.visit.inspectorName.toLowerCase().contains(query);
      
      final matchesStatus = statusFilter == null || v.visit.status == statusFilter;
      
      return matchesQuery && matchesStatus;
    }).toList();
  });
});

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final visitsAsync = ref.watch(visitsWithCompanyProvider);
    final filteredVisitsAsync = ref.watch(filteredAdminVisitsProvider);
    final exportService = ref.watch(adminExportServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shield_rounded, size: 24, color: Color(0xFF1A237E)),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.username ?? 'Amministratore',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A237E), letterSpacing: -0.5),
                ),
                Text(
                  'SQNPI Control Panel • Gestione Centrale',
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade400, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
            ),
            tooltip: 'Esci dal portale',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: visitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Errore: $err')),
        data: (allVisits) {
          int totalVisits = allVisits.length;
          int completed = allVisits.where((v) => v.visit.status >= 2).length;
          int inProgress = allVisits.where((v) => v.visit.status == 1).length;
          // Simulated inspectors based on unique inspector names in real data
          int activeInspectors = allVisits.map((v) => v.visit.inspectorName).where((name) => name.isNotEmpty).toSet().length;
          if (activeInspectors == 0 && totalVisits > 0) activeInspectors = 1;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
                        ],
                      ),
                      child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Panoramica Generale',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1, color: Color(0xFF1A237E)),
                          ),
                          Text('Monitoraggio in tempo reale delle ispezioni', style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade600, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    _ExportButton(
                      label: 'Excel',
                      icon: Icons.table_chart_rounded,
                      color: const Color(0xFF2E7D32),
                      onPressed: () => exportService.exportToExcel(allVisits),
                    ),
                    const SizedBox(width: 12),
                    _ExportButton(
                      label: 'PDF',
                      icon: Icons.picture_as_pdf_rounded,
                      color: const Color(0xFFC62828),
                      onPressed: () => exportService.exportSummaryPdf(allVisits),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    _StatCard(title: 'Totale Visite', value: totalVisits.toString(), icon: Icons.list_alt, color: Colors.blue),
                    const SizedBox(width: 16),
                    _StatCard(title: 'Ispettori Attivi', value: activeInspectors.toString(), icon: Icons.people_outline, color: Colors.purple),
                    const SizedBox(width: 16),
                    _StatCard(title: 'Visite Concluse', value: completed.toString(), icon: Icons.check_circle_outline, color: Colors.green),
                    const SizedBox(width: 16),
                    _StatCard(title: 'In Corso', value: inProgress.toString(), icon: Icons.sync, color: Colors.orange),
                  ],
                ),
                const SizedBox(height: 48),
                Row(
                  children: [
                    const Icon(Icons.tune_rounded, color: Color(0xFF1A237E), size: 24),
                    const SizedBox(width: 12),
                    const Text('Esplora e Filtra', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A237E), letterSpacing: -0.5)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          _FilterChip(label: 'Tutte', status: null),
                          const SizedBox(width: 4),
                          _FilterChip(label: 'In Corso', status: 1),
                          const SizedBox(width: 4),
                          _FilterChip(label: 'Concluse', status: 2),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (val) => ref.read(adminSearchQueryProvider.notifier).state = val,
                  decoration: InputDecoration(
                    hintText: 'Cerca per azienda, coltura o ispettore...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    const Icon(Icons.update, color: Color(0xFF1A237E)),
                    const SizedBox(width: 12),
                    const Text('Attività Ispettive', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActivityList(context, filteredVisitsAsync),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityList(BuildContext context, AsyncValue<List<VisitWithCompany>> visitsAsync) {
    return visitsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Errore: $err')),
      data: (visits) {
        if (visits.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Column(
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('Nessuna visita trovata con i filtri attuali.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return Column(
          children: List.generate(visits.length, (index) {
            final vwc = visits[index];
            final visit = vwc.visit;
            final statusColor = visit.status >= 2 ? const Color(0xFF4CAF50) : visit.status == 1 ? const Color(0xFF2196F3) : const Color(0xFFFFA000);
            final statusLabel = visit.status >= 2 ? 'Conclusa' : visit.status == 1 ? 'In Corso' : 'Pianificata';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.business_center_rounded, color: statusColor, size: 24),
                ),
                title: Text(
                  visit.companyName, 
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1A237E)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_pin_rounded, size: 14, color: Colors.blueGrey.shade400),
                        const SizedBox(width: 4),
                        Text(visit.inspectorName.isEmpty ? 'Nessun ispettore' : visit.inspectorName, 
                             style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.eco_rounded, size: 14, color: Colors.blueGrey.shade400),
                        const SizedBox(width: 4),
                        Text(visit.crop, style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1), 
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor.withOpacity(0.1)),
                      ),
                      child: Text(
                        statusLabel.toUpperCase(),
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.visibility_rounded, size: 20),
                        color: const Color(0xFF1A237E),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VisitWorkspacePage(visitId: visit.id, forceReadOnly: true),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _ExportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ExportButton({required this.label, required this.icon, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _FilterChip extends ConsumerWidget {
  final String label;
  final int? status;

  const _FilterChip({required this.label, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(adminStatusFilterProvider) == status;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (val) => ref.read(adminStatusFilterProvider.notifier).state = status,
      selectedColor: const Color(0xFF1A237E),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF1A237E), 
        fontWeight: FontWeight.bold, 
        fontSize: 13
      ),
      backgroundColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none,
      showCheckmark: false,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Icon(Icons.trending_up_rounded, color: color.withOpacity(0.3), size: 16),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1A237E), letterSpacing: -1),
            ),
            const SizedBox(height: 4),
            Text(
              title.toUpperCase(),
              style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade400, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }
}
