import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/location_autocomplete_search_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/location_autocomplete_service.dart';
import '../../../../core/services/location_weather_service.dart';
import '../../../../core/services/journey_details_generation_service.dart';
import '../../data/services/journey_service.dart';
import '../../data/models/journey.dart';
import '../../data/models/journey_details_data.dart';

/// Page for adding a new journey with modern UI
class AddJourneyPage extends StatefulWidget {
  const AddJourneyPage({super.key});

  @override
  State<AddJourneyPage> createState() => _AddJourneyPageState();
}

class _AddJourneyPageState extends State<AddJourneyPage> {
  final _formKey = GlobalKey<FormState>();
  final _journeyService = JourneyService();
  final _journeyDetailsService = JourneyDetailsGenerationService();

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
  bool _isGeneratingDetails = false;

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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                      borderSide:
                          BorderSide(color: AppColors.primary, width: 2),
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
                      borderSide:
                          BorderSide(color: AppColors.primary, width: 2),
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.route,
                    color: Colors.blue,
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
            const SizedBox(height: 24),

            // Source location
            _buildLocationInput(
              label: 'Starting Point',
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
              label: 'Destination',
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

  /// Build individual location input with modern design
  Widget _buildLocationInput({
    required String label,
    required IconData icon,
    required Color iconColor,
    required LocationSuggestion? location,
    required Function(LocationSuggestion) onLocationSelected,
    required VoidCallback onRemove,
    required bool isRequired,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
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
            border: location == null
                ? Border.all(color: AppColors.grey300)
                : Border.all(
                    color: AppColors.primary.withOpacity(0.5), width: 1.5),
            borderRadius: BorderRadius.circular(12),
            color: location == null
                ? AppColors.surface
                : Colors.blue.withOpacity(0.02),
          ),
          child: location != null
              ? _buildSelectedLocationTile(location, onRemove, iconColor)
              : LocationAutocompleteSearchBar(
                  hintText: 'Enter $label',
                  userLatitude: _userLatitude,
                  userLongitude: _userLongitude,
                  onLocationSelected: onLocationSelected,
                ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Build selected location tile with modern design
  Widget _buildSelectedLocationTile(
      LocationSuggestion location, VoidCallback onRemove, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.location_on,
              color: iconColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (location.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    location.subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(
              Icons.close,
              size: 20,
              color: AppColors.textSecondary,
            ),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  /// Build intermediate stops section with route visualization
  Widget _buildIntermediateStopsSection() {
    return Column(
      children: [
        // Route line before intermediate stops
        if (_intermediateStops.isNotEmpty || true) // Always show line
          _buildRouteLine(),

        // Existing intermediate stops
        ..._intermediateStops.asMap().entries.map((entry) {
          final index = entry.key;
          final stop = entry.value;
          return Column(
            children: [
              _buildIntermediateStopTile(stop, index + 1, () {
                setState(() {
                  _intermediateStops.removeAt(index);
                });
              }),
              if (index < _intermediateStops.length - 1) _buildRouteLine(),
            ],
          );
        }),

        // Add intermediate stop button
        if (_intermediateStops.length < 5) _buildAddStopButton(),

        // Route line after intermediate stops
        _buildRouteLine(),
      ],
    );
  }

  /// Build route connecting line
  Widget _buildRouteLine() {
    return Container(
      width: 2,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grey400,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  /// Build intermediate stop tile with numbering
  Widget _buildIntermediateStopTile(
      LocationSuggestion stop, int number, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.withOpacity(0.5), width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: Colors.orange.withOpacity(0.02),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  number.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (stop.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      stop.subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: Icon(
                Icons.close,
                size: 20,
                color: AppColors.textSecondary,
              ),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  /// Build add intermediate stop button
  Widget _buildAddStopButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton.icon(
        onPressed: () {
          _showAddStopDialog();
        },
        icon: Icon(Icons.add, color: AppColors.primary),
        label: Text(
          'Add Intermediate Stop',
          style: TextStyle(color: AppColors.primary),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  /// Show dialog to add intermediate stop
  void _showAddStopDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Intermediate Stop'),
          content: SizedBox(
            width: double.maxFinite,
            child: LocationAutocompleteSearchBar(
              hintText: 'Search for intermediate stop',
              userLatitude: _userLatitude,
              userLongitude: _userLongitude,
              onLocationSelected: (location) {
                setState(() {
                  _intermediateStops.add(location);
                });
                Navigator.of(context).pop();
              },
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  /// Build travel dates card
  Widget _buildDatesCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Travel Dates',
                  style: AppTextStyles.h4.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    label: 'Start Date',
                    date: _startDate,
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    label: 'End Date',
                    date: _endDate,
                    onTap: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual date field
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
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.grey300),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.surface,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? '${date.day}/${date.month}/${date.year}'
                      : 'Select date',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: date != null
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build create journey button
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
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isGeneratingDetails 
                        ? 'Generating AI insights...'
                        : 'Creating journey...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Text(
                'Create Journey',
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // ==================== HELPER METHODS ====================

  /// Select date using date picker
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Clear end date if it's before start date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  /// Create journey with validation
  Future<void> _createJourney() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_sourceLocation == null) {
      _showError('Please select a starting location');
      return;
    }

    if (_destinationLocation == null) {
      _showError('Please select a destination');
      return;
    }

    if (_startDate == null || _endDate == null) {
      _showError('Please select travel dates');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create journey object
      final destinationNames = <String>[
        _sourceLocation!.title,
        ..._intermediateStops.map((stop) => stop.title),
        _destinationLocation!.title,
      ];

      final journey = Journey(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        isCompleted: false,
        destinations: destinationNames,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save journey first
      _journeyService.addJourney(journey);
      
      // Generate journey details using AI and wait for completion
      final journeyDetails = await _generateJourneyDetails(journey);
      
      if (mounted) {
        final message = journeyDetails != null 
            ? 'Journey created with AI insights!'
            : 'Journey created with default insights!';
        final bgColor = journeyDetails != null 
            ? Colors.green 
            : Colors.orange;
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: bgColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        Navigator.of(context).pop(true);
      }
      
    } catch (e) {
      _showError('Failed to create journey: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Generate journey details using AI and update the journey
  Future<JourneyDetailsData?> _generateJourneyDetails(Journey journey) async {
    JourneyDetailsData? journeyDetails;
    
    try {
      if (mounted) {
        setState(() {
          _isGeneratingDetails = true;
        });
      }
      
      debugPrint('🤖 Starting AI generation for journey: ${journey.title}');
      
      // Collect all journey locations (source, intermediate stops, destination)
      final allLocations = <LocationSuggestion>[
        if (_sourceLocation != null) _sourceLocation!,
        ..._intermediateStops,
        if (_destinationLocation != null) _destinationLocation!,
      ];
      
      debugPrint('📍 Journey locations: ${allLocations.map((l) => l.title).join(', ')}');
      
      // Generate with timeout to avoid long waits (increased for underrated places)
      journeyDetails = await _journeyDetailsService
          .generateJourneyDetails(journey, locations: allLocations)
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              debugPrint('⏰ AI generation timed out, using fallback data');
              return null;
            },
          );
      
      if (journeyDetails != null) {
        _journeyService.updateJourneyDetails(journey.id, journeyDetails);
        debugPrint('✅ AI journey details generated and saved successfully');
      } else {
        debugPrint('⚠️ AI generation failed (both package and HTTP methods), using dummy data fallback');
        // Ensure journey still has details by using dummy data as fallback
        _journeyService.updateJourneyDetails(journey.id, dummyJourneyDetails);
        debugPrint('💾 Dummy data fallback saved to journey');
      }
      
    } catch (e) {
      debugPrint('❌ Error generating journey details: $e');
      // On exception, also use dummy data as fallback
      _journeyService.updateJourneyDetails(journey.id, dummyJourneyDetails);
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingDetails = false;
        });
      }
    }
    
    return journeyDetails;
  }

  /// Show error message
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
}
