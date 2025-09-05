import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/location_autocomplete_service.dart';
import 'dart:async';

/// Autocomplete search bar widget with location suggestions
class LocationAutocompleteSearchBar extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;
  final Function(LocationSuggestion)? onLocationSelected;
  final Function(String)? onTextChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final double? userLatitude;
  final double? userLongitude;

  const LocationAutocompleteSearchBar({
    super.key,
    required this.hintText,
    this.controller,
    this.onLocationSelected,
    this.onTextChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.userLatitude,
    this.userLongitude,
  });

  @override
  State<LocationAutocompleteSearchBar> createState() =>
      _LocationAutocompleteSearchBarState();
}

class _LocationAutocompleteSearchBarState
    extends State<LocationAutocompleteSearchBar> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<LocationSuggestion> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _overlayEntry?.remove();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && _controller.text.isNotEmpty) {
      _showSuggestions();
    } else {
      _hideSuggestions();
    }
  }

  void _onTextChanged(String value) {
    widget.onTextChanged?.call(value);

    // Cancel previous timer
    _debounceTimer?.cancel();

    if (value.trim().isEmpty) {
      _hideSuggestions();
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      return;
    }

    // Show loading state immediately
    setState(() {
      _isLoading = true;
    });

    // Update overlay to show loading if it's already visible
    if (_overlayEntry != null) {
      _showSuggestions(); // This will refresh the overlay
    }

    // Debounce the search
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchLocations(value);
    });
  }

  Future<void> _searchLocations(String query) async {
    if (!mounted) return;

    try {
      final suggestions = await LocationAutocompleteService.getSuggestions(
        query,
        userLatitude: widget.userLatitude,
        userLongitude: widget.userLongitude,
        maxResults: 8,
      );

      if (mounted) {
        print(
            '🔍 Search completed for "$query": Found ${suggestions.length} suggestions');
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });

        if ((suggestions.isNotEmpty || _isLoading) && _focusNode.hasFocus) {
          _showSuggestions();
        } else {
          _hideSuggestions();
        }
      }
    } catch (e) {
      print('❌ Error searching locations: $e');
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
        _hideSuggestions();
      }
    }
  }

  void _showSuggestions() {
    if (!_isLoading && _suggestions.isEmpty) return;

    // Remove existing overlay if it exists
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }

    // Create and insert new overlay
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestions() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 4.0),
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey300, width: 1),
              ),
              child: _buildSuggestionsList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (_isLoading) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        child: Text(
          'No locations found',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _suggestions.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        color: AppColors.grey200,
      ),
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return _buildSuggestionTile(suggestion);
      },
    );
  }

  Widget _buildSuggestionTile(LocationSuggestion suggestion) {
    return InkWell(
      onTap: () => _onSuggestionTapped(suggestion),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              _getLocationIcon(suggestion.type),
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (suggestion.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      suggestion.subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getLocationIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'city':
        return Icons.location_city;
      case 'airport':
        return Icons.flight;
      case 'station':
        return Icons.train;
      case 'attraction':
      case 'place':
        return Icons.place;
      case 'hotel':
        return Icons.hotel;
      case 'museum':
        return Icons.museum;
      case 'park':
        return Icons.park;
      case 'monument':
        return Icons.account_balance;
      case 'religious_site':
        return Icons.temple_buddhist;
      case 'entertainment':
        return Icons.theater_comedy;
      case 'address':
        return Icons.home;
      default:
        return Icons.location_on;
    }
  }

  void _onSuggestionTapped(LocationSuggestion suggestion) {
    _controller.text = suggestion.title;
    _hideSuggestions();
    _focusNode.unfocus();
    widget.onLocationSelected?.call(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          onChanged: _onTextChanged,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: AppTextStyles.searchHint,
            prefixIcon: widget.prefixIcon ??
                const Icon(Icons.search, color: AppColors.textHint),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : widget.suffixIcon,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.grey300),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }
}
