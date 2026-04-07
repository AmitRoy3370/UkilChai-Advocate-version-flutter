import 'package:flutter/cupertino.dart';

class ResponsiveHelper {
  static double width(BuildContext context, {double percentage = 1}) {
    return MediaQuery.of(context).size.width * percentage;
  }

  static double height(BuildContext context, {double percentage = 1}) {
    return MediaQuery.of(context).size.height * percentage;
  }

  static double fontSize(BuildContext context, double size) {
    double scale = MediaQuery.of(context).size.width / 400;
    return size * scale.clamp(0.8, 1.5);
  }

  static double padding(BuildContext context, double size) {
    double scale = MediaQuery.of(context).size.width / 400;
    return size * scale.clamp(0.8, 1.5);
  }

  static double iconSize(BuildContext context, double size) {
    double scale = MediaQuery.of(context).size.width / 400;
    return size * scale.clamp(0.8, 1.3);
  }

  static double buttonHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.065;
  }

  static double cardRadius(BuildContext context) {
    double scale = MediaQuery.of(context).size.width / 400;
    return (16 * scale).clamp(8, 24);
  }
}
