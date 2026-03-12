import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../audits/data/audits_repository.dart';
import '../../audits/domain/visit_with_company.dart';
import '../../audits/presentation/visit_workspace_page.dart';
import '../application/activity_logger.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';

class AdminMapPage extends ConsumerWidget {
  const AdminMapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(visitsWithCompanyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Mappa Territoriale Audits',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A237E)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1A237E)),
            onPressed: () => ref.refresh(visitsWithCompanyProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: visitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Errore: $err')),
        data: (visits) {
          final markers = visits
              .where((v) => v.company.latitude != null && v.company.longitude != null)
              .map((v) => _buildMarker(context, ref, v))
              .toList();

          return Stack(
            children: [
              FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(41.9028, 12.4964), // Roma
                  initialZoom: 6,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.bios.sqnpi_audit_manager',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
              _buildLegend(),
            ],
          );
        },
      ),
    );
  }

  Marker _buildMarker(BuildContext context, WidgetRef ref, VisitWithCompany vwc) {
    final statusColor = vwc.visit.status >= 2 
        ? const Color(0xFF4CAF50) 
        : vwc.visit.status == 1 
            ? const Color(0xFF2196F3) 
            : const Color(0xFFFFA000);

    return Marker(
      point: LatLng(vwc.company.latitude!, vwc.company.longitude!),
      width: 60,
      height: 60,
      child: GestureDetector(
        onTap: () => _showVisitDetails(context, ref, vwc),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              width: 50,
              height: 50,
            ),
            Container(
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              width: 32,
              height: 32,
              child: const Icon(Icons.business_rounded, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Positioned(
      bottom: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _legendItem(const Color(0xFF4CAF50), 'Completata'),
            const SizedBox(height: 8),
            _legendItem(const Color(0xFF2196F3), 'In Corso'),
            const SizedBox(height: 8),
            _legendItem(const Color(0xFFFFA000), 'Pianificata'),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
      ],
    );
  }

  void _showVisitDetails(BuildContext context, WidgetRef ref, VisitWithCompany vwc) {
    final dateFormat = DateFormat('dd MMM yyyy', 'it_IT');
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 6,
              width: 40,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vwc.company.ragioneSociale,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A237E), letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 16, color: Colors.blueGrey.shade400),
                      const SizedBox(width: 6),
                      Text(
                        '${vwc.company.comune} (${vwc.company.provincia})',
                        style: TextStyle(color: Colors.blueGrey.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  if (vwc.company.indirizzo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.map_rounded, size: 16, color: Colors.blueGrey.shade400),
                        const SizedBox(width: 6),
                        Text(
                          vwc.company.indirizzo,
                          style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _infoRow(Icons.person_pin_rounded, 'Ispettore', vwc.visit.inspectorName),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1),
                        ),
                        _infoRow(Icons.calendar_today_rounded, 'Programmata', dateFormat.format(vwc.visit.scheduledAt)),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1),
                        ),
                        _infoRow(Icons.eco_rounded, 'Coltura', vwc.visit.crop),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VisitWorkspacePage(visitId: vwc.visit.id, forceReadOnly: true),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.remove_red_eye_rounded, size: 20),
                              SizedBox(width: 12),
                              Text('Supervisiona', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          onPressed: () => _showAssignInspectorDialog(context, ref, vwc),
                          icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF1A237E)),
                          padding: const EdgeInsets.all(18),
                          tooltip: 'Assegna Ispettore',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF1A237E)),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 0.5)),
            Text(value.isEmpty ? 'Non assegnato' : value, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Future<void> _showAssignInspectorDialog(BuildContext context, WidgetRef ref, VisitWithCompany vwc) async {
    final db = ref.read(appDatabaseProvider);
    final inspectors = await db.select(db.inspectors).get();

    if (inspectors.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nessun ispettore censito.')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Column(
          children: [
            Icon(Icons.person_add_rounded, color: Color(0xFF1A237E), size: 32),
            SizedBox(height: 16),
            Text('Seleziona Ispettore', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A237E), fontSize: 22)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: inspectors.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final isp = inspectors[index];
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.05)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1A237E),
                    radius: 18,
                    child: Text(isp.fullName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  title: Text(isp.fullName, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A237E))),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF1A237E)),
                  onTap: () async {
                    await (db.update(db.visits)..where((t) => t.id.equals(vwc.visit.id))).write(
                      VisitsCompanion(inspectorName: Value(isp.fullName)),
                    );

                    final logger = ref.read(activityLoggerProvider);
                    await logger.log(
                      action: 'ASSIGN_VISIT_MAP',
                      description: 'Assegnata visita ${vwc.visit.id} (Azienda: ${vwc.visit.companyName}) a ${isp.fullName} dalla mappa',
                    );

                    if (context.mounted) {
                      Navigator.pop(context); // Chiude dialog
                      Navigator.pop(context); // Chiude bottom sheet
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Visita assegnata a ${isp.fullName}'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
