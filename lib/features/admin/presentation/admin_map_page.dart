import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../audits/data/audits_repository.dart';
import '../../audits/domain/visit_with_company.dart';
import '../../audits/presentation/visit_workspace_page.dart';
import '../../../core/widgets/pulse_marker.dart';

class AdminMapPage extends ConsumerWidget {
  const AdminMapPage({super.key});

  Color _getStatusColor(int status) {
    if (status >= 2) return const Color(0xFF10B981); // Emerald
    if (status == 1) return const Color(0xFF3B82F6); // Blue
    return const Color(0xFFF59E0B); // Amber
  }

  String _getStatusLabel(int status) {
    if (status >= 3) return 'SINCRONIZZATA';
    if (status == 2) return 'COMPLETATA';
    if (status == 1) return 'IN CORSO';
    return 'PIANIFICATA';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(visitsWithCompanyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Mappa Territoriale',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F172A)),
            onPressed: () => ref.refresh(visitsWithCompanyProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: visitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Errore: $err')),
        data: (visits) {
          final validVisits = visits.where((v) {
            final lat =
                v.company.latitude ?? double.tryParse(v.company.latitudeText);
            final lng =
                v.company.longitude ?? double.tryParse(v.company.longitudeText);
            return lat != null &&
                lng != null &&
                lat >= 35.0 &&
                lat <= 48.0 &&
                lng >= 6.0 &&
                lng <= 19.0;
          }).toList();

          final markers = validVisits.map((v) {
            final lat =
                v.company.latitude ?? double.tryParse(v.company.latitudeText)!;
            final lng =
                v.company.longitude ??
                double.tryParse(v.company.longitudeText)!;
            return Marker(
              point: LatLng(lat, lng),
              width: 50,
              height: 50,
              child: PulseMarker(
                color: _getStatusColor(v.visit.status),
                icon: Icons.business_rounded,
                onTap: () => _showVisitDetails(context, ref, v),
              ),
            );
          }).toList();

          final hiddenCount = visits.length - validVisits.length;

          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(41.9028, 12.4964), // Roma
                  initialZoom: 6.5,
                  minZoom: 3.0,
                  cameraConstraint: CameraConstraint.contain(
                    bounds: LatLngBounds(
                      const LatLng(-85, -180),
                      const LatLng(85, 180),
                    ),
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.bios.sqnpi_audit_manager',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
              if (hiddenCount > 0)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFFB45309),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$hiddenCount aziende non localizzate',
                            style: const TextStyle(
                              color: Color(0xFF92400E),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              _buildLegend(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegend() {
    return Positioned(
      bottom: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'STATO VISITE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Color(0xFF94A3B8),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            _legendItem(const Color(0xFF10B981), 'Completata'),
            const SizedBox(height: 8),
            _legendItem(const Color(0xFF3B82F6), 'In Corso'),
            const SizedBox(height: 8),
            _legendItem(const Color(0xFFF59E0B), 'Pianificata'),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  void _showVisitDetails(
    BuildContext context,
    WidgetRef ref,
    VisitWithCompany vwc,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy', 'it_IT');
    final statusColor = _getStatusColor(vwc.visit.status);
    final statusLabel = _getStatusLabel(vwc.visit.status);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF1E293B,
                          ).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.eco_rounded,
                              size: 12,
                              color: Color(0xFF059669),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              vwc.visit.crop.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    vwc.company.ragioneSociale,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${vwc.company.comune} (${vwc.company.provincia})',
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (vwc.company.indirizzo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.map_rounded,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          vwc.company.indirizzo,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _infoRow(
                          Icons.person_pin_rounded,
                          'Ispettore',
                          vwc.visit.inspectorName,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                        ),
                        _infoRow(
                          Icons.calendar_today_rounded,
                          'Programmata',
                          dateFormat.format(vwc.visit.scheduledAt),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                        ),
                        _infoRow(
                          Icons.analytics_rounded,
                          'CUAA',
                          vwc.company.cuaa,
                        ),
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
                                builder: (context) => VisitWorkspacePage(
                                  visitId: vwc.visit.id,
                                  forceReadOnly: false,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.remove_red_eye_rounded, size: 20),
                              SizedBox(width: 12),
                              Text(
                                'Supervisiona',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              value.isEmpty ? 'Non assegnato' : value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
