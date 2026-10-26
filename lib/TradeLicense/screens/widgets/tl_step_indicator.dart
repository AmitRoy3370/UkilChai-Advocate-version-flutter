// lib/TradeLicense/screens/widgets/tl_step_indicator.dart

import 'package:flutter/material.dart';

class TlStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const TlStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (index) {
          if (index.isEven) {
            final stepIdx = index ~/ 2;
            final isCompleted = stepIdx < currentStep;
            final isActive = stepIdx == currentStep;
            return Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isCompleted || isActive
                    ? const Color(0xFF1E7A3A)
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted || isActive
                      ? const Color(0xFF1E7A3A)
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      '${stepIdx + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
            );
          } else {
            final leftIdx = index ~/ 2;
            final isCompleted = leftIdx < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted
                    ? const Color(0xFF1E7A3A)
                    : Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
            );
          }
        }),
      ),
    );
  }
}