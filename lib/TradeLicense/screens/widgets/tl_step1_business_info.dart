// lib/TradeLicense/screens/widgets/tl_step1_business_info.dart

import 'package:flutter/material.dart';

class TlStep1BusinessInfo extends StatelessWidget {
  final TextEditingController businessNameController;
  final TextEditingController ownerNameController;
  final TextEditingController mobileController;
  final TextEditingController emailController;
  final String? selectedBusinessType;
  final String? selectedBusinessCategory;

  final List<String> businessTypes;
  final List<String> businessCategories;

  final ValueChanged<String> onBusinessNameChanged;
  final ValueChanged<String> onOwnerNameChanged;
  final ValueChanged<String> onMobileChanged;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onBusinessTypeChanged;
  final ValueChanged<String> onBusinessCategoryChanged;

  final VoidCallback onBack;
  final VoidCallback onNext;

  const TlStep1BusinessInfo({
    super.key,
    required this.businessNameController,
    required this.ownerNameController,
    required this.mobileController,
    required this.emailController,
    required this.selectedBusinessType,
    required this.selectedBusinessCategory,
    required this.businessTypes,
    required this.businessCategories,
    required this.onBusinessNameChanged,
    required this.onOwnerNameChanged,
    required this.onMobileChanged,
    required this.onEmailChanged,
    required this.onBusinessTypeChanged,
    required this.onBusinessCategoryChanged,
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
            const Text('Business Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            _label('Business Name'),
            TextFormField(
              controller: businessNameController,
              decoration: _dec('Enter business name'),
              onChanged: onBusinessNameChanged,
            ),
            const SizedBox(height: 14),

            _label('Owner Name'),
            TextFormField(
              controller: ownerNameController,
              decoration: _dec('Enter owner name'),
              onChanged: onOwnerNameChanged,
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
              decoration: _dec('Enter email address'),
              onChanged: onEmailChanged,
            ),
            const SizedBox(height: 14),

            _label('Business Type'),
            DropdownButtonFormField<String>(
              value: selectedBusinessType,
              decoration: _dec('Select business type'),
              items: businessTypes
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => onBusinessTypeChanged(v ?? ''),
            ),
            const SizedBox(height: 14),

            _label('Business Category'),
            DropdownButtonFormField<String>(
              value: selectedBusinessCategory,
              decoration: _dec('Select category'),
              items: businessCategories
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => onBusinessCategoryChanged(v ?? ''),
            ),

            const SizedBox(height: 20),
            _navRow(onBack: onBack, onNext: onNext, nextLabel: 'Next'),
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

  Widget _navRow({
    required VoidCallback onBack,
    required VoidCallback onNext,
    required String nextLabel,
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
              backgroundColor: const Color(0xFF1E7A3A),
              minimumSize: const Size(0, 46),
            ),
            child: Text(nextLabel),
          ),
        ),
      ],
    );
  }
}