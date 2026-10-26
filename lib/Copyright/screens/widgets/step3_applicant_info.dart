// lib/Copyright/screens/widgets/step3_applicant_info.dart

import 'package:flutter/material.dart';

class Step3ApplicantInfo extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController mobileController;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onMobileChanged;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onAddressChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const Step3ApplicantInfo({
    super.key,
    required this.nameController,
    required this.mobileController,
    required this.emailController,
    required this.addressController,
    required this.onNameChanged,
    required this.onMobileChanged,
    required this.onEmailChanged,
    required this.onAddressChanged,
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

            _label('Applicant Name'),
            TextFormField(
              controller: nameController,
              decoration: _dec('Enter name'),
              onChanged: onNameChanged,
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
                      backgroundColor: const Color(0xFF1A3FBF),
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

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
          borderSide: const BorderSide(color: Color(0xFF1A3FBF), width: 1.5),
        ),
      );
}