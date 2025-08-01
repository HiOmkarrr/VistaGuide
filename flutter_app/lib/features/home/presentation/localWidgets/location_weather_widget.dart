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

  @override
  void initState() {
    super.initState();
    _loadLocationAndWeather();
  }

  Future<void> _loadLocationAndWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final weatherData = await _locationWeatherService.getWeatherData();
      if (mounted) {
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Current Location',
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              else
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    size: 20,
                    color: AppColors.grey600,
                  ),
                  onPressed: _loadLocationAndWeather,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
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
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.location_city,
              color: AppColors.grey400,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Loading location...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.wb_sunny_outlined,
              color: AppColors.grey400,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Loading weather...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Row(
      children: [
        Icon(
          Icons.error_outline,
          color: AppColors.emergency,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _errorMessage,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.emergency,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherData(WeatherData weather) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.location_city,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                weather.cityName,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.wb_sunny,
              color: Colors.orange,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              _locationWeatherService
                  .getFormattedTemperature(weather.temperature),
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                weather.description
                    .split(' ')
                    .map((word) => word[0].toUpperCase() + word.substring(1))
                    .join(' '),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grey700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoDataState() {
    return Row(
      children: [
        Icon(
          Icons.location_off,
          color: AppColors.grey400,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          'Location not available',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.grey600,
          ),
        ),
      ],
    );
  }
}
