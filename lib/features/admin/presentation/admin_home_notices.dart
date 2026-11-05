import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/utils/visit_clock.dart';
import '../../../core/widgets/components.dart';
import '../../home/presentation/home_notice_banner.dart';
import '../../notifications/domain/home_notice.dart';

class HomeNoticeShortcut extends StatelessWidget {
  const HomeNoticeShortcut({super.key});

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Home notices',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const AppText(
          'Tell visitors about cancellations or changes before they travel.',
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const ValueKey('home-notice-manage'),
          onPressed: () => context.go('/admin/notices'),
          icon: const Icon(Icons.campaign_outlined),
          label: const AppText('Manage home notice'),
        ),
      ],
    ),
  );
}

class AdminHomeNotices extends ConsumerWidget {
  const AdminHomeNotices({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(authProvider).asData?.value?.admin != true) {
      return const EmptyState(title: 'Staff access is required');
    }
    return AsyncPanel(
      value: ref.watch(configurationProvider),
      onRetry: () => ref.invalidate(configurationProvider),
      builder: (config) => _HomeNoticeEditor(notice: config.homeNotice),
    );
  }
}

class _HomeNoticeEditor extends ConsumerStatefulWidget {
  const _HomeNoticeEditor({required this.notice});
  final HomeNotice? notice;

  @override
  ConsumerState<_HomeNoticeEditor> createState() => _HomeNoticeEditorState();
}

class _HomeNoticeEditorState extends ConsumerState<_HomeNoticeEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController reason;
  late String day;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    reason = TextEditingController(text: widget.notice?.reason ?? '');
    day = widget.notice?.visitDate ?? VisitClock.today();
  }

  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  Future<void> chooseDate() async {
    final today = DateTime.parse(VisitClock.today());
    final last = today.add(const Duration(days: 365));
    final selected = DateTime.parse(day);
    final picked = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: last,
      initialDate: selected.isBefore(today)
          ? today
          : selected.isAfter(last)
          ? last
          : selected,
    );
    if (picked != null && mounted) {
      setState(() => day = VisitClock.dayKey(picked));
    }
  }

  Future<void> save(bool publish) async {
    if (busy) return;
    if (publish && !form.currentState!.validate()) return;
    if (publish && day.compareTo(VisitClock.today()) < 0) {
      showMessage(context, 'Choose today or a future visit date.');
      return;
    }
    setState(() => busy = true);
    try {
      final repository = ref.read(adminRepositoryProvider);
      if (publish) {
        await repository.publishHomeNotice(
          HomeNotice(
            visitDate: day,
            reason: reason.text.trim(),
            active: true,
          ),
        );
      } else {
        await repository.hideHomeNotice();
      }
      if (!mounted) return;
      ref.invalidate(configurationProvider);
      showMessage(
        context,
        publish ? 'Home notice published.' : 'Home notice hidden.',
      );
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.notice;
    final visible = current?.visibleAt(ref.read(homeNoticeClockProvider)()) == true;
    return SurfaceCard(
      child: LocalizedForm(
        formKey: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText(
              'Home notices',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const AppText(
              'Publish a date and reason in a visible banner on the visitor home screen.',
            ),
            const SizedBox(height: 12),
            const AppText(
              'Update affected bookings in Bookings and availability in Slots & closures.',
            ),
            const SizedBox(height: 20),
            AppText(
              visible
                  ? 'Currently visible on Home'
                  : current?.active == true
                  ? 'Notice expired'
                  : 'No active home notice',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (visible) ...[
              const SizedBox(height: 12),
              HomeNoticeCard(notice: current!, animate: false),
            ],
            const SizedBox(height: 24),
            const AppText('Affected visit date'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const ValueKey('home-notice-date'),
                onPressed: busy ? null : chooseDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: AppText(VisitClock.dayLabel(day)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('home-notice-reason'),
              controller: reason,
              enabled: !busy,
              maxLines: 4,
              maxLength: 500,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                label: AppText('Reason / notice for visitors'),
                alignLabelWithHint: true,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter the reason visitors should see.'
                  : null,
            ),
            const SizedBox(height: 12),
            const AppText(
              'Visible immediately after publishing, until the end of the affected date in India time. You can hide it earlier.',
            ),
            if (reason.text.trim().isNotEmpty) ...[
              const SizedBox(height: 24),
              AppText(
                'Banner preview',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              HomeNoticeCard(
                notice: HomeNotice(
                  visitDate: day,
                  reason: reason.text.trim(),
                  active: true,
                ),
                animate: false,
              ),
            ],
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  key: const ValueKey('home-notice-publish'),
                  onPressed: busy ? null : () => save(true),
                  icon: const Icon(Icons.publish_outlined),
                  label: AppText(busy ? 'Saving…' : 'Publish notice'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('home-notice-hide'),
                  onPressed: busy || current?.active != true
                      ? null
                      : () => save(false),
                  icon: const Icon(Icons.visibility_off_outlined),
                  label: const AppText('Hide notice'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
