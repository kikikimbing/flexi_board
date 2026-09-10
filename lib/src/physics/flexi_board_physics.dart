import 'package:flutter/animation.dart';

/// Tunables for drag feel and edge auto-scroll.
class FlexiBoardPhysics {
  const FlexiBoardPhysics({
    this.longPressDelay = const Duration(milliseconds: 180),
    this.edgeScrollExtent = 56,
    this.edgeScrollSpeed = 12,
    this.midScrollExtent = 96,
    this.midScrollSpeed = 6,
    this.farScrollExtent = 140,
    this.farScrollSpeed = 3,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeOutCubic,
    this.tabHoverSwitchDelay = const Duration(milliseconds: 350),
    this.columnWidth = 280,
    this.cardSpacing = 8,
    this.columnSpacing = 12,
    this.snapOnBoardEnter = false,
    this.snapFeedbackToPlaceholder = false,
    this.pageSideMargin = 16,
    this.pageEdgeExtent = 80,
    this.pageChangeDuration = const Duration(milliseconds: 400),
    this.keepSourceCardVisible = false,
  });

  final Duration longPressDelay;
  final double edgeScrollExtent;
  final double edgeScrollSpeed;
  final double midScrollExtent;
  final double midScrollSpeed;
  final double farScrollExtent;
  final double farScrollSpeed;
  final Duration animationDuration;
  final Curve animationCurve;
  final Duration tabHoverSwitchDelay;
  final double columnWidth;
  final double cardSpacing;
  final double columnSpacing;

  /// When the pointer enters a different board, snap hover to the nearest
  /// column (and top insert slot) instead of waiting for a precise hit.
  final bool snapOnBoardEnter;

  /// When snapped to a cross-board target, pin the floating card to the
  /// placeholder slot rather than the finger.
  final bool snapFeedbackToPlaceholder;

  /// Horizontal inset used by [FlexiBoardLayout.paged] to compute
  /// `PageController.viewportFraction` (side peek of neighboring columns).
  final double pageSideMargin;

  /// Distance from the left/right edge that triggers a page change while
  /// dragging in [FlexiBoardLayout.paged].
  final double pageEdgeExtent;

  /// Duration for animated page changes in [FlexiBoardLayout.paged].
  final Duration pageChangeDuration;

  /// When true, the source card stays in the origin column while dragging
  /// (LongPressDraggable-style). Default collapses the slot and shows a
  /// placeholder ghost instead.
  final bool keepSourceCardVisible;

  static const FlexiBoardPhysics standard = FlexiBoardPhysics();

  /// Snappy cross-board feel for demos / multi-board UIs.
  static const FlexiBoardPhysics snappy = FlexiBoardPhysics(
    snapOnBoardEnter: true,
    snapFeedbackToPlaceholder: true,
    tabHoverSwitchDelay: Duration(milliseconds: 220),
  );
}
