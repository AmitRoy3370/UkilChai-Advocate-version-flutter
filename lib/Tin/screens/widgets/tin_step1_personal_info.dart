// lib/Tin/screens/widgets/tin_step1_personal_info.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TinStep1PersonalInfo extends StatelessWidget {
  final TextEditingController fullNameController;
  final TextEditingController fatherNameController;
  final TextEditingController motherNameController;
  final TextEditingController dateOfBirthController;
  final TextEditingController mobileController;

  final ValueChanged<String> onFullNameChanged;
  final ValueChanged<String> onFatherNameChanged;
  final ValueChanged<String> onMotherNameChanged;
  final ValueChanged<DateTime> onDateOfBirthChanged;
  final ValueChanged<String> onMobileChanged;

  final VoidCallback onBack;
  final VoidCallback onNext;

  const TinStep1PersonalInfo({
    super.key,
    required this.fullNameController,
    required this.fatherNameController,
    required this.motherNameController,
    required this.dateOfBirthController,
    required this.mobileController,
    required this.onFullNameChanged,
    required this.onFatherNameChanged,
    required this.onMotherNameChanged,
    required this.onDateOfBirthChanged,
    required this.onMobileChanged,
    required this.onBack,
    required this.onNext,
  });

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1E7A3A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      dateOfBirthController.text = DateFormat('dd/MM/yyyy').format(picked);
      onDateOfBirthChanged(picked);
    }
  }

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
            const Text('Personal Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            _label('Full Name'),
            TextFormField(
              controller: fullNameController,
              decoration: _dec('Enter full name'),
              onChanged: onFullNameChanged,
            ),
            const SizedBox(height: 14),

            _label("Father's Name"),
            TextFormField(
              controller: fatherNameController,
              decoration: _dec("Enter father's name"),
              onChanged: onFatherNameChanged,
            ),
            const SizedBox(height: 14),

            _label("Mother's Name"),
            TextFormField(
              controller: motherNameController,
              decoration: _dec("Enter mother's name"),
              onChanged: onMotherNameChanged,
            ),
            const SizedBox(height: 14),

            _label('Date of Birth'),
            TextFormField(
              controller: dateOfBirthController,
              readOnly: true,
              onTap: () => _pickDate(context),
              decoration: _dec('DD / MM / YYYY').copyWith(
                suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 14),

            _label('Mobile Number'),
            TextFormField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              decoration: _dec('01XXXXXXXXX'),
              onChanged: onMobileChanged,
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

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
      );
}