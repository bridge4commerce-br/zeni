import 'package:flutter/material.dart';

class ZeniRadius {
  const ZeniRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double xl = 28;
  static const double xxl = 36;
  static const double pill = 999;

  static const double controlValue = md;
  static const double parentValue = 16;
  static const double kidsValue = 24;
  static const double heroValue = xl;
  static const double dialogValue = 24;

  static BorderRadius card = BorderRadius.circular(lg);
  static BorderRadius button = BorderRadius.circular(lg);
  static BorderRadius sheet = const BorderRadius.vertical(
    top: Radius.circular(xl),
  );

  static final BorderRadius control = BorderRadius.circular(controlValue);
  static final BorderRadius parent = BorderRadius.circular(parentValue);
  static final BorderRadius kids = BorderRadius.circular(kidsValue);
  static final BorderRadius hero = BorderRadius.circular(heroValue);
  static final BorderRadius dialog = BorderRadius.circular(dialogValue);
}
