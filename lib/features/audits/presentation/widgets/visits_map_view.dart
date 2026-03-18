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

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        try {
          permission = await Geolocator.requestPermission();
        } catch (e) {
          // If a request is already in progress, wait a bit and check again
          debugPrint('Location permission request in progress, waiting...');
          await Future.delayed(const Duration(milliseconds: 500));
          permission = await Geolocator.checkPermission();
        }

        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      // Ignore if permission was denied at the OS level during fetch
      debugPrint('Error getting location: $e');
    }
  }

  void _showMarkerOptions(BuildContext context, VisitWithCompany v) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.business),
                  title: Text(
                    v.company.ragioneSociale,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${v.company.indirizzo}, ${v.company.comune}'),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.assignment,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: const Text('Apri Dettagli Visita'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/visit/${v.visit.id}');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.directions, color: Colors.blue),
                  title: const Text('Naviga (Apri in Mappe)'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final lat = v.company.latitude!;
                    final lng = v.company.longitude!;
                    // Utilizza un URI che apre direttamente la navigazione
                    final url = Uri.parse(
                      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Impossibile aprire le mappe.'),
                          ),
                        );
                      }
                    }
                  },
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
    // Calcoliamo il centro della mappa in base alle visite (o default se vuoto)
    LatLng center = const LatLng(
      43.7696,
      11.2558,
    ); // Firenze (centro Italia circa)

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

    return cacheStoreAsync.when(
      data: (cacheStore) => FlutterMap(
        options: MapOptions(initialCenter: center, initialZoom: 8),
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
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showMarkerOptions(context, v),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D6A4F),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
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
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => FlutterMap(
        options: MapOptions(initialCenter: center, initialZoom: 8),
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
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showMarkerOptions(context, v),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D6A4F),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
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
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
