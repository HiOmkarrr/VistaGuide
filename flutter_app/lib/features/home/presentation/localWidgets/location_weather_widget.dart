import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/location_weather_service.dart';

/// Widget to display current location and weather information
class LocationWeatherWidget extends StatefulWidget {
  const LocationWeatherWidget({super.key});

  @override
  State<LocationWeatherWidget> createState() => _LocationWeatherWidgetState();
}

class _LocationWeatherWidgetState extends State<LocationWeatherWidget> {
  final LocationWeatherService _locationWeatherService =
      LocationWeatherService();
  bool _isLoading = true;
  WeatherData? _weatherData;
  String _errorMessage = '';

  // Cache management
  static DateTime? _lastUpdated;
  static WeatherData? _cachedWeatherData;
  static const Duration _cacheInterval = Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
    _loadLocationAndWeather();
  }

  Future<void> _loadLocationAndWeather([bool forceRefresh = false]) async {
    // Check if we have cached data that's still valid (unless forcing refresh)
    if (!forceRefresh &&
        _cachedWeatherData != null &&
        _lastUpdated != null &&
        DateTime.now().difference(_lastUpdated!) < _cacheInterval) {
      setState(() {
        _weatherData = _cachedWeatherData;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final weatherData = await _locationWeatherService.getWeatherData();
      if (mounted) {
        // Cache the new data
        _cachedWeatherData = weatherData;
        _lastUpdated = DateTime.now();

        setState(() {
          _weatherData = weatherData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load location data';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading)
            _buildLoadingState()
          else if (_errorMessage.isNotEmpty)
            _buildErrorState()
          else if (_weatherData != null)
            _buildWeatherData(_weatherData!)
          else
            _buildNoDataState(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Row(
      children: [
        // Left side: Location and Weather loading indicators
        Expanded(
          child: Row(
            children: [
              // Location loading
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.location_city,
                      color: AppColors.grey400,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Loading...',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Weather loading
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.wb_sunny_outlined,
                      color: AppColors.grey400,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Loading...',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Right side: Loading spinner
        SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Row(
      children: [
        // Left side: Error message
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: AppColors.emergency,
                size: 18,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _errorMessage,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.emergency,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Right side: Reload button
        IconButton(
          icon: Icon(
            Icons.refresh,
            size: 20,
            color: AppColors.grey600,
          ),
          onPressed: _loadLocationAndWeather,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherData(WeatherData weather) {
    return Row(
      children: [
        // Left side: Location and Weather columns
        Expanded(
          child: Row(
            children: [
              // Location column
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.location_city,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        weather.cityName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Weather column
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.wb_sunny,
                      color: Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _locationWeatherService
                          .getFormattedTemperature(weather.temperature),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        weather.description
                            .split(' ')
                            .map((word) =>
                                word[0].toUpperCase() + word.substring(1))
                            .join(' '),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.grey700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Right side: Reload button
        IconButton(
          icon: Icon(
            Icons.refresh,
            size: 20,
            color: AppColors.grey600,
          ),
          onPressed: _loadLocationAndWeather,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
      ],
    );
  }

  Widget _buildNoDataState() {
    return Row(
      children: [
        // Left side: No data message
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.location_off,
                color: AppColors.grey400,
                size: 18,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Location not available',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Right side: Reload button
        IconButton(
          icon: Icon(
            Icons.refresh,
            size: 20,
            color: AppColors.grey600,
          ),
          onPressed: _loadLocationAndWeather,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
      ],
    );
  }
}
