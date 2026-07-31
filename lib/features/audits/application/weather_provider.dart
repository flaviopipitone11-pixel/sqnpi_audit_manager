import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

class WeatherData {
  final double temperature;
  final String condition;
  final String icon;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.icon,
  });
}

final weatherProvider = FutureProvider<WeatherData>((ref) async {
  double lat = 45.4642; // Default Italia (Milano/Centro)
  double lng = 9.1900;

  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            timeLimit: Duration(seconds: 3),
          ),
        );
        lat = position.latitude;
        lng = position.longitude;
      }
    }
  } catch (e) {
    debugPrint('Geolocator fallback su coordinate di default: $e');
  }

  try {
    final dio = Dio();
    final response = await dio.get(
      'https://api.open-meteo.com/v1/forecast',
      queryParameters: {
        'latitude': lat,
        'longitude': lng,
        'current_weather': true,
      },
    );

    final current = response.data['current_weather'];
    final temp = (current['temperature'] as num).toDouble();
    final code = (current['weathercode'] as num).toInt();

    String condition = 'Sereno';
    if (code >= 1 && code <= 3) condition = 'Parz. Nuvoloso';
    if (code >= 45 && code <= 48) condition = 'Nebbia';
    if (code >= 51 && code <= 67) condition = 'Pioggia';
    if (code >= 71 && code <= 77) condition = 'Neve';
    if (code >= 80 && code <= 82) condition = 'Rovescio';
    if (code >= 95) condition = 'Temporale';

    return WeatherData(
      temperature: temp,
      condition: condition,
      icon: _getIconForCode(code),
    );
  } catch (e) {
    debugPrint('Errore API meteo Open-Meteo: $e');
    return WeatherData(temperature: 20.0, condition: 'Sereno', icon: '☀️');
  }
});

String _getIconForCode(int code) {
  if (code == 0) return '☀️'; // Clear
  if (code >= 1 && code <= 3) return '⛅'; // Partly cloudy
  if (code >= 45 && code <= 48) return '🌫️'; // Fog
  if (code >= 51 && code <= 67) return '🌧️'; // Drizzle/Rain
  if (code >= 71 && code <= 77) return '❄️'; // Snow
  if (code >= 80 && code <= 82) return '🌦️'; // Rain showers
  if (code >= 95) return '⛈️'; // Thunderstorm
  return '🌡️';
}
