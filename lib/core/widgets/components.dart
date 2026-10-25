import 'package:keekot_thangal/core/localization/app_language.dart';

import 'package:flutter/material.dart';
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

class PageContainer extends StatelessWidget {
  const PageContainer({super.key, required this.child, this.width = 1240});
  final Widget child;
  final double width;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
            vertical: MediaQuery.sizeOf(context).width < 600 ? 20 : 36,
          ),
          child: child,
        ),
      ),
    ),
  );
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.color = AppColors.white,
    this.padding = 18,
  });
  final Widget child;
  final Color color;
  final double padding;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: AppColors.emerald.withValues(alpha: .045),
          blurRadius: 28,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Material(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: EdgeInsets.all(padding), child: child),
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, {super.key, this.eyebrow, this.subtitle});
  final String title;
  final String? eyebrow, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Container(
            width: 32,
            height: 3,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          AppText(
            tr(context, eyebrow!).toUpperCase(),
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Semantics(
          header: true,
          child: AppText(
            title,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          AppText(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    ),
  );
}

class BookingProgress extends StatelessWidget {
  const BookingProgress({super.key, required this.current});
  final int current;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked =
          constraints.maxWidth < 520 ||
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
                    color: current == index ? AppColors.mint : AppColors.white,
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
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.emerald, size: 22),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(title, style: Theme.of(context).textTheme.titleMedium),
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
          Icon(icon, size: 38, color: AppColors.secondary),
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
