import 'package:flutter/material.dart';

/// The official Zeni wordmark for in-app branding. App and splash icons remain
/// independent from this component.
class ZeniBrandLogo extends StatelessWidget {
  const ZeniBrandLogo({
    super.key,
    this.width = 132,
    this.semanticLabel = 'Zeni',
  });

  final double width;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Image.asset(
          'assets/branding/zeni_logo.png',
          width: width,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
