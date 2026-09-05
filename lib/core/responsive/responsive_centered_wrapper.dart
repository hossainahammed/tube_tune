import 'package:flutter/material.dart';

/// Provides a clean root wrapper for responsive layouts across Mobile, Tablet, Desktop, and Web.
class ResponsiveCenteredWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveCenteredWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
