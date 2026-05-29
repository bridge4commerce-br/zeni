import 'package:flutter/material.dart';

import 'zeni_feedback_popup.dart';

class ZeniInfoPopup {
  const ZeniInfoPopup._();

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    return ZeniFeedbackPopup.show(
      context,
      title: title,
      message: message,
      type: ZeniFeedbackType.info,
      duration: duration,
    );
  }
}
