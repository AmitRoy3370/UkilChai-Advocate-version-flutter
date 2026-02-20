import 'package:flutter/material.dart';

class TimelineStep {
  String title;
  String subtitle;
  String? date;
  IconData icon;
  Color color;
  bool completed;
  double? price;

  TimelineStep({
    required this.title,
    required this.subtitle,
    this.date,
    required this.icon,
    required this.color,
    required this.completed,
    this.price,
  });
}
