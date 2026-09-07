import 'package:flutter/material.dart';

class ZeniRadius {
  const ZeniRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double xl = 28;
  static const double xxl = 36;
  static const double pill = 999;

  static BorderRadius card = BorderRadius.circular(lg);
  static BorderRadius button = BorderRadius.circular(lg);
  static BorderRadius sheet = const BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}
