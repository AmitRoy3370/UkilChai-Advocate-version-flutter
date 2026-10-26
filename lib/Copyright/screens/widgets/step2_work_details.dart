// lib/Copyright/screens/widgets/step2_work_details.dart

import 'package:flutter/material.dart';

class Step2WorkDetails extends StatelessWidget {
  final String typeOfWork;
  final TextEditingController titleController;
  final TextEditingController authorController;
  final TextEditingController yearController;
  final TextEditingController descController;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onAuthorChanged;
  final ValueChanged<String> onYearChanged;
  final ValueChanged<String> onDescChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const Step2WorkDetails({
    super.key,
    required this.typeOfWork,
    required this.titleController,
    required this.authorController,
    required this.yearController,
    required this.descController,
    required this.onTypeChanged,
    required this.onTitleChanged,
    required this.onAuthorChanged,
    required this.onYearChanged,
    required this.onDescChanged,
    required this.onBack,
    required this.onNext,
  });

  static const _workTypes = [
    'Literary',
    'Artistic',
    'Musical',
    'Software',
    'Film',
    'Other',
  ];

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
            const Text('Work Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            _label('Type of Work'),
            DropdownButtonFormField<String>(
              value: typeOfWork.isEmpty ? null : typeOfWork,
              decoration: _inputDecoration('Select type'),
              items: _workTypes
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => onTypeChanged(v ?? ''),
            ),
            const SizedBox(height: 14),

            _label('Title of Work'),
            TextFormField(
              controller: titleController,
              decoration: _inputDecoration('Enter title'),
              onChanged: onTitleChanged,
            ),
            const SizedBox(height: 14),

            _label('Author / Creator Name'),
            TextFormField(
              controller: authorController,
              decoration: _inputDecoration('Enter name'),
              onChanged: onAuthorChanged,
            ),
            const SizedBox(height: 14),

            _label('Year of Creation'),
            TextFormField(
              controller: yearController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('YYYY'),
              onChanged: onYearChanged,
            ),
            const SizedBox(height: 14),

            _label('Description'),
            TextFormField(
              controller: descController,
              maxLines: 3,
              decoration: _inputDecoration('Describe your work'),
              onChanged: onDescChanged,
            ),
            const SizedBox(height: 20),

            _navRow(onBack, onNext, nextLabel: 'Next'),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
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

  Widget _navRow(VoidCallback onBack, VoidCallback onNext,
      {required String nextLabel}) {
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
              backgroundColor: const Color(0xFF1A3FBF),
              minimumSize: const Size(0, 46),
            ),
            child: Text(nextLabel),
          ),
        ),
      ],
    );
  }
}