import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/services/journey_service.dart';
import '../../data/models/journey.dart';

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

class _JourneyDetailsPageState extends State<JourneyDetailsPage> {
  final _journeyService = JourneyService();
  Journey? _journey;

  @override
  void initState() {
    super.initState();
    _loadJourney();
  }

  void _loadJourney() {
    final journey = _journeyService.getJourneyById(widget.journeyId);
    setState(() {
      _journey = journey;
    });
  }

  @override
  Widget build(BuildContext context) {
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(),
              const SizedBox(height: 16),
              _buildDetailsCard(),
              const SizedBox(height: 16),
              _buildDestinationsCard(),
              const SizedBox(height: 16),
              _buildDateCard(),
              const SizedBox(height: 24),
              if (!_journey!.isCompleted) _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color backgroundColor;
    Color textColor;
    String status;
    IconData icon;

    if (_journey!.isCompleted) {
      backgroundColor = AppColors.success.withValues(alpha: 0.1);
      textColor = AppColors.success;
      status = 'Completed';
      icon = Icons.check_circle;
    } else if (_journey!.isCurrent) {
      backgroundColor = AppColors.primary.withValues(alpha: 0.1);
      textColor = AppColors.primary;
      status = 'Ongoing';
      icon = Icons.flight_takeoff;
    } else if (_journey!.isUpcoming) {
      backgroundColor = AppColors.info.withValues(alpha: 0.1);
      textColor = AppColors.info;
      status = 'Upcoming';
      icon = Icons.schedule;
    } else {
      backgroundColor = AppColors.grey200;
      textColor = AppColors.grey600;
      status = 'Past';
      icon = Icons.history;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: textColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: textColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: AppTextStyles.h3.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusDescription(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: textColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return _buildCard(
      title: 'Journey Details',
      icon: Icons.info_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _journey!.description,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Duration',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_journey!.durationInDays} ${_journey!.durationInDays == 1 ? 'day' : 'days'}',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationsCard() {
    return _buildCard(
      title: 'Destinations',
      icon: Icons.place,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_journey!.destinations.length} ${_journey!.destinations.length == 1 ? 'destination' : 'destinations'}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...(_journey!.destinations.asMap().entries.map(
                (entry) => _buildDestinationItem(
                  entry.value,
                  entry.key + 1,
                  entry.key == _journey!.destinations.length - 1,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDestinationItem(String destination, int index, bool isLast) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              destination,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard() {
    return _buildCard(
      title: 'Travel Dates',
      icon: Icons.calendar_today,
      child: Column(
        children: [
          _buildDateRow(
            'Start Date',
            _journey!.startDate,
            Icons.flight_takeoff,
          ),
          const SizedBox(height: 16),
          _buildDateRow(
            'End Date',
            _journey!.endDate,
            Icons.flight_land,
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(String label, DateTime date, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(date),
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey300.withValues(alpha: 0.3),
            blurRadius: 8,
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
                icon,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
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

  String _getStatusDescription() {
    if (_journey!.isCompleted) {
      return 'This journey has been completed';
    } else if (_journey!.isCurrent) {
      return 'Currently in progress';
    } else if (_journey!.isUpcoming) {
      final daysUntil = _journey!.startDate.difference(DateTime.now()).inDays;
      return 'Starts in $daysUntil ${daysUntil == 1 ? 'day' : 'days'}';
    } else {
      return 'This journey has ended';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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
            onPressed: () {
              _journeyService.markJourneyAsCompleted(widget.journeyId);
              Navigator.of(context).pop();
              _loadJourney(); // Reload to update UI
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Journey marked as completed!'),
                  backgroundColor: AppColors.success,
                ),
              );
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
            onPressed: () {
              _journeyService.deleteJourney(widget.journeyId);
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to journey list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Journey deleted successfully'),
                  backgroundColor: AppColors.emergency,
                ),
              );
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
