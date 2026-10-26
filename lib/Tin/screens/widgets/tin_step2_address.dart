// lib/Tin/screens/widgets/tin_step2_address.dart

import 'package:flutter/material.dart';

class TinStep2Address extends StatelessWidget {
  final String? presentDivision;
  final String? presentDistrict;
  final String? presentUpazila;
  final String? permanentDivision;
  final String? permanentDistrict;
  final String? permanentUpazila;

  final List<String> divisions;
  final List<String> districts;
  final List<String> upazilas;

  final ValueChanged<String?> onPresentDivisionChanged;
  final ValueChanged<String?> onPresentDistrictChanged;
  final ValueChanged<String?> onPresentUpazilaChanged;
  final ValueChanged<String?> onPermanentDivisionChanged;
  final ValueChanged<String?> onPermanentDistrictChanged;
  final ValueChanged<String?> onPermanentUpazilaChanged;

  final VoidCallback onBack;
  final VoidCallback onNext;

  const TinStep2Address({
    super.key,
    required this.presentDivision,
    required this.presentDistrict,
    required this.presentUpazila,
    required this.permanentDivision,
    required this.permanentDistrict,
    required this.permanentUpazila,
    required this.divisions,
    required this.districts,
    required this.upazilas,
    required this.onPresentDivisionChanged,
    required this.onPresentDistrictChanged,
    required this.onPresentUpazilaChanged,
    required this.onPermanentDivisionChanged,
    required this.onPermanentDistrictChanged,
    required this.onPermanentUpazilaChanged,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Present & Permanent Address',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // ---------------- Present Address ----------------
            const Text('Present Address',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E7A3A))),
            const SizedBox(height: 10),

            _label('Division'),
            _dropdown(
              value: presentDivision,
              hint: 'Select division',
              items: divisions,
              onChanged: onPresentDivisionChanged,
            ),
            const SizedBox(height: 12),

            _label('District'),
            _dropdown(
              value: presentDistrict,
              hint: 'Select district',
              items: districts,
              onChanged: onPresentDistrictChanged,
            ),
            const SizedBox(height: 12),

            _label('Upazila'),
            _dropdown(
              value: presentUpazila,
              hint: 'Select upazila',
              items: upazilas,
              onChanged: onPresentUpazilaChanged,
            ),

            const Divider(height: 32),

            // ---------------- Permanent Address ----------------
            const Text('Permanent Address',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E7A3A))),
            const SizedBox(height: 10),

            _label('Division'),
            _dropdown(
              value: permanentDivision,
              hint: 'Select division',
              items: divisions,
              onChanged: onPermanentDivisionChanged,
            ),
            const SizedBox(height: 12),

            _label('District'),
            _dropdown(
              value: permanentDistrict,
              hint: 'Select district',
              items: districts,
              onChanged: onPermanentDistrictChanged,
            ),
            const SizedBox(height: 12),

            _label('Upazila'),
            _dropdown(
              value: permanentUpazila,
              hint: 'Select upazila',
              items: upazilas,
              onChanged: onPermanentUpazilaChanged,
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      side: BorderSide(color: Colors.grey.shade300),
                      foregroundColor: Colors.black87,
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E7A3A),
                      minimumSize: const Size(0, 46),
                    ),
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF1E7A3A), width: 1.5),
        ),
      ),
      hint: Text(hint, style: const TextStyle(fontSize: 13)),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}