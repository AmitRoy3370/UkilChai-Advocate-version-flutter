// lib/Copyright/widgets/copyright_card.dart

import 'package:flutter/material.dart';
import '../../models/copyright_response_dto.dart';

class CopyrightCard extends StatelessWidget {
  final CopyrightResponseDTO copyright;
  final VoidCallback onTap;
  final bool showStatusBadge;

  const CopyrightCard({
    super.key,
    required this.copyright,
    required this.onTap,
    this.showStatusBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final process = copyright.registrationProcess;
    final isApproved = process != null && process.status == true;
    final isPending = process == null;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A3FBF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.copyright,
                        color: Color(0xFF1A3FBF), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          copyright.titleOfWork.isEmpty
                              ? 'Untitled'
                              : copyright.titleOfWork,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          copyright.typeOfWork.isEmpty
                              ? 'Unknown type'
                              : copyright.typeOfWork,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showStatusBadge) _statusBadge(isApproved, isPending),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              _row('Author', copyright.author),
              const SizedBox(height: 4),
              _row('Applicant', copyright.userName),
              const SizedBox(height: 4),
              _row('Year', copyright.yearOfCreation.year.toString()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(bool isApproved, bool isPending) {
    final color = isApproved
        ? const Color(0xFF2E7D32)
        : (isPending ? const Color(0xFFE65100) : Colors.grey);
    final label = isApproved
        ? 'Approved'
        : (isPending ? 'Pending' : 'Unknown');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}