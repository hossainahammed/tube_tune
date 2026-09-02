import 'package:flutter/material.dart';
import 'app_breakpoints.dart';
import 'responsive_builder.dart';

/// Wraps UI in a centered, max-width constrained container for Tablets, Desktop, and Web.
class ResponsiveCenteredWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveCenteredWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: ResponsiveBuilder(
        mobile: child,
        tablet: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.mobile),
            child: ClipRect(child: child),
          ),
        ),
        desktop: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.mobile),
            child: ClipRect(child: child),
          ),
        ),
      ),
    );
  }
}
