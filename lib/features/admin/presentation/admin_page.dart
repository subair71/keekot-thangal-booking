import '../../../core/localization/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/components.dart';
import '../../../core/utils/visit_clock.dart';
import 'admin_settings_page.dart';
import 'admin_slots_page.dart';
import 'admin_export_button.dart';
import 'pass_scanner_dialog.dart';

class AdminPage extends ConsumerWidget {
  const AdminPage({super.key, this.section = 'dashboard'});
  final String section;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).asData?.value;
    final navigation = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in [
          ('dashboard', 'Overview'),
          ('bookings', 'Bookings'),
          ('slots', 'Slots & closures'),
          ('settings', 'Settings'),
          ('gate', 'Scan visitor pass'),
          if (user?.admin == true) ...[
            ('khadims', 'Khadim accounts'),
            ('assignments', 'Khadim Assignments'),
            ('availability', 'Khadim availability'),
          ],
        ])
          if (['khadims', 'assignments', 'availability'].contains(item.$1)
              ? user?.admin == true
              : user?.can(item.$1) == true)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: item.$1 == section ? AppColors.mint : null,
              ),
              onPressed: () => context.go(
                item.$1 == 'dashboard' ? '/admin' : '/admin/${item.$1}',
              ),
              child: AppText(item.$2),
            ),
      ],
    );
    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeading(
            section == 'gate' ? 'Visitor entry' : 'Administration',
            eyebrow: 'Keekkott Sayyid Attakoya Thangal Maqam',
          ),
          if (user?.staff == true) ...[
            if (user?.can('bookings') == true)
              if (SanctuaryLayout.mobile(context))
                SurfaceCard(
                  padding: 0,
                  child: ExpansionTile(
                    leading: const Icon(Icons.file_download_outlined),
                    title: const AppText('Download bookings'),
                    children: const [AdminExportButton()],
                  ),
                )
              else
                const AdminExportButton(),
            const SizedBox(height: 20),
            if (SanctuaryLayout.mobile(context))
              SurfaceCard(
                padding: 0,
                child: ExpansionTile(
                  leading: const Icon(Icons.dashboard_outlined),
                  title: AppText(switch (section) {
                    'bookings' => 'Bookings',
                    'slots' => 'Slots & closures',
                    'settings' => 'Settings',
                    'gate' => 'Scan visitor pass',
                    _ => 'Overview',
                  }),
                  childrenPadding: const EdgeInsets.all(12),
                  children: [navigation],
                ),
              )
            else
              navigation,
            const SizedBox(height: 28),
          ],
          switch (section) {
            'bookings' => const AdminBookings(),
            'slots' => const AdminSlots(),
            'settings' => const AdminSettings(),
            'gate' => const GateValidation(),
            _ => const AdminDashboard(),
          },
        ],
      ),
    );
  }
}

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncPanel(
    value: ref.watch(adminDashboardProvider),
    onRetry: () => ref.invalidate(adminDashboardProvider),
    builder: (data) => Column(
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth > 900
                ? 3
                : c.maxWidth > 550 ||
                      (SanctuaryLayout.mobile(context) &&
                          MediaQuery.textScalerOf(context).scale(1) <= 1.3)
                ? 2
                : 1;
            const labels = {
              'bookingsToday': 'Bookings today',
              'visitorsToday': 'Visitors today',
              'upcoming': 'Upcoming bookings',
              'availableSlots': 'Available slots today',
              'fullSlots': 'Full slots today',
              'cancelled': 'Cancellations today',
            };
            return Wrap(
              spacing: 18,
              runSpacing: 18,
              children: [
                for (final item in labels.entries)
                  SizedBox(
                    width: (c.maxWidth - 18 * (cols - 1)) / cols,
                    child: SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(item.value),
                          const SizedBox(height: 12),
                          AppText(
                            '${data[item.key] ?? 0}',
                            style: Theme.of(context).textTheme.displayLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => ref.invalidate(adminDashboardProvider),
          icon: const Icon(Icons.refresh),
          label: const AppText('Refresh overview'),
        ),
      ],
    ),
  );
}

class AdminBookings extends ConsumerStatefulWidget {
  const AdminBookings({super.key});
  @override
  ConsumerState<AdminBookings> createState() => _AdminBookingsState();
}

class _AdminBookingsState extends ConsumerState<AdminBookings> {
  String day = VisitClock.today(), search = '';
  bool busy = false;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.parse(day),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => day = VisitClock.dayKey(picked));
              }
            },
            icon: const Icon(Icons.calendar_month),
            label: AppText(VisitClock.dayLabel(day)),
          ),
          SizedBox(
            width: SanctuaryLayout.mobile(context)
                ? MediaQuery.sizeOf(context).width - 40
                : 340,
            child: TextField(
              onChanged: (v) => setState(() => search = v.toLowerCase().trim()),
              decoration: InputDecoration(
                label: AppText('Reference, visitor or phone on selected date'),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      AsyncPanel(
        value: ref.watch(adminBookingsProvider(day)),
        onRetry: () => ref.invalidate(adminBookingsProvider(day)),
        builder: (all) {
          final bookings = all
              .where(
                (b) => '${b.reference} ${b.visitorName} ${b.visitorPhone}'
                    .toLowerCase()
                    .contains(search),
              )
              .toList();
          if (bookings.isEmpty) {
            return const EmptyState(title: 'No matching bookings');
          }
          return Column(
            children: [
              for (final b in bookings)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 20,
                          runSpacing: 12,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            AppText(
                              b.reference,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            StatusBadge(b.status.toUpperCase()),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AppText(
                          '${b.visitorName} · ${tr(context, '${b.visitors} visitors')}\n${tr(context, b.timeLabel)}',
                        ),
                        const SizedBox(height: 16),
                        InfoLine(
                          Icons.phone_outlined,
                          'Visitor Phone Number',
                          b.visitorPhoneDisplay,
                        ),
                        if (b.bookedByLabel.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          InfoLine(
                            Icons.support_agent,
                            'Booked by',
                            b.bookedByLabel,
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (b.visitorAddress.isNotEmpty) ...[
                          InfoLine(
                            Icons.home_outlined,
                            'Address',
                            b.visitorAddress,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (b.status == 'confirmed')
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final action in [
                                ('completed', 'Mark attended'),
                                ('noShow', 'Mark no-show'),
                                ('cancelled', 'Cancel booking'),
                              ])
                                OutlinedButton(
                                  onPressed: busy
                                      ? null
                                      : () async {
                                          if (action.$1 == 'cancelled' &&
                                              !await confirmDialog(
                                                context,
                                                'Cancel this booking?',
                                                'The visitor will receive a booking update.',
                                                confirmLabel: 'Cancel booking',
                                              )) {
                                            return;
                                          }
                                          if (!mounted) return;
                                          setState(() => busy = true);
                                          try {
                                            if (action.$1 == 'cancelled') {
                                              await ref
                                                  .read(
                                                    bookingRepositoryProvider,
                                                  )
                                                  .cancel(
                                                    b.id,
                                                    'Cancelled by administration',
                                                  );
                                            } else {
                                              await ref
                                                  .read(adminRepositoryProvider)
                                                  .setBookingStatus(
                                                    b.id,
                                                    action.$1,
                                                  );
                                            }
                                            ref.invalidate(
                                              adminDashboardProvider,
                                            );
                                          } catch (e) {
                                            if (context.mounted) {
                                              showMessage(
                                                context,
                                                failureMessage(e),
                                              );
                                            }
                                          } finally {
                                            if (mounted) {
                                              setState(() => busy = false);
                                            }
                                          }
                                        },
                                  child: AppText(action.$2),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}

class GateValidation extends ConsumerStatefulWidget {
  const GateValidation({super.key});
  @override
  ConsumerState<GateValidation> createState() => _GateValidationState();
}

class _GateValidationState extends ConsumerState<GateValidation> {
  final token = TextEditingController();
  Map<String, dynamic>? result;
  bool busy = false;
  String? error;
  @override
  void dispose() {
    token.dispose();
    super.dispose();
  }

  Future<void> scanPass() async {
    final scanned = await showDialog<String>(
      context: context,
      builder: (_) => const PassScannerDialog(),
    );
    if (!mounted || scanned == null) return;
    token.text = scanned;
    await validate(true);
  }

  Future<void> validate(bool checkIn) async {
    if (busy) return;
    final scanned = token.text.trim();
    if (!RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(scanned)) {
      setState(() {
        result = null;
        error = 'This is not a valid visitor pass QR code.';
      });
      return;
    }
    setState(() {
      result = null;
      busy = true;
      error = null;
    });
    try {
      final response = await ref
          .read(adminRepositoryProvider)
          .validatePass(scanned, checkIn);
      if (mounted) {
        setState(() => result = response);
        if (response['valid'] == true && response['status'] == 'completed') {
          ref.invalidate(adminDashboardProvider);
        }
      }
    } catch (e) {
      if (mounted) setState(() => error = failureMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topLeft,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText(
              'Scan and confirm visit',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const AppText(
              'Scan the QR code on the visitor pass. A valid pass automatically confirms attendance during the allowed arrival and visit time.',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: busy ? null : scanPass,
              icon: const Icon(Icons.qr_code_scanner),
              label: const AppText('Scan visitor pass'),
            ),
            const SizedBox(height: 20),
            TextField(
              enabled: !busy,
              controller: token,
              onChanged: (_) => setState(() => result = null),
              onSubmitted: (_) => busy ? null : validate(true),
              decoration: InputDecoration(
                label: AppText('Or paste the pass QR token'),
                prefixIcon: Icon(Icons.qr_code_scanner),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton(
                  onPressed: busy ? null : () => validate(false),
                  child: const AppText('Check pass'),
                ),
                FilledButton(
                  onPressed: busy || result?['status'] == 'completed'
                      ? null
                      : () => validate(true),
                  child: const AppText('Verify and confirm visit'),
                ),
              ],
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: LinearProgressIndicator(),
              ),
            if (error != null) ...[
              const SizedBox(height: 20),
              AppText(error!, style: const TextStyle(color: AppColors.error)),
            ],
            if (result != null) ...[
              const SizedBox(height: 24),
              StatusBadge(
                result!['valid'] == true
                    ? (result!['status'] == 'completed'
                          ? 'Visit confirmed'
                          : 'Valid for entry')
                    : 'Not valid for entry',
                danger: result!['valid'] != true,
              ),
              const SizedBox(height: 12),
              if (result!['valid'] != true)
                AppText(switch (result!['reason'] ?? result!['status']) {
                  'already_used' || 'completed' =>
                    'This pass has already been used. Do not admit again.',
                  'cancelled' => 'This booking has been cancelled.',
                  'too_early' =>
                    'This pass is not yet valid. Check the scheduled visit time.',
                  'expired' => 'The visit time for this pass has expired.',
                  _ =>
                    'This pass is not valid for entry. Check the booking and visit time.',
                }),
              if (result!['bookingReference'] != null)
                AppText(
                  "${result!['bookingReference']}\n${result!['visitDate']} · ${result!['timeSlot']}\n${tr(context, '${result!['visitorCount']} visitors')} · ${tr(context, '${result!['status']}')}",
                ),
            ],
          ],
        ),
      ),
    ),
  );
}
