import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Helper class providing consistent, safe bottom navigation padding across all screens.
/// Accounts for hardware navigation bars (3-button nav), gesture navigation pill bars,
/// iOS home indicators, and floating action buttons (FABs).
class NavigationPadding {
  /// Base ergonomic bottom clearance (minimum spacing above navigation elements)
  static const double baseClearance = 16.0;

  /// Comfortable bottom clearance for scrollable content / lists without FABs
  static const double scrollClearance = 24.0;

  /// Extra clearance when a FloatingActionButton sits at the bottom of the screen
  static const double fabClearance = 84.0;

  /// Returns the device bottom inset (system navigation bar / home indicator height)
  static double bottomInset(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom;
  }

  /// Returns total navigation padding: device bottom inset + [extra] clearance.
  /// Guarantees at least [baseClearance] spacing even when inset is 0.
  static double of(BuildContext context, {double extra = baseClearance}) {
    final inset = bottomInset(context);
    return math.max(inset, baseClearance) + extra;
  }

  /// Returns an [EdgeInsets] with bottom navigation padding.
  static EdgeInsets insets(
    BuildContext context, {
    double horizontal = 0.0,
    double top = 0.0,
    double extra = baseClearance,
  }) {
    return EdgeInsets.fromLTRB(horizontal, top, horizontal, of(context, extra: extra));
  }

  /// Returns an [EdgeInsets] tailored for scrollable lists with or without a FAB.
  static EdgeInsets listInsets(
    BuildContext context, {
    double horizontal = 16.0,
    double top = 16.0,
    bool hasFab = false,
  }) {
    final extra = hasFab ? fabClearance : scrollClearance;
    return insets(context, horizontal: horizontal, top: top, extra: extra);
  }
}

/// A convenient spacing widget that inserts bottom navigation padding.
class BottomNavSpacing extends StatelessWidget {
  final double extra;

  const BottomNavSpacing({super.key, this.extra = NavigationPadding.baseClearance});

  const BottomNavSpacing.fab({super.key}) : extra = NavigationPadding.fabClearance;

  const BottomNavSpacing.scroll({super.key}) : extra = NavigationPadding.scrollClearance;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: NavigationPadding.of(context, extra: extra));
  }
}
