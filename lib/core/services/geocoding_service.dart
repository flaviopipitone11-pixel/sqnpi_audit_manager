import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final geocodingServiceProvider = Provider((ref) => GeocodingService());

class GeocodingService {
  final _dio = Dio(BaseOptions(
    headers: {
      'User-Agent': 'SQNPIAuditManager/1.0 (contact: support@example.com)',
    },
  ));

  Future<({double lat, double lon})?> getCoordinates({
    required String address,
    required String city,
    required String province,
  }) async {
    try {
      final query = '$address, $city, $province, Italia';
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 1,
        },
      );

      if (response.statusCode == 200 && (response.data as List).isNotEmpty) {
        final first = response.data[0];
        return (
          lat: double.parse(first['lat']),
          lon: double.parse(first['lon']),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
