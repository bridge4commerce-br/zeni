import 'package:flutter/material.dart';

class ZeniAnimation {
  const ZeniAnimation._();

  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve entranceCurve = Curves.easeOutBack;
  static const Curve exitCurve = Curves.easeInCubic;
}
