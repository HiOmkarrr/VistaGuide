import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/services/journey_service.dart';
import '../../data/models/journey.dart';
import '../localWidgets/journey_detail_tabs/overview_tab.dart';
import '../localWidgets/journey_detail_tabs/safety_weather_tab.dart';
import '../localWidgets/journey_detail_tabs/suggestions_packing_tab.dart';

/// Page for viewing journey details
class JourneyDetailsPage extends StatefulWidget {
  final String journeyId;

  const JourneyDetailsPage({
    super.key,
    required this.journeyId,
  });

  @override
  State<JourneyDetailsPage> createState() => _JourneyDetailsPageState();
}

class _JourneyDetailsPageState extends State<JourneyDetailsPage>
    with SingleTickerProviderStateMixin {
  final _journeyService = JourneyService();
  Journey? _journey;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadJourney();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadJourney() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final journey = await _journeyService.getJourneyById(widget.journeyId);
      
      setState(() {
        _journey = journey;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading journey: $e');
      setState(() {
        _journey = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const CustomAppBar(
          title: 'Journey Details',
          showBackButton: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }
    
    if (_journey == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const CustomAppBar(
          title: 'Journey Details',
          showBackButton: true,
        ),
        body: const Center(
          child: Text('Journey not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: _journey!.title,
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editJourney,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusBanner(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                OverviewTab(journey: _journey!),
                SafetyWeatherTab(journey: _journey!),
                SuggestionsPackingTab(journey: _journey!),
              ],
            ),
          ),
          if (!_journey!.isCompleted)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildActionButtons(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    Color backgroundColor;
    String status;

    if (_journey!.isCompleted) {
      backgroundColor = AppColors.success;
      status = 'Completed';
    } else if (_journey!.isCurrent) {
      backgroundColor = AppColors.primary;
      status = 'Ongoing';
    } else if (_journey!.isUpcoming) {
      backgroundColor = AppColors.info;
      status = 'Upcoming';
    } else {
      backgroundColor = AppColors.grey600;
      status = 'Past';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: backgroundColor,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.bodyMedium,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Safety & Weather'),
          Tab(text: 'Suggestions & Packing'),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _markAsCompleted,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle),
                const SizedBox(width: 8),
                Text(
                  'Mark as Completed',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _deleteJourney,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.emergency),
              foregroundColor: AppColors.emergency,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.delete_outline),
                const SizedBox(width: 8),
                Text(
                  'Delete Journey',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _editJourney() {
    // TODO: Navigate to edit journey page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit journey feature coming soon!'),
      ),
    );
  }

  void _markAsCompleted() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Completed'),
        content: const Text(
            'Are you sure you want to mark this journey as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _journeyService.markJourneyAsCompleted(widget.journeyId);
                Navigator.of(context).pop();
                await _loadJourney(); // Reload to update UI
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Journey marked as completed!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error marking journey as completed: $e'),
                    backgroundColor: AppColors.emergency,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Mark Completed'),
          ),
        ],
      ),
    );
  }

  void _deleteJourney() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Journey'),
        content: const Text(
          'Are you sure you want to delete this journey? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _journeyService.deleteJourney(widget.journeyId);
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to journey list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Journey deleted successfully'),
                    backgroundColor: AppColors.emergency,
                  ),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting journey: $e'),
                    backgroundColor: AppColors.emergency,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergency,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
