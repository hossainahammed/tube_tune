import 'package:flutter/material.dart';
import 'app_breakpoints.dart';

/// Helper methods for querying device form factor and screen size.
class ResponsiveHelper {
  ResponsiveHelper._();

  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double height(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static bool isMobile(BuildContext context) =>
      width(context) < AppBreakpoints.mobile;

  static bool isTablet(BuildContext context) =>
      width(context) >= AppBreakpoints.mobile &&
      width(context) < AppBreakpoints.desktop;

  static bool isDesktop(BuildContext context) =>
      width(context) >= AppBreakpoints.desktop;
}
