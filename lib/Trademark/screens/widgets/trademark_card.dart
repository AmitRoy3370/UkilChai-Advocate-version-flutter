// lib/Trademark/screens/widgets/trademark_card.dart

import 'package:flutter/material.dart';
import '../../models/trademark_response_dto.dart';

class TrademarkCard extends StatelessWidget {
  final TrademarkResponse trademark;
  final VoidCallback onTap;
  final bool showStatusBadge;

  const TrademarkCard({
    super.key,
    required this.trademark,
    required this.onTap,
    this.showStatusBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final process = trademark.registrationProcess;
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
                      color: const Color(0xFF6A1B9A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.verified,
                        color: Color(0xFF6A1B9A), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trademark.trademarkName.isEmpty
                              ? 'Untitled'
                              : trademark.trademarkName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          trademark.trademarkType.isEmpty
                              ? 'Unknown type'
                              : trademark.trademarkType,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
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
              _row('Applicant', trademark.userName),
              const SizedBox(height: 4),
              _row('Class', trademark.classOfGoods),
              const SizedBox(height: 4),
              _row('Organization', trademark.organaizationalName),
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
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}