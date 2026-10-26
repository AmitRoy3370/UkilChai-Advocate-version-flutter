// lib/Copyright/screens/widgets/step_indicator.dart

import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> titles;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.titles,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top label: "STEP X"
        Text(
          'STEP ${currentStep + 1}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: Color(0xFF1A3FBF),
          ),
        ),
        const SizedBox(height: 4),
        // Title
        Text(
          titles[currentStep].toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        // Circles with connectors
        Row(
          children: List.generate(totalSteps * 2 - 1, (index) {
            if (index.isEven) {
              final stepIdx = index ~/ 2;
              final isCompleted = stepIdx < currentStep;
              final isActive = stepIdx == currentStep;
              return Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted || isActive
                      ? const Color(0xFF1A3FBF)
                      : Colors.white,
                  border: Border.all(
                    color: isCompleted || isActive
                        ? const Color(0xFF1A3FBF)
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check,
                          color: Colors.white, size: 16)
                      : Text(
                          '${stepIdx + 1}',
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
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
                      ? const Color(0xFF1A3FBF)
                      : Colors.grey.shade300,
                ),
              );
            }
          }),
        ),
      ],
    );
  }
}