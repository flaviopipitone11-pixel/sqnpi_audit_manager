import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import '../../../../core/storage/map_cache_provider.dart';
import '../../domain/visit_with_company.dart';
import '../../../../core/widgets/pulse_marker.dart';

class VisitsMapView extends ConsumerStatefulWidget {
  final List<VisitWithCompany> visits;

  const VisitsMapView({super.key, required this.visits});

  @override
  ConsumerState<VisitsMapView> createState() => _VisitsMapViewState();
}

class _VisitsMapViewState extends ConsumerState<VisitsMapView> {
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

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

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        try {
          permission = await Geolocator.requestPermission();
        } catch (e) {
          await Future.delayed(const Duration(milliseconds: 500));
          permission = await Geolocator.checkPermission();
        }
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _currentPosition = position);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _showMarkerOptions(BuildContext context, VisitWithCompany v) {
    final statusColor = _getStatusColor(v.visit.status);
    final statusLabel = _getStatusLabel(v.visit.status);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            bottom: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
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
                                  v.visit.crop.toUpperCase(),
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
                        v.company.ragioneSociale,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${v.company.indirizzo}, ${v.company.comune} (${v.company.provincia})',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                context.push('/visit/${v.visit.id}');
                              },
                              icon: const Icon(
                                Icons.assignment_rounded,
                                size: 20,
                              ),
                              label: const Text('APRI VISITA'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: IconButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                final lat = v.company.latitude!;
                                final lng = v.company.longitude!;
                                final url = Uri.parse(
                                  'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
                                );
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                }
                              },
                              icon: const Icon(
                                Icons.directions_rounded,
                                color: Color(0xFF2563EB),
                              ),
                              padding: const EdgeInsets.all(16),
                              tooltip: 'Naviga',
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    LatLng center = const LatLng(43.7696, 11.2558);

    final validVisits = widget.visits
        .where((v) => v.company.latitude != null && v.company.longitude != null)
        .toList();

    if (validVisits.isNotEmpty) {
      double sumLat = 0;
      double sumLng = 0;
      for (var v in validVisits) {
        sumLat += v.company.latitude!;
        sumLng += v.company.longitude!;
      }
      center = LatLng(sumLat / validVisits.length, sumLng / validVisits.length);
    } else if (_currentPosition != null) {
      center = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    }

    final cacheStoreAsync = ref.watch(mapCacheStoreProvider);
    final hiddenCount = widget.visits.length - validVisits.length;

    return cacheStoreAsync.when(
      data: (cacheStore) => Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 8,
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
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.flaviopipitone.sqnpiauditmanager',
                tileProvider: CachedTileProvider(store: cacheStore),
              ),
              MarkerLayer(
                markers: [
                  ...validVisits.map((v) {
                    final lat = v.company.latitude!;
                    final lng = v.company.longitude!;
                    return Marker(
                      point: LatLng(lat, lng),
                      width: 50,
                      height: 50,
                      child: PulseMarker(
                        color: _getStatusColor(v.visit.status),
                        icon: Icons.business_rounded,
                        onTap: () => _showMarkerOptions(context, v),
                      ),
                    );
                  }),
                  if (_currentPosition != null)
                    Marker(
                      point: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
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
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 8,
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
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.flaviopipitone.sqnpiauditmanager',
              ),
              MarkerLayer(
                markers: [
                  ...validVisits.map((v) {
                    final lat = v.company.latitude!;
                    final lng = v.company.longitude!;
                    return Marker(
                      point: LatLng(lat, lng),
                      width: 50,
                      height: 50,
                      child: PulseMarker(
                        color: _getStatusColor(v.visit.status),
                        icon: Icons.business_rounded,
                        onTap: () => _showMarkerOptions(context, v),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
