import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/visit_clock.dart';
import '../../../core/widgets/components.dart';
import '../domain/booking_models.dart';

class ConfirmationPage extends ConsumerStatefulWidget {
  const ConfirmationPage({super.key});
  @override
  ConsumerState<ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends ConsumerState<ConfirmationPage> {
  final name = TextEditingController(), form = GlobalKey<FormState>();
  final elapsed = Stopwatch();
  SlotHold? hold;
  String? error;
  bool busy = false, loading = true;
  Timer? timer;
  int get remaining => hold == null
      ? 0
      : ((hold!.expiresAt - hold!.serverNow - elapsed.elapsedMilliseconds) ~/
                1000)
            .clamp(0, 300);
  @override
  void initState() {
    super.initState();
    Future.microtask(loadHold);
  }

  Future<void> loadHold() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final repo = ref.read(bookingRepositoryProvider),
          draft = ref.read(draftProvider);
      var current = await repo.activeHold();
      if (current != null &&
          draft.slot != null &&
          (current.slotId != draft.slot!.id ||
              current.visitors != draft.visitors)) {
        await repo.releaseHold(current.id);
        current = null;
      }
      if (current == null && draft.slot != null)
        current = await repo.createHold(
          draft.slot!,
          draft.visitors,
          draft.requestId,
        );
      if (!mounted) return;
      hold = current;
      elapsed.reset();
      elapsed.start();
      timer?.cancel();
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } catch (e) {
      if (mounted) error = failureMessage(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> submit() async {
    if (hold == null || remaining == 0 || !form.currentState!.validate())
      return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final id = await ref
          .read(bookingRepositoryProvider)
          .confirm(hold!.id, name.text.trim());
      ref.read(draftProvider.notifier).clear();
      if (mounted) context.go('/book/success/$id');
    } catch (e) {
      if (mounted) setState(() => error = failureMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> change() async {
    setState(() => busy = true);
    try {
      if (hold != null)
        await ref.read(bookingRepositoryProvider).releaseHold(hold!.id);
      ref.read(draftProvider.notifier).clear();
      if (mounted) context.go('/book');
    } catch (e) {
      if (mounted) {
        showMessage(context, failureMessage(e));
        setState(() => busy = false);
      }
    }
  }

  @override
  void dispose() {
    name.dispose();
    timer?.cancel();
    elapsed.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).asData?.value;
    final content = loading
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(60),
              child: CircularProgressIndicator(),
            ),
          )
        : hold == null
        ? EmptyState(
            title: error ?? 'Select a visit time first',
            action: FilledButton(
              onPressed: () => context.go('/book'),
              child: const Text('Choose a time'),
            ),
          )
        : TwoColumn(
            main: SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Booking summary',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      StatusBadge(
                        remaining > 0
                            ? 'Held ${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}'
                            : 'Hold expired',
                        danger: remaining == 0,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const InfoLine(
                    Icons.location_on_outlined,
                    'Keekot Thangal Maqam',
                    'Chavakkad, Kerala',
                  ),
                  const SizedBox(height: 24),
                  InfoLine(
                    Icons.calendar_today_outlined,
                    'Visit date',
                    VisitClock.dayLabel(hold!.visitDate),
                  ),
                  const SizedBox(height: 24),
                  InfoLine(
                    Icons.schedule,
                    'Your time',
                    '${hold!.label}\nIndia Standard Time',
                  ),
                  const SizedBox(height: 24),
                  InfoLine(
                    Icons.people_outline,
                    'Visitors',
                    '${hold!.visitors} ${hold!.visitors == 1 ? 'visitor' : 'visitors'}',
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Keep your pass ready when you arrive. Please dress respectfully and silence your phone during your visit.',
                  ),
                ],
              ),
            ),
            aside: SurfaceCard(
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Visitor details',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: name,
                      enabled: !busy,
                      maxLength: 100,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) =>
                          value == null || value.trim().length < 2
                          ? 'Enter your full name.'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    InfoLine(
                      Icons.verified_user_outlined,
                      'Mobile verified',
                      user?.maskedPhone ?? 'Signed in',
                    ),
                    const SizedBox(height: 24),
                    if (error != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (remaining == 0) ...[
                      const Text(
                        'Your hold has ended. Please select your time again.',
                      ),
                      const SizedBox(height: 20),
                    ],
                    FilledButton.icon(
                      onPressed: busy || remaining == 0 ? null : submit,
                      icon: const Icon(Icons.lock_outline),
                      label: Text(busy ? 'Confirming…' : 'Confirm booking'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: busy ? null : change,
                      child: const Text('Change date or time'),
                    ),
                  ],
                ),
              ),
            ),
          );
    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeading(
            'Confirm your visit',
            eyebrow: 'Step 2 of 2',
            subtitle: 'Check your time and add your name to the pass.',
          ),
          content,
        ],
      ),
    );
  }
}
