// lib/Tin/screens/widgets/tin_step4_review_submit.dart

import 'package:flutter/material.dart';

class TinStep4ReviewSubmit extends StatefulWidget {
  final String fullName;
  final String dateOfBirth;
  final String mobile;
  final String email;
  final String address;
  final bool isSubmitting;
  final bool isUpdateMode;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const TinStep4ReviewSubmit({
    super.key,
    required this.fullName,
    required this.dateOfBirth,
    required this.mobile,
    required this.email,
    required this.address,
    required this.isSubmitting,
    required this.isUpdateMode,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  State<TinStep4ReviewSubmit> createState() => _TinStep4ReviewSubmitState();
}

class _TinStep4ReviewSubmitState extends State<TinStep4ReviewSubmit> {
  bool _confirmed = false;

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
            const Text('Review & Submit',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Information Summary',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            _row('Full Name', widget.fullName),
            _row('Date of Birth', widget.dateOfBirth),
            _row('Mobile Number', widget.mobile),
            _row('Email', widget.email),
            _row('Address', widget.address),
            const Divider(height: 32),

            // ✅ Confirmation checkbox
            CheckboxListTile(
              value: _confirmed,
              onChanged: (v) => setState(() => _confirmed = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFF1E7A3A),
              title: const Text(
                'I have checked all the information and it is correct.',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),

            if (widget.isSubmitting)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _confirmed ? widget.onSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E7A3A),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  widget.isUpdateMode ? 'Update Application' : 'Submit Application',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: widget.isSubmitting ? null : widget.onBack,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                side: BorderSide(color: Colors.grey.shade300),
                foregroundColor: Colors.black87,
              ),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(value.isEmpty ? '-' : value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}