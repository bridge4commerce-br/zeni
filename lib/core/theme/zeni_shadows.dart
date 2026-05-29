import 'package:flutter/material.dart';

class ZeniShadows {
  const ZeniShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
}
