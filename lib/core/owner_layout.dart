import 'package:flutter/material.dart';

/// Breakpoints y helpers de layout para Owner (mobile + escritorio).
class OwnerLayout {
  OwnerLayout._();

  static const double desktopBreakpoint = 900;
  static const double contentMaxWidth = 1080;
  static const double formMaxWidth = 720;
  static const double actionButtonMaxWidth = 280;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  /// Centra el contenido y limita ancho en pantallas anchas.
  static Widget constrain({
    required BuildContext context,
    required Widget child,
    double? maxWidth,
    EdgeInsetsGeometry? padding,
  }) {
    final content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? contentMaxWidth),
      child: child,
    );
    if (padding != null) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(padding: padding, child: content),
      );
    }
    return Align(alignment: Alignment.topCenter, child: content);
  }

  static Widget form({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) =>
      constrain(
        context: context,
        maxWidth: formMaxWidth,
        padding: padding,
        child: child,
      );
}
