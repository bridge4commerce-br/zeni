import 'package:flutter/material.dart';

class ZeniShadows {
  const ZeniShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x120B2E17), blurRadius: 20, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x0D0B2E17), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> button = [
    BoxShadow(color: Color(0x2422C55E), blurRadius: 12, offset: Offset(0, 5)),
  ];
}
