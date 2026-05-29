import 'package:flutter/material.dart';

import 'zeni_feedback_popup.dart';

class ZeniErrorPopup {
  const ZeniErrorPopup._();

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 5),
  }) {
    return ZeniFeedbackPopup.show(
      context,
      title: title,
      message: message,
      type: ZeniFeedbackType.error,
      duration: duration,
    );
  }
}
