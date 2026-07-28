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
      final dio = Dio();
      dio.options.headers = {
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        'Accept': 'application/json, text/plain, */*',
        'Accept-Language': 'it-IT,it;q=0.9,en-US;q=0.8,en;q=0.7',
      };

      // Pulizia dell'indirizzo (rimozione n., n°, civico, virgole, ecc.)
      final cleanAddress = address
          .replaceAll(RegExp(r'\bN°?\b|\bNR\.?\b|\bN\.?\b|\bCIVICO\b', caseSensitive: false), '')
          .replaceAll(',', ' ')
          .replaceAll('.', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      // Tentativi di ricerca progressivi (tutti ristretti rigorosamente all'Italia via countrycode=it)
      final queriesToTry = [
        '$cleanAddress $city $province Italia',
        '$cleanAddress $city Italia',
        '${cleanAddress.replaceAll(RegExp(r'\d+$'), '').trim()} $city Italia',
        '$city $province Italia',
      ];

      for (final query in queriesToTry) {
        if (query.trim().isEmpty) continue;
        try {
          final response = await dio
              .get(
                'https://photon.komoot.io/api',
                queryParameters: {
                  'q': query,
                  'limit': 1,
                  'countrycode': 'it', // RISERVA ESCLUSIVAMENTE ALL'ITALIA!
                },
              )
              .timeout(const Duration(seconds: 4));

          if (response.statusCode == 200) {
            final data = response.data as Map<String, dynamic>;
            final features = data['features'] as List;
            if (features.isNotEmpty) {
              final first = features[0];
              final geometry = first['geometry'] as Map<String, dynamic>;
              final coords = geometry['coordinates'] as List;

              final lat = (coords[1] as num).toDouble();
              final lon = (coords[0] as num).toDouble();

              // Verifichiamo che le coordinate rientrino nei confini dell'Italia (Lat ~35..48, Lon ~6..19)
              if (lat >= 35.0 && lat <= 48.0 && lon >= 6.0 && lon <= 19.0) {
                return (lat: lat, lon: lon, error: null);
              }
            }
          }
        } catch (_) {}
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
