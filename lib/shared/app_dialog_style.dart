import 'package:flutter/material.dart';

class AppDialogStyle {
  static const Color background = Color(0xFFF1F2ED);
  static const Color text = Color(0xFF44403B);
  static const Color mutedText = Color(0xFF605A55);
  static const Color border = Color(0xFFE7E5E4);

  static const double radius = 24;
  static const EdgeInsets insetPadding =
      EdgeInsets.symmetric(horizontal: 24, vertical: 24);
  static const EdgeInsets contentPadding = EdgeInsets.all(20);
  static const EdgeInsets titlePadding = EdgeInsets.fromLTRB(20, 20, 20, 0);
  static const EdgeInsets actionsPadding = EdgeInsets.fromLTRB(0, 0, 16, 16);

  static RoundedRectangleBorder shape() {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
  }
}
