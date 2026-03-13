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
  // 1. Get location
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw 'Servizi di localizzazione disabilitati.';
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    try {
      permission = await Geolocator.requestPermission();
    } catch (e) {
      // If a request is already in progress, wait a bit and check again
      await Future.delayed(const Duration(milliseconds: 500));
      permission = await Geolocator.checkPermission();
    }

    if (permission == LocationPermission.denied) {
      throw 'Permessi di localizzazione negati.';
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw 'I permessi di localizzazione sono negati permanentemente.';
  }

  final position = await Geolocator.getCurrentPosition();

  // 2. Fetch weather (using Open-Meteo - Free, No API Key needed)
  final dio = Dio();
  final response = await dio.get(
    'https://api.open-meteo.com/v1/forecast',
    queryParameters: {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'current_weather': true,
    },
  );

  final current = response.data['current_weather'];
  final temp = current['temperature'] as double;
  final code = current['weathercode'] as int;

  // Map WMO Weather Codes to human readable strings and icons
  // https://open-meteo.com/en/docs
  String condition = 'Sereno';
  if (code >= 1 && code <= 3) condition = 'Parzialmente nuvoloso';
  if (code >= 45 && code <= 48) condition = 'Nebbia';
  if (code >= 51 && code <= 67) condition = 'Pioggia';
  if (code >= 71 && code <= 77) condition = 'Neve';
  if (code >= 80 && code <= 82) condition = 'Rovescio di pioggia';
  if (code >= 95) condition = 'Temporale';

  return WeatherData(
    temperature: temp,
    condition: condition,
    icon: _getIconForCode(code),
  );
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
