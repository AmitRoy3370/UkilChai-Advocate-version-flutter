// lib/vat/screens/widgets/vat_step_indicator.dart

import 'package:flutter/material.dart';

class VatStepIndicator extends StatelessWidget {
  final int currentStep; // 1-based (1..4)
  final int totalSteps;  // 4
  final List<String> labels;

  const VatStepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
    this.labels = const [
      'BUSINESS INFORMATION',
      'BUSINESS DETAILS',
      'UPLOAD DOCUMENTS',
      'REVIEW & PAYMENT',
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final stepNum = index + 1;
          final isActive = stepNum == currentStep;
          final isDone = stepNum < currentStep;

          return Expanded(
            child: Row(
              children: [
                // Circle + label
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? const Color(0xFF1565C0)
                              : isDone
                                  ? const Color(0xFF1565C0).withOpacity(0.3)
                                  : Colors.grey.shade300,
                          border: isActive
                              ? Border.all(
                                  color: const Color(0xFF1565C0), width: 2)
                              : null,
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : Text(
                                  '$stepNum',
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.w500,
                          color: isActive
                              ? const Color(0xFF1565C0)
                              : Colors.grey.shade600,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Connector
                if (index < totalSteps - 1)
                  Container(
                    width: 20,
                    height: 2,
                    color: isDone
                        ? const Color(0xFF1565C0)
                        : Colors.grey.shade300,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}