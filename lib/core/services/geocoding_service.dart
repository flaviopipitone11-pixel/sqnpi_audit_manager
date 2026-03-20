import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final geocodingServiceProvider = Provider((ref) => GeocodingService());

class GeocodingService {
  Future<({double lat, double lon, String? error})?> getCoordinates({
    required String address,
    required String city,
    required String province,
    String? postalCode,
  }) async {
    try {
      // Usiamo una nuova istanza di Dio con header che simulano un browser reale
      // per evitare blocchi 403 da parte di Akamai/Cloudflare
      final dio = Dio();
      dio.options.headers = {
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        'Accept': 'application/json, text/plain, */*',
        'Accept-Language': 'it-IT,it;q=0.9,en-US;q=0.8,en;q=0.7',
      };

      final cleanAddress = address
          .replaceAll(',', ' ')
          .replaceAll('.', ' ')
          .trim();
      final query = '$cleanAddress $city Italia';

      final response = await dio
          .get(
            'https://photon.komoot.io/api',
            queryParameters: {'q': query, 'limit': 1},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final features = data['features'] as List;
        if (features.isNotEmpty) {
          final first = features[0];
          final geometry = first['geometry'] as Map<String, dynamic>;
          final coords = geometry['coordinates'] as List;

          return (
            lat: (coords[1] as num).toDouble(),
            lon: (coords[0] as num).toDouble(),
            error: null,
          );
        }
      }

      // Prova con query ancora più semplice (solo via e città)
      final simpleQuery = '$cleanAddress $city';
      final response2 = await dio
          .get(
            'https://photon.komoot.io/api',
            queryParameters: {'q': simpleQuery, 'limit': 1},
          )
          .timeout(const Duration(seconds: 5));

      if (response2.statusCode == 200) {
        final data = response2.data as Map<String, dynamic>;
        final features = data['features'] as List;
        if (features.isNotEmpty) {
          final first = features[0];
          final geometry = first['geometry'] as Map<String, dynamic>;
          final coords = geometry['coordinates'] as List;

          return (
            lat: (coords[1] as num).toDouble(),
            lon: (coords[0] as num).toDouble(),
            error: null,
          );
        }
      }

      return null;
    } catch (e) {
      return (
        lat: 0.0,
        lon: 0.0,
        error: 'Errore di connessione o servizio non disponibile: $e',
      );
    }
  }
}
