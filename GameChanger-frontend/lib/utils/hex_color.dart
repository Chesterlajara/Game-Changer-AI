import 'package:flutter/material.dart';

/// A utility class to convert hex color strings to Color objects
class HexColor extends Color {
  /// Creates a Color from a hex string (e.g. "FF0000" or "#FF0000")
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Creates a HexColor directly from a hex string (e.g. "FF0000" or "#FF0000")
  HexColor(final String hexString) : super(_getColorFromHex(hexString));

  /// Private helper to parse hex values
  static int _getColorFromHex(String hexString) {
    hexString = hexString.toUpperCase().replaceAll('#', '');
    if (hexString.length == 6) {
      hexString = 'FF' + hexString;
    }
    return int.parse(hexString, radix: 16);
  }
}
