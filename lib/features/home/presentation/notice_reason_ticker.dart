import 'package:flutter/material.dart';

/// A clipped, single-line announcement moving from right to left.
class NoticeReasonTicker extends StatefulWidget {
  const NoticeReasonTicker({
    super.key,
    required this.text,
    required this.style,
    this.animate = true,
  });

  final String text;
  final TextStyle style;
  final bool animate;

  @override
  State<NoticeReasonTicker> createState() => _NoticeReasonTickerState();
}

class _NoticeReasonTickerState extends State<NoticeReasonTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController motion = AnimationController(vsync: this);
  double distance = 0;
  String message = '';
  bool enabled = false, hovered = false;

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  void configure(double nextDistance, bool nextEnabled) {
    if (distance == nextDistance &&
        enabled == nextEnabled &&
        message == widget.text) {
      return;
    }
    distance = nextDistance;
    enabled = nextEnabled;
    message = widget.text;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || distance != nextDistance || enabled != nextEnabled) {
        return;
      }
      motion.stop();
      motion.value = 0;
      if (enabled) {
        // Constant speed keeps long Malayalam and English notices readable.
        motion.duration = Duration(milliseconds: (distance / 36 * 1000).ceil());
        if (!hovered) motion.repeat();
      }
    });
  }

  void hover(bool value) {
    hovered = value;
    if (hovered) {
      motion.stop();
    } else if (enabled && motion.duration != null) {
      motion.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        !widget.animate ||
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final style = DefaultTextStyle.of(context).style.merge(widget.style);
    if (reduceMotion) {
      configure(0, false);
      return Text(widget.text, style: style);
    }
    final line = widget.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return Semantics(
      label: widget.text,
      child: ExcludeSemantics(
        child: MouseRegion(
          onEnter: (_) => hover(true),
          onExit: (_) => hover(false),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final painter = TextPainter(
                text: TextSpan(text: line, style: style),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
                locale: Localizations.maybeLocaleOf(context),
                maxLines: 1,
              )..layout();
              final height = painter.height.ceilToDouble() + 2;
              final travel = constraints.maxWidth + painter.width + 24;
              painter.dispose();
              configure(travel, true);
              return ClipRect(
                child: SizedBox(
                  height: height,
                  child: AnimatedBuilder(
                    animation: motion,
                    builder: (context, child) => Transform.translate(
                      key: const ValueKey('notice-reason-motion'),
                      offset: Offset(
                        constraints.maxWidth - travel * motion.value,
                        0,
                      ),
                      child: child,
                    ),
                    child: OverflowBox(
                      alignment: Alignment.centerLeft,
                      minWidth: 0,
                      maxWidth: double.infinity,
                      child: Text(
                        line,
                        style: style,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
