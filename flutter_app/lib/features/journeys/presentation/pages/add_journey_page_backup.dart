import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/location_autocomplete_search_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/location_autocomplete_service.dart';
import '../../../../core/services/location_weather_service.dart';
import '../../data/services/journey_service.dart';
import '../../data/models/journey.dart';

/// Page for adding a new journey
class AddJourneyPage extends StatefulWidget {
  const AddJourneyPage({super.key});

  @override
  State<AddJourneyPage> createState() => _AddJourneyPageState();
}

class _AddJourneyPageState extends State<AddJourneyPage> {
  final _formKey = GlobalKey<FormState>();
  final _journeyService = JourneyService();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Location data
  LocationSuggestion? _sourceLocation;
  LocationSuggestion? _destinationLocation;
  final List<LocationSuggestion> _intermediateStops = [];

  // User location for better search results
  double? _userLatitude;
  double? _userLongitude;

  // Date variables
  DateTime? _startDate;
  DateTime? _endDate;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final locationService = LocationWeatherService();
      final position = await locationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _userLatitude = position.latitude;
          _userLongitude = position.longitude;
        });
        print(
            '📍 User location for journey: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      print('❌ Error getting user location: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Create New Journey',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section with journey basic info
                _buildBasicInfoCard(),
                const SizedBox(height: 20),
                
                // Journey route section
                _buildRouteCard(),
                const SizedBox(height: 20),
                
                // Travel dates section
                _buildDatesCard(),
                const SizedBox(height: 32),
                
                // Create button
                _buildCreateButton(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== UI COMPONENTS ====================

  /// Build basic journey information card
  Widget _buildBasicInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit_note,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Journey Details',
                  style: AppTextStyles.h4.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Journey Title
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Journey Title',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Enter your journey title',
                    hintStyle: TextStyle(color: AppColors.textHint),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.grey300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.grey300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title for your journey';
                    }
                    return null;
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Description
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Describe your journey...',
                    hintStyle: TextStyle(color: AppColors.textHint),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.grey300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.grey300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build journey route card with source, destination, and intermediate stops
  Widget _buildRouteCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.route,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Journey Route',
                  style: AppTextStyles.h4.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Source location
            _buildLocationInput(
              label: 'From (Starting Point)',
              icon: Icons.my_location,
              iconColor: Colors.green,
              location: _sourceLocation,
              onLocationSelected: (location) {
                setState(() {
                  _sourceLocation = location;
                });
              },
              onRemove: () {
                setState(() {
                  _sourceLocation = null;
                });
              },
              isRequired: true,
            ),
            
            // Route line and intermediate stops
            _buildIntermediateStopsSection(),
            
            // Destination location
            _buildLocationInput(
              label: 'To (Destination)',
              icon: Icons.location_on,
              iconColor: Colors.red,
              location: _destinationLocation,
              onLocationSelected: (location) {
                setState(() {
                  _destinationLocation = location;
                });
              },
              onRemove: () {
                setState(() {
                  _destinationLocation = null;
                });
              },
              isRequired: true,
            ),
          ],
        ),
      ),
    );
  }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Journey Locations',
          style: AppTextStyles.h4.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // Source Location
        _buildLocationFieldSection(
          label: 'From (Source)',
          hintText: 'Enter starting location',
          selectedLocation: _sourceLocation,
          onLocationSelected: (location) {
            setState(() {
              _sourceLocation = location;
            });
          },
          isRequired: true,
        ),

        const SizedBox(height: 16),

        // Destination Location
        _buildLocationFieldSection(
          label: 'To (Destination)',
          hintText: 'Enter destination location',
          selectedLocation: _destinationLocation,
          onLocationSelected: (location) {
            setState(() {
              _destinationLocation = location;
            });
          },
          isRequired: true,
        ),

        const SizedBox(height: 16),

        // Intermediate Stops
        _buildIntermediateStopsSection(),
      ],
    );
  }

  Widget _buildLocationFieldSection({
    required String label,
    required String hintText,
    required LocationSuggestion? selectedLocation,
    required Function(LocationSuggestion) onLocationSelected,
    required bool isRequired,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: selectedLocation == null
                ? Border.all(color: AppColors.grey300)
                : Border.all(color: AppColors.primary.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: selectedLocation != null
              ? _buildSelectedLocationTile(selectedLocation, () {
                  if (label.contains('Source')) {
                    setState(() => _sourceLocation = null);
                  } else {
                    setState(() => _destinationLocation = null);
                  }
                })
              : LocationAutocompleteSearchBar(
                  hintText: hintText,
                  userLatitude: _userLatitude,
                  userLongitude: _userLongitude,
                  onLocationSelected: onLocationSelected,
                ),
        ),
      ],
    );
  }

  Widget _buildSelectedLocationTile(
      LocationSuggestion location, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (location.subtitle.isNotEmpty)
                  Text(
                    location.subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 18),
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildIntermediateStopsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Intermediate Stops',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(Optional)',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Show existing intermediate stops
        ..._intermediateStops.asMap().entries.map((entry) {
          final index = entry.key;
          final stop = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: _buildSelectedLocationTile(stop, () {
                setState(() {
                  _intermediateStops.removeAt(index);
                });
              }),
            ),
          );
        }),

        // Add new intermediate stop button/field
        if (_intermediateStops.length < 5) // Limit to 5 intermediate stops
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.grey300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: LocationAutocompleteSearchBar(
              hintText: 'Add intermediate stop',
              userLatitude: _userLatitude,
              userLongitude: _userLongitude,
              onLocationSelected: (location) {
                setState(() {
                  _intermediateStops.add(location);
                });
              },
            ),
          ),

        if (_intermediateStops.length >= 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Maximum 5 intermediate stops allowed',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Travel Dates',
          style: AppTextStyles.h4.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'Start Date',
                date: _startDate,
                onTap: () => _selectStartDate(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                label: 'End Date',
                date: _endDate,
                onTap: () => _selectEndDate(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.grey300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'Select date',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: date != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createJourney,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Create Journey',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date != null) {
      setState(() {
        _startDate = date;
        // Reset end date if it's before start date
        if (_endDate != null && _endDate!.isBefore(date)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final firstDate = _startDate ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  Future<void> _createJourney() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_sourceLocation == null) {
      _showErrorDialog('Please select a source location');
      return;
    }

    if (_destinationLocation == null) {
      _showErrorDialog('Please select a destination location');
      return;
    }

    if (_startDate == null || _endDate == null) {
      _showErrorDialog('Please select both start and end dates');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create location names list
      final locations = <String>[
        _sourceLocation!.title,
        ..._intermediateStops.map((stop) => stop.title),
        _destinationLocation!.title,
      ];

      // Create new journey
      final journey = Journey(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        isCompleted: false,
        destinations: locations,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add journey to service
      _journeyService.addJourney(journey);

      // Show success and navigate back
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to create journey. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Journey created successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to journey list
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
