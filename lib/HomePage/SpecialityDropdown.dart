import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Utils/AdvocateSpeciality.dart';

class SpecialityDropdown extends StatefulWidget {
  final Function(String?) onSpecialitySelected;
  final String? selectedSpeciality;
  
  const SpecialityDropdown({
    super.key,
    required this.onSpecialitySelected,
    this.selectedSpeciality,
  });

  @override
  State<SpecialityDropdown> createState() => _SpecialityDropdownState();
}

class _SpecialityDropdownState extends State<SpecialityDropdown> {
  late String? _selectedSpeciality;
  late String _selectedLabel;

  @override
  void initState() {
    super.initState();
    _selectedSpeciality = widget.selectedSpeciality;
    _updateLabel();
  }

  @override
  void didUpdateWidget(SpecialityDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSpeciality != widget.selectedSpeciality) {
      setState(() {
        _selectedSpeciality = widget.selectedSpeciality;
        _updateLabel();
      });
    }
  }

  void _updateLabel() {
    if (_selectedSpeciality != null && _selectedSpeciality!.isNotEmpty) {
      final selected = _specialities.firstWhere(
        (item) => item['value'] == _selectedSpeciality,
        orElse: () => {'label': 'Filter'},
      );
      _selectedLabel = selected['label'] ?? 'Filter';
    } else {
      _selectedLabel = 'Filter';
    }
  }

  List<Map<String, dynamic>> get _specialities {
    final list = [
      {'value': null, 'label': 'All Specialities', 'icon': Icons.all_inclusive},
    ];
    
    for (var speciality in AdvocateSpeciality.values) {
      list.add({
        'value': speciality.apiValue,
        'label': speciality.label,
        'icon': speciality.icon,
      });
    }
    
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 30),
      onSelected: (String value) {
        setState(() {
          final selected = _specialities.firstWhere(
            (item) => item['value']?.toString() == value,
            orElse: () => {'label': 'Filter'},
          );
          _selectedLabel = selected['label'] ?? 'Filter';
          _selectedSpeciality = value == 'null' ? null : value;
        });
        
        final specialityValue = value == 'null' ? null : value;
        print("🔍 Filter selected: ${specialityValue ?? 'All Specialities'}");
        widget.onSpecialitySelected(specialityValue);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list,
              size: 16,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              _selectedLabel,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
      itemBuilder: (context) {
        return _specialities.map((item) {
          final value = item['value']?.toString() ?? 'null';
          // 🔥 সঠিকভাবে তুলনা করুন
          final isSelected = _selectedSpeciality == item['value'];
          
          return PopupMenuItem<String>(
            value: value,
            child: Row(
              children: [
                Icon(
                  item['icon'],
                  size: 16,
                  color: isSelected ? Colors.green : Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['label'],
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isSelected ? Colors.green : Colors.grey.shade800,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green,
                  ),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}