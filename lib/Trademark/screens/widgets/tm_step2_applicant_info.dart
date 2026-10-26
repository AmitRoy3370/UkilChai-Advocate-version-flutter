// lib/Trademark/screens/widgets/tm_step2_applicant_info.dart

import 'package:flutter/material.dart';

class TmStep2ApplicantInfo extends StatelessWidget {
  final TextEditingController applicationNameController;
  final TextEditingController mobileController;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final String? applicationType;
  final List<String> applicationTypes;

  final ValueChanged<String> onApplicationNameChanged;
  final ValueChanged<String> onMobileChanged;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onAddressChanged;
  final ValueChanged<String> onApplicationTypeChanged;

  final VoidCallback onBack;
  final VoidCallback onNext;

  const TmStep2ApplicantInfo({
    super.key,
    required this.applicationNameController,
    required this.mobileController,
    required this.emailController,
    required this.addressController,
    required this.applicationType,
    required this.applicationTypes,
    required this.onApplicationNameChanged,
    required this.onMobileChanged,
    required this.onEmailChanged,
    required this.onAddressChanged,
    required this.onApplicationTypeChanged,
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
            const Text('Applicant Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            _label('Applicant Type'),
            DropdownButtonFormField<String>(
              value: applicationType,
              decoration: _dec('Select type'),
              items: applicationTypes
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => onApplicationTypeChanged(v ?? ''),
            ),
            const SizedBox(height: 14),

            _label('Applicant Name'),
            TextFormField(
              controller: applicationNameController,
              decoration: _dec('Enter name'),
              onChanged: onApplicationNameChanged,
            ),
            const SizedBox(height: 14),

            _label('Mobile Number'),
            TextFormField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              decoration: _dec('01XXXXXXXXX'),
              onChanged: onMobileChanged,
            ),
            const SizedBox(height: 14),

            _label('Email Address'),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _dec('Enter email'),
              onChanged: onEmailChanged,
            ),
            const SizedBox(height: 14),

            _label('Address'),
            TextFormField(
              controller: addressController,
              maxLines: 3,
              decoration: _dec('Enter complete address'),
              onChanged: onAddressChanged,
            ),
            const SizedBox(height: 20),
            _navRow(onBack: onBack, onNext: onNext),
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
              const BorderSide(color: Color(0xFF6A1B9A), width: 1.5),
        ),
      );

  Widget _navRow({
    required VoidCallback onBack,
    required VoidCallback onNext,
  }) {
    return Row(
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
              backgroundColor: const Color(0xFF6A1B9A),
              minimumSize: const Size(0, 46),
            ),
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }
}