import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'location_permission_service.dart';

/// Weather data model
class WeatherData {
  final String cityName;
  final String country;
  final double temperature;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;

  const WeatherData({
    required this.cityName,
    required this.country,
    required this.temperature,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      cityName: json['name'] ?? '',
      country: json['sys']['country'] ?? '',
      temperature: (json['main']['temp'] ?? 0).toDouble(),
      description: json['weather'][0]['description'] ?? '',
      icon: json['weather'][0]['icon'] ?? '',
      humidity: json['main']['humidity'] ?? 0,
      windSpeed: (json['wind']['speed'] ?? 0).toDouble(),
    );
  }
}

/// Service to handle location and weather data
class LocationWeatherService {
  static final LocationWeatherService _instance =
      LocationWeatherService._internal();
  factory LocationWeatherService() => _instance;
  LocationWeatherService._internal();

  Position? _currentPosition;
  WeatherData? _currentWeather;
  String? _currentLocationName;
  final _permissionService = LocationPermissionService();

  /// Check and request location permissions - now requires "always" permission
  Future<bool> _handleLocationPermission(BuildContext? context) async {
    bool serviceEnabled;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // If context is provided, use the new permission service that requires "always" permission
    if (context != null) {
      return await _permissionService.ensureAlwaysLocationPermission(context);
    }

    // Fallback: check if we already have "always" permission
    return await _permissionService.hasAlwaysLocationPermission();
  }

  /// Get current location - requires BuildContext for permission dialogs
  Future<Position?> getCurrentLocation({BuildContext? context}) async {
    try {
      final hasPermission = await _handleLocationPermission(context);
      if (!hasPermission) return null;

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return _currentPosition;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Get location name from coordinates
  Future<String> getLocationName(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality ?? place.subAdministrativeArea ?? '';
        final country = place.country ?? '';

        _currentLocationName =
            city.isNotEmpty ? '$city, $country' : 'Unknown Location';
        return _currentLocationName!;
      }
    } catch (e) {
      debugPrint('Error getting location name: $e');
    }
    return 'Unknown Location';
  }

  /// Get weather data for current location - requires BuildContext for permission dialogs
  Future<WeatherData?> getWeatherData({BuildContext? context}) async {
    try {
      final position = await getCurrentLocation(context: context);
      if (position == null) {
        // Return mock data even if location is not available
        _currentWeather = const WeatherData(
          cityName: 'Demo Location',
          country: 'Demo',
          temperature: 24.5,
          description: 'partly cloudy',
          icon: '02d',
          humidity: 65,
          windSpeed: 3.2,
        );
        return _currentWeather;
      }

      // For demo purposes, return mock weather data with actual location
      // In production, you would use a real weather API
      final locationName = await getLocationName(position);

      _currentWeather = WeatherData(
        cityName: locationName,
        country: 'Demo',
        temperature: 24.5,
        description: 'partly cloudy',
        icon: '02d',
        humidity: 65,
        windSpeed: 3.2,
      );

      return _currentWeather;

      // Uncomment below for real API call (requires API key)
      /*
      final url = '$_baseUrl/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentWeather = WeatherData.fromJson(data);
        return _currentWeather;
      }
      */
    } catch (e) {
      debugPrint('Error getting weather data: $e');
    }
    return null;
  }

  /// Get cached weather data
  WeatherData? get cachedWeather => _currentWeather;

  /// Get cached location name
  String? get cachedLocationName => _currentLocationName;

  /// Get formatted temperature
  String getFormattedTemperature(double temp) {
    return '${temp.toInt()}°C';
  }

  /// Get weather icon URL
  String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }
}
