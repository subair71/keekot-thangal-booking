import 'package:keekot_thangal/core/localization/app_language.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../errors/app_failure.dart';

class Emblem extends StatelessWidget {
  const Emblem({super.key, this.size = 48});
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Keekkott Bungalow Thibbu Nabi Society, Chavakkad logo',
    image: true,
    child: Image.asset(
      'assets/brand/official-logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    ),
  );
}

/// Translate visible validation errors when switching language, preserving
/// controllers, focus and field values. Untouched fields remain untouched.
class LocalizedForm extends StatefulWidget {
  const LocalizedForm({super.key, required this.formKey, required this.child});
  final GlobalKey<FormState> formKey;
  final Widget child;
  @override
  State<LocalizedForm> createState() => _LocalizedFormState();
}

class _LocalizedFormState extends State<LocalizedForm> {
  String? language;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = AppLanguage.of(context);
    if (language != null && next != language) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (final field
            in widget.formKey.currentState?.fields ??
                <FormFieldState<dynamic>>[]) {
          if (field.hasError) field.validate();
        }
      });
    }
    language = next;
  }

  @override
  Widget build(BuildContext context) =>
      Form(key: widget.formKey, child: widget.child);
}

class PageContainer extends StatelessWidget {
  const PageContainer({super.key, required this.child, this.width = 1280});
  final Widget child;
  final double width;
  @override
  Widget build(BuildContext context) => Theme(
    data: SanctuaryLayout.mobile(context)
        ? mobileSanctuaryTheme(Theme.of(context))
        : Theme.of(context),
    child: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SanctuaryLayout.mobile(context)
                  ? SanctuaryLayout.pageMargin
                  : 32,
              vertical: MediaQuery.sizeOf(context).width < 600 ? 20 : 36,
            ),
            child: child,
          ),
        ),
      ),
    ),
  );
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.color,
    this.padding = 20,
    this.borderColor = AppColors.outline,
  });
  final Widget child;
  final Color? color;
  final Color borderColor;
  final double padding;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: AppColors.emerald.withValues(alpha: .045),
          blurRadius: 28,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Material(
      color:
          color ??
          (SanctuaryLayout.mobile(context) ? AppColors.cream : AppColors.white),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(
          SanctuaryLayout.mobile(context) && padding == 20 ? 16 : padding,
        ),
        child: child,
      ),
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, {super.key, this.eyebrow, this.subtitle});
  final String title;
  final String? eyebrow, subtitle;
  @override
  Widget build(BuildContext context) {
    final mobile = SanctuaryLayout.mobile(context);
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          AppText(
            eyebrow!,
            style: TextStyle(
              color: mobile ? AppColors.brass : AppColors.goldText,
              fontSize: 10,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Semantics(
          header: true,
          child: AppText(
            title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: mobile ? AppColors.ivory : AppColors.primary,
              fontSize: mobile ? 27 : 32,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          AppText(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: mobile
                  ? AppColors.ivory.withValues(alpha: .83)
                  : AppColors.muted,
            ),
          ),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: mobile
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.forest,
                borderRadius: BorderRadius.circular(SanctuaryLayout.cardRadius),
                border: Border.all(
                  color: AppColors.brass.withValues(alpha: .35),
                ),
              ),
              child: heading,
            )
          : heading,
    );
  }
}

/// Wraps at large text sizes instead of squeezing translated segmented labels.
class SanctuaryChoices<T> extends StatelessWidget {
  const SanctuaryChoices({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });
  final Map<T, String> options;
  final T value;
  final ValueChanged<T>? onChanged;
  @override
  Widget build(BuildContext context) => !SanctuaryLayout.mobile(context)
      ? SegmentedButton<T>(
          segments: [
            for (final entry in options.entries)
              ButtonSegment(value: entry.key, label: AppText(entry.value)),
          ],
          selected: {value},
          onSelectionChanged: onChanged == null
              ? null
              : (selection) => onChanged!(selection.first),
        )
      : Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in options.entries)
              ChoiceChip(
                label: AppText(entry.value),
                selected: value == entry.key,
                onSelected: onChanged == null
                    ? null
                    : (_) => onChanged!(entry.key),
              ),
          ],
        );
}

class BookingProgress extends StatelessWidget {
  const BookingProgress({super.key, required this.current});
  final int current;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked =
          (SanctuaryLayout.mobile(context)
              ? (AppLanguage.of(context) == 'ml' || constraints.maxWidth < 260)
              : constraints.maxWidth < 520) ||
          MediaQuery.textScalerOf(context).scale(1) > 1.3;
      return Wrap(
        spacing: 12,
        runSpacing: 10,
        children: [
          for (final (index, label) in [
            'Choose your time',
            'Confirm your details',
          ].indexed)
            SizedBox(
              width: stacked
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2,
              child: Semantics(
                excludeSemantics: true,
                label: AppLanguage.of(context) == 'ml'
                    ? 'ഘട്ടം ${index + 1}, ആകെ 2: ${tr(context, label)}'
                    : 'Step ${index + 1} of 2: ${tr(context, label)}',
                selected: current == index,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: current == index ? AppColors.cream : AppColors.ivory,
                    border: Border.all(
                      color: current == index
                          ? AppColors.secondary
                          : AppColors.outline,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: index <= current
                              ? AppColors.emerald
                              : AppColors.cream,
                          shape: BoxShape.circle,
                        ),
                        child: index < current
                            ? const Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: AppColors.white,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: current == index
                                      ? AppColors.white
                                      : AppColors.muted,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppText(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: current == index
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: current == index
                                ? AppColors.emerald
                                : AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(
    this.label, {
    super.key,
    this.danger = false,
    this.neutral = false,
  });
  final String label;
  final bool danger, neutral;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: danger
          ? AppColors.rose
          : neutral
          ? AppColors.cream
          : AppColors.mint,
      borderRadius: BorderRadius.circular(20),
    ),
    child: AppText(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: danger ? AppColors.error : AppColors.emerald,
      ),
    ),
  );
}

class InfoLine extends StatelessWidget {
  const InfoLine(this.icon, this.title, this.detail, {super.key});
  final IconData icon;
  final String title, detail;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: SanctuaryLayout.mobile(context)
              ? AppColors.disabled
              : AppColors.mint,
          borderRadius: BorderRadius.circular(
            SanctuaryLayout.mobile(context) ? 30 : 12,
          ),
        ),
        child: Icon(icon, color: AppColors.emerald, size: 22),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            AppText(detail, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    ],
  );
}

class TwoColumn extends StatelessWidget {
  const TwoColumn({
    super.key,
    required this.main,
    required this.aside,
    this.breakpoint = 1000,
    this.asideFirstOnMobile = false,
  });
  final Widget main, aside;
  final double breakpoint;
  final bool asideFirstOnMobile;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) => size.maxWidth >= breakpoint
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: main),
              const SizedBox(width: 28),
              Expanded(flex: 4, child: aside),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: asideFirstOnMobile
                ? [aside, const SizedBox(height: 18), main]
                : [main, const SizedBox(height: 18), aside],
          ),
  );
}

class AsyncPanel<T> extends StatelessWidget {
  const AsyncPanel({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
  });
  final AsyncValue<T> value;
  final Widget Function(T) builder;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => value.when(
    data: builder,
    loading: () => const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            AppText('Loading…'),
          ],
        ),
      ),
    ),
    error: (e, _) => EmptyState(
      icon: Icons.cloud_off_outlined,
      title: e is AppFailure
          ? e.message
          : 'We could not load this information.',
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const AppText('Try again'),
            ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.detail,
    this.action,
    this.icon = Icons.event_available_outlined,
  });
  final String title;
  final String? detail;
  final Widget? action;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: AppColors.disabled,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: AppColors.secondary),
          ),
          const SizedBox(height: 18),
          AppText(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (detail != null) ...[
            const SizedBox(height: 12),
            AppText(detail!, textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    ),
  );
}

void showMessage(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: AppText(message)));
String failureMessage(Object e) => e is AppFailure
    ? e.message
    : 'We could not complete this request. Please try again.';
Future<bool> confirmDialog(
  BuildContext context,
  String title,
  String message, {
  String confirmLabel = 'Confirm',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: AppText(title),
        content: AppText(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const AppText('Keep booking'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: AppText(confirmLabel),
          ),
        ],
      ),
    ) ??
    false;

/// Keeps a desktop sidebar within its own section. Tall panels and mobile
/// layouts stay in normal document flow so every control remains reachable.
class StickyAsideLayout extends StatefulWidget {
  const StickyAsideLayout({
    super.key,
    required this.main,
    required this.aside,
    this.asideWidth = 380,
  });
  final Widget main, aside;
  final double asideWidth;
  @override
  State<StickyAsideLayout> createState() => _StickyAsideLayoutState();
}

class _StickyAsideLayoutState extends State<StickyAsideLayout> {
  final _section = GlobalKey(), _panel = GlobalKey();
  @override
  Widget build(BuildContext context) {
    final position = Scrollable.maybeOf(context)?.position;
    Widget layout(double offset) => Row(
      key: _section,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: widget.main),
        const SizedBox(width: 28),
        Transform.translate(
          offset: Offset(0, offset),
          child: SizedBox(
            key: _panel,
            width: widget.asideWidth,
            child: widget.aside,
          ),
        ),
      ],
    );
    if (position == null) return layout(0);
    return AnimatedBuilder(
      animation: position,
      builder: (context, _) {
        final section = _section.currentContext?.findRenderObject();
        final panel = _panel.currentContext?.findRenderObject();
        var offset = 0.0;
        if (section is RenderBox &&
            panel is RenderBox &&
            section.hasSize &&
            panel.hasSize &&
            position.hasViewportDimension &&
            panel.size.height < position.viewportDimension - 40) {
          final viewport = RenderAbstractViewport.of(section);
          final top = section.localToGlobal(Offset.zero, ancestor: viewport).dy;
          final travel = section.size.height - panel.size.height;
          if (travel > 0) offset = (20 - top).clamp(0.0, travel);
        }
        return layout(offset);
      },
    );
  }
}
