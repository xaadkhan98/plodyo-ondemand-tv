import 'package:flutter/material.dart';

import '../theme/tv_colors.dart';
import '../theme/tv_scale.dart';

/// A D-pad focus target. OK/Enter, click and tap select it; a pointer (LG's Magic Remote) focuses it on hover.
/// Draws the reference's focus ring around the box unless [ring] is false; [builder] styles the focused state.
class TvFocusable extends StatefulWidget {
  const TvFocusable({
    super.key,
    required this.builder,
    this.onSelect,
    this.focusNode,
    this.autofocus = false,
    this.disabled = false,
    this.ring = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(0.75 * rem)),
    this.semanticLabel,
  });

  final Widget Function(BuildContext context, bool focused) builder;
  final VoidCallback? onSelect;
  final FocusNode? focusNode;
  final bool autofocus;

  /// Unfocusable, dimmed and inert, but still on screen.
  final bool disabled;
  final bool ring;

  /// The target's shape, which the ring follows.
  final BorderRadius borderRadius;
  final String? semanticLabel;

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  FocusNode? _ownNode;
  bool _focused = false;

  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());

  @override
  void dispose() {
    _ownNode?.dispose();
    super.dispose();
  }

  void _select() {
    if (widget.disabled) return;
    _node.requestFocus();
    widget.onSelect?.call();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focused && !widget.disabled;

    return Semantics(
      button: true,
      enabled: !widget.disabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        focusNode: _node,
        autofocus: widget.autofocus,
        enabled: !widget.disabled,
        mouseCursor: widget.disabled
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        onFocusChange: (value) => setState(() => _focused = value),
        // The D-pad resumes from wherever the pointer left off.
        onShowHoverHighlight: (hovered) {
          if (hovered && !widget.disabled) _node.requestFocus();
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => widget.onSelect?.call(),
          ),
        },
        child: GestureDetector(
          onTap: widget.disabled ? null : _select,
          child: Opacity(
            opacity: widget.disabled ? 0.4 : 1,
            child: CustomPaint(
              painter: focused && widget.ring
                  ? _FocusRing(widget.borderRadius)
                  : null,
              child: widget.builder(context, focused),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints only outside the box, so a translucent target never shows the ring through its fill.
class _FocusRing extends CustomPainter {
  const _FocusRing(this.borderRadius);

  /// Tailwind's `ring-2 ring-offset-2` with a transparent offset renders as one 4px band against the edge.
  static const double _width = 4 * px;

  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final box = borderRadius.toRRect(Offset.zero & size).scaleRadii();
    canvas.drawDRRect(box.inflate(_width), box, Paint()..color = TvColors.ring);
  }

  @override
  bool shouldRepaint(_FocusRing oldDelegate) =>
      oldDelegate.borderRadius != borderRadius;
}
