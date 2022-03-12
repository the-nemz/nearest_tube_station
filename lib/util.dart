import 'package:flutter/material.dart';

const nationalRailColor = Color(0xFFE11B22);

const lineToColor = {
  'bakerloo': Color(0xFFA45A2A),
  'central': Color(0xFFDA291C),
  'circle': Color(0xFFFFCD00),
  'district': Color(0xFF007A33),
  'hammersmith-city': Color(0xFFE89CAE),
  'jubilee': Color(0xFF7C878E),
  'metropolitan': Color(0xFF840B55),
  'northern': Color(0xFF2D2926),
  'piccadilly': Color(0xFF10069F),
  'victoria': Color(0xFF00A3E0),
  'waterloo-city': Color(0xFF6ECEB2),
  'london-overground': Color(0xFFE87722),
};

// DLR #00AFAD
// tflrail #0019A8
// tram #00BD19
// londontrams #00BD19

Color getLineColor(String lineId, String mode) {
  return (mode == 'national-rail' ? nationalRailColor : lineToColor[lineId]) ??
      Colors.blue;
}
