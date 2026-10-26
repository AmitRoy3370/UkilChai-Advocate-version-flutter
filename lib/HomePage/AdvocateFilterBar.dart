
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../HomePage/AdvocateFilter.dart';
import '../RegistrationPage/gender.dart';
import '../Utils/AdvocateSpeciality.dart';

class AdvocateFilterBar extends StatefulWidget {
  final AdvocateFilter filter;
  final Function(AdvocateFilter) onFilterChanged;
  final List<String> locations;
  
  const AdvocateFilterBar({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    required this.locations,
  });

  @override
  State<AdvocateFilterBar> createState() => _AdvocateFilterBarState();
}

class _AdvocateFilterBarState extends State<AdvocateFilterBar> {
  late AdvocateFilter _filter;
  
  @override
  void initState() {
    super.initState();
    _filter = widget.filter;
  }

  @override
  void didUpdateWidget(AdvocateFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      setState(() {
        _filter = widget.filter;
      });
    }
  }

  void _updateFilter(AdvocateFilter newFilter) {
    setState(() {
      _filter = newFilter;
    });
    widget.onFilterChanged(newFilter);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Speciality',
                  value: _filter.speciality != null 
                      ? _getSpecialityLabel(_filter.speciality!) 
                      : 'All',
                  icon: Icons.work_outline,
                  onTap: () => _showSpecialityPicker(context),
                  isActive: _filter.speciality != null,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Location',
                  value: _filter.location ?? 'All',
                  icon: Icons.location_on_outlined,
                  onTap: () => _showLocationPicker(context),
                  isActive: _filter.location != null,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Gender',
                  value: _filter.gender != null 
                      ? _getGenderDisplayName(_filter.gender!) 
                      : 'All',
                  icon: _filter.gender != null 
                      ? _getGenderIcon(_filter.gender!) 
                      : Icons.person_outline,
                  iconColor: _filter.gender != null 
                      ? _getGenderColor(_filter.gender!) 
                      : null,
                  onTap: () => _showGenderPicker(context),
                  isActive: _filter.gender != null,
                ),
                if (_filter.isActive) ...[
                  const SizedBox(width: 8),
                  _buildClearChip(),
                ],
              ],
            ),
          ),
          
          // Active filters summary (only on small screens)
          if (isSmallScreen && _filter.isActive)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_filter.activeCount} filter${_filter.activeCount > 1 ? 's' : ''} active',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.shade600 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.green.shade600 : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : (iconColor ?? Colors.grey.shade600),
            ),
            const SizedBox(width: 6),
            Text(
              '$label: ',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white70 : Colors.grey.shade500,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: isActive ? Colors.white70 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearChip() {
    return GestureDetector(
      onTap: () {
        _updateFilter(AdvocateFilter());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.red.shade200,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.close,
              size: 14,
              color: Colors.red.shade400,
            ),
            const SizedBox(width: 4),
            Text(
              'Clear All',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ PICKER METHODS ============
  
  void _showSpecialityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Speciality',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a legal speciality to filter advocates',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildPickerItem(
                      title: 'All Specialities',
                      isSelected: _filter.speciality == null,
                      onTap: () {
                        Navigator.pop(context);
                        _updateFilter(_filter.copyWith(speciality: null));
                      },
                    ),
                    ...AdvocateSpeciality.values.map(
                      (s) => _buildPickerItem(
                        title: s.label,
                        icon: s.icon,
                        isSelected: _filter.speciality == s.apiValue,
                        onTap: () {
                          Navigator.pop(context);
                          _updateFilter(_filter.copyWith(speciality: s.apiValue));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLocationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Location',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a district to find advocates near you',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildPickerItem(
                      title: 'All Locations',
                      isSelected: _filter.location == null,
                      onTap: () {
                        Navigator.pop(context);
                        _updateFilter(_filter.copyWith(location: null));
                      },
                    ),
                    ...widget.locations.map(
                      (loc) => _buildPickerItem(
                        title: loc,
                        isSelected: _filter.location == loc,
                        onTap: () {
                          Navigator.pop(context);
                          _updateFilter(_filter.copyWith(location: loc));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGenderPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Gender',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Filter advocates by gender',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildPickerItem(
                      title: 'All Genders',
                      isSelected: _filter.gender == null,
                      onTap: () {
                        Navigator.pop(context);
                        _updateFilter(_filter.copyWith(gender: null));
                      },
                    ),
                    ...Gender.values.map(
                      (g) => _buildPickerItem(
                        title: _getGenderDisplayName(g),
                        icon: _getGenderIcon(g),
                        iconColor: _getGenderColor(g),
                        isSelected: _filter.gender == g,
                        onTap: () {
                          Navigator.pop(context);
                          _updateFilter(_filter.copyWith(gender: g));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPickerItem({
    required String title,
    IconData? icon,
    Color? iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: icon != null
          ? Icon(icon, color: iconColor ?? Colors.green)
          : null,
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? Colors.green.shade700 : Colors.grey[800],
        ),
      ),
      trailing: isSelected
          ? Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 16, color: Colors.white),
            )
          : null,
      onTap: onTap,
    );
  }

  // ============ HELPER METHODS ============
  
  String _getSpecialityLabel(String apiValue) {
    for (var s in AdvocateSpeciality.values) {
      if (s.apiValue == apiValue) {
        return s.label;
      }
    }
    return apiValue;
  }

  String _getGenderDisplayName(Gender gender) {
    switch (gender) {
      case Gender.MALE: return 'Male';
      case Gender.FEMALE: return 'Female';
      case Gender.OTHER: return 'Other';
    }
  }

  IconData _getGenderIcon(Gender gender) {
    switch (gender) {
      case Gender.MALE: return Icons.male;
      case Gender.FEMALE: return Icons.female;
      case Gender.OTHER: return Icons.transgender;
    }
  }

  Color _getGenderColor(Gender gender) {
    switch (gender) {
      case Gender.MALE: return Colors.blue;
      case Gender.FEMALE: return Colors.pink;
      case Gender.OTHER: return Colors.purple;
    }
  }
}