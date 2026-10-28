import 'dart:async';

import 'availability_state.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/bootstrap/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/localization/app_language.dart';
import '../../core/utils/visit_clock.dart';
import '../../core/widgets/components.dart';
import 'assignment_repository.dart';

class AssignmentPage extends ConsumerStatefulWidget {
  const AssignmentPage({super.key, this.staff = false});
  final bool staff;
  @override
  ConsumerState<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends ConsumerState<AssignmentPage> {
  String day = VisitClock.today(),
      search = '',
      status = 'All',
      khadim = 'All',
      time = '';
  bool upcoming = false, busy = false;
  Future<void> transition(Record b, String status) async {
    setState(() => busy = true);
    try {
      await ref.read(assignmentsRepositoryProvider).call('khadimVisitStatus', {
        'bookingId': b['id'],
        'status': status,
      });
    } catch (e) {
      if (mounted) showMessage(context, failureMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.staff ? ref.watch(authProvider).asData?.value?.id : null;
    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeading(
            widget.staff ? 'Your visits' : 'Khadim Assignments',
            eyebrow: 'VISITOR CARE',
            subtitle: 'Scheduled in India Standard Time · Asia/Kolkata',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.go(
                  widget.staff ? '/khadim/availability' : '/admin/availability',
                ),
                icon: const Icon(Icons.event_available_outlined),
                label: const AppText('Manage availability'),
              ),
              if (!widget.staff)
                OutlinedButton(
                  onPressed: () => context.go('/admin'),
                  child: const AppText('Administration'),
                ),
              if (widget.staff) ...[
                ChoiceChip(
                  label: const AppText('Today'),
                  selected: !upcoming,
                  onSelected: (_) => setState(() => upcoming = false),
                ),
                ChoiceChip(
                  label: const AppText('Upcoming'),
                  selected: upcoming,
                  onSelected: (_) => setState(() => upcoming = true),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          if (!widget.staff)
            SurfaceCard(
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) => setState(() => search = v),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      label: AppText('Search visitor or booking'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: DateTime.parse(day),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (d != null) {
                            setState(() => day = VisitClock.dayKey(d));
                          }
                        },
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: AppText(VisitClock.dayLabel(day)),
                      ),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: status,
                          decoration: InputDecoration(
                            label: AppText('Service status'),
                          ),
                          items: [
                            for (final s in [
                              'All',
                              'Unassigned',
                              'Assigned',
                              'In progress',
                              'Completed',
                              'Cancelled',
                            ])
                              DropdownMenuItem(
                                value: s,
                                child: AppText(
                                  s,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (s) => setState(() => status = s!),
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: TextField(
                          onChanged: (v) => setState(() => time = v),
                          decoration: InputDecoration(
                            label: AppText('Time (HH:mm)'),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: AsyncPanel(
                          value: ref.watch(assignmentStaffProvider),
                          builder: (staff) => DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: khadim,
                            decoration: InputDecoration(
                              label: AppText('Khadim'),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 'All',
                                child: AppText('All'),
                              ),
                              for (final k in staff)
                                DropdownMenuItem(
                                  value: k['id'] as String,
                                  child: Text(k['name'] as String),
                                ),
                            ],
                            onChanged: (s) => setState(() => khadim = s!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          AsyncPanel(
            value: ref.watch(assignmentBookingsProvider(uid)),
            onRetry: () => ref.invalidate(assignmentBookingsProvider(uid)),
            builder: (data) {
              final bookings =
                  data.where((b) {
                    final a = b['assignment'] as Map?;
                    return (widget.staff
                            ? (upcoming
                                  ? '${b['visitDate']}'.compareTo(day) > 0
                                  : b['visitDate'] == day)
                            : b['visitDate'] == day) &&
                        (status == 'All' || serviceLabel(b) == status) &&
                        (khadim == 'All' || a?['khadimId'] == khadim) &&
                        (time.isEmpty || '${b['startTime']}'.contains(time)) &&
                        ('${b['visitorName']} ${b['bookingReference']} ${b['tokenStart']}'
                            .toLowerCase()
                            .contains(search.toLowerCase()));
                  }).toList()..sort(
                    (a, b) =>
                        (a['startAt'] as num).compareTo(b['startAt'] as num),
                  );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${bookings.length} ${tr(context, 'visits')} · ${bookings.where((b) => serviceLabel(b) == 'In progress').length} ${tr(context, 'in progress')}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (bookings.isEmpty)
                    const EmptyState(
                      title: 'No visits to show',
                      detail: 'Try another date or filter.',
                    ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth > 1000
                          ? 3
                          : constraints.maxWidth > 680
                          ? 2
                          : 1;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          for (final b in bookings)
                            SizedBox(
                              width:
                                  (constraints.maxWidth - 16 * (columns - 1)) /
                                  columns,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: SurfaceCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          StatusBadge(
                                            tr(context, serviceLabel(b)),
                                          ),
                                          StatusBadge(
                                            '${tr(context, 'Booking')}: ${tr(context, '${b['status']}')}',
                                            neutral: true,
                                          ),
                                          if ((b['assignment']
                                                  as Map?)?['conflict'] ==
                                              true)
                                            const StatusBadge(
                                              'Needs review',
                                              danger: true,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        '${b['visitorName']}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${tr(context, 'Visitor Phone Number')}: ${b['visitorPhone'] ?? tr(context, 'Not recorded')}',
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${b['bookingReference']} · ${tr(context, 'Token')} ${b['tokenStart'] ?? '—'}',
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 20,
                                        runSpacing: 8,
                                        children: [
                                          AppText(
                                            VisitClock.dayLabel(
                                              '${b['visitDate']}',
                                            ),
                                          ),
                                          Text(
                                            '${VisitClock.timeLabel('${b['startTime']}')} – ${VisitClock.timeLabel('${b['endTime']}')}',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      AppText(
                                        (b['assignment']
                                                    as Map?)?['displayName']
                                                as String? ??
                                            'Khadim assignment pending',
                                      ),
                                      const SizedBox(height: 16),
                                      if (!widget.staff &&
                                          (b['status'] == 'confirmed' ||
                                              b['checkedInAt'] != null) &&
                                          serviceLabel(b) != 'Completed')
                                        FilledButton.icon(
                                          onPressed: () => showDialog<void>(
                                            context: context,
                                            builder: (_) =>
                                                AssignDialog(booking: b),
                                          ),
                                          icon: const Icon(
                                            Icons.person_add_alt,
                                          ),
                                          label: AppText(
                                            (b['assignment']
                                                        as Map?)?['khadimId'] ==
                                                    null
                                                ? 'Assign Khadim'
                                                : 'Review assignment',
                                          ),
                                        ),
                                      if (widget.staff &&
                                          (b['status'] == 'confirmed' ||
                                              b['checkedInAt'] != null))
                                        Wrap(
                                          spacing: 8,
                                          children: [
                                            if (serviceLabel(b) == 'Assigned')
                                              FilledButton(
                                                onPressed: busy
                                                    ? null
                                                    : () => transition(
                                                        b,
                                                        'inProgress',
                                                      ),
                                                child: const AppText(
                                                  'Start visit',
                                                ),
                                              ),
                                            if (serviceLabel(b) ==
                                                'In progress')
                                              FilledButton(
                                                onPressed: busy
                                                    ? null
                                                    : () => transition(
                                                        b,
                                                        'completed',
                                                      ),
                                                child: const AppText(
                                                  'Complete visit',
                                                ),
                                              ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class AssignDialog extends ConsumerStatefulWidget {
  const AssignDialog({super.key, required this.booking});
  final Record booking;
  @override
  ConsumerState<AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends ConsumerState<AssignDialog> {
  final reason = TextEditingController();
  List<Record>? candidates;
  String? selected, error;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final result = await ref.read(assignmentsRepositoryProvider).call(
        'assignmentCandidates',
        {'bookingId': widget.booking['id']},
      );
      if (mounted) {
        setState(
          () => candidates = (result['candidates'] as List)
              .map((x) => Map<String, dynamic>.from(x as Map))
              .toList(),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = failureMessage(e));
    }
  }

  Future<void> save({bool remove = false}) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(assignmentsRepositoryProvider).call('adminAssignKhadim', {
        'bookingId': widget.booking['id'],
        'khadimId': remove ? null : selected,
        'reason': reason.text,
        'revision': (widget.booking['assignment'] as Map?)?['revision'] ?? 0,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = failureMessage(e));
      await load();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(assignmentSchedulesProvider(null), (previous, next) {
      if (previous != null && next.hasValue) load();
    });
    ref.listen(assignmentBookingsProvider(null), (previous, next) {
      if (previous != null && next.hasValue) load();
    });
    final assigned =
        (widget.booking['assignment'] as Map?)?['khadimId'] != null;
    return AlertDialog(
      title: AppText(assigned ? 'Reassign Khadim' : 'Assign Khadim'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.booking['visitorName']} · ${widget.booking['bookingReference']}',
              ),
              const SizedBox(height: 8),
              AppText('Availability for the selected booking time'),
              Text(
                '${widget.booking['visitDate']} · ${VisitClock.timeLabel('${widget.booking['startTime']}')} – ${VisitClock.timeLabel('${widget.booking['endTime']}')}',
              ),
              const Divider(height: 28),
              if (candidates == null && error == null)
                const Center(child: CircularProgressIndicator()),
              if (candidates != null &&
                  !candidates!.any((c) => c['eligible'] == true))
                const AppText('No khadim available for this time'),
              for (final c in candidates ?? <Record>[])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: busy || c['eligible'] != true
                        ? null
                        : () => setState(() => selected = c['uid'] as String),
                    style: OutlinedButton.styleFrom(
                      disabledForegroundColor: AppColors.muted,
                      backgroundColor: selected == c['uid']
                          ? AppColors.mint
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            selected == c['uid']
                                ? Icons.check_circle
                                : Icons.person_outline,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${c['name']}'),
                                Text(
                                  '${tr(context, '${c['state']}')} · ${c['workload']}/${c['capacity']} ${tr(context, 'active visits')}',
                                ),
                                if (c['eligible'] != true)
                                  AppText('${c['reason']}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (assigned)
                TextField(
                  controller: reason,
                  maxLength: 500,
                  decoration: InputDecoration(
                    label: AppText('Reason for change'),
                    helperText: tr(
                      context,
                      'Required for reassignment or removal',
                    ),
                  ),
                ),
              if (error != null)
                Semantics(
                  liveRegion: true,
                  child: AppText(
                    error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const AppText('Cancel'),
        ),
        if (assigned)
          TextButton(
            onPressed: busy ? null : () => save(remove: true),
            child: const AppText('Remove assignment'),
          ),
        FilledButton(
          onPressed: busy || selected == null ? null : save,
          child: AppText(busy ? 'Saving…' : 'Confirm assignment'),
        ),
      ],
    );
  }
}

class AvailabilityPage extends ConsumerStatefulWidget {
  const AvailabilityPage({super.key, this.staff = false});
  final bool staff;
  @override
  ConsumerState<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends ConsumerState<AvailabilityPage> {
  Timer? clock;
  @override
  void initState() {
    super.initState();
    clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  String day = VisitClock.today(), uid = '';
  bool available = true, busy = false, acknowledge = false;
  String? error;
  final hours = TextEditingController(text: '07:00-19:00'),
      breaks = TextEditingController(),
      unavailable = TextEditingController(),
      capacity = TextEditingController(text: '1');
  @override
  void dispose() {
    clock?.cancel();
    for (final c in [hours, breaks, unavailable, capacity]) {
      c.dispose();
    }
    super.dispose();
  }

  List<Record> ranges(String value) => value.trim().isEmpty
      ? []
      : value.split(',').map((v) {
          final pair = v.trim().split('-');
          if (pair.length != 2) throw const FormatException('Use HH:mm-HH:mm');
          return {'start': pair[0].trim(), 'end': pair[1].trim()};
        }).toList();
  void edit(Record s) {
    setState(() {
      uid = '${s['khadimId']}';
      day = '${s['visitDate']}';
      available = s['available'] == true;
      capacity.text = '${s['capacity']}';
      String format(dynamic x) =>
          (x as List? ?? []).map((w) => '${w['start']}-${w['end']}').join(', ');
      hours.text = format(s['hours']);
      breaks.text = format(s['breaks']);
      unavailable.text = format(s['unavailable']);
    });
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final self = ref.read(authProvider).asData?.value?.id;
      final result = await ref.read(assignmentsRepositoryProvider).call(
        widget.staff ? 'khadimSetAvailability' : 'adminSaveKhadimSchedule',
        {
          'khadimId': widget.staff ? self : uid,
          'visitDate': day,
          'available': available,
          'acknowledgeConflicts': acknowledge,
          if (!widget.staff) ...{
            'hours': ranges(hours.text),
            'breaks': ranges(breaks.text),
            'unavailable': ranges(unavailable.text),
            'capacity': int.parse(capacity.text),
          },
        },
      );
      if (mounted) {
        showMessage(
          context,
          (result['conflicts'] as List? ?? []).isEmpty
              ? 'Availability saved'
              : 'Saved. Affected bookings need admin review.',
        );
        setState(() => acknowledge = false);
      }
    } catch (e) {
      if (mounted) setState(() => error = failureMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffNames = widget.staff
        ? <String, String>{}
        : {
            for (final k
                in ref.watch(assignmentStaffProvider).asData?.value ??
                    <Record>[])
              '${k['id']}': '${k['name']}',
          };
    final liveBookings =
        ref
            .watch(
              assignmentBookingsProvider(
                widget.staff ? ref.watch(authProvider).asData?.value?.id : null,
              ),
            )
            .asData
            ?.value ??
        <Record>[];
    final self = widget.staff
        ? ref.watch(authProvider).asData?.value?.id
        : null;
    return PageContainer(
      width: 900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeading(
            'Khadim availability',
            eyebrow: 'WORKING SCHEDULE',
            subtitle:
                'Availability is checked for each visit. No schedule means off duty.',
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  context.go(widget.staff ? '/khadim' : '/admin/assignments'),
              icon: const Icon(Icons.arrow_back),
              label: const AppText('Back to visits'),
            ),
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.staff)
                  AsyncPanel(
                    value: ref.watch(assignmentStaffProvider),
                    builder: (staff) => DropdownButtonFormField<String>(
                      isExpanded: true,
                      key: ValueKey(uid),
                      initialValue: uid.isEmpty ? null : uid,
                      decoration: InputDecoration(label: AppText('Khadim')),
                      items: [
                        for (final k in staff)
                          DropdownMenuItem(
                            value: '${k['id']}',
                            child: Text('${k['name']}'),
                          ),
                      ],
                      onChanged: busy ? null : (v) => setState(() => uid = v!),
                    ),
                  ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: DateTime.parse(day),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (d != null) {
                            setState(() => day = VisitClock.dayKey(d));
                          }
                        },
                  icon: const Icon(Icons.calendar_month),
                  label: AppText(VisitClock.dayLabel(day)),
                ),
                const SizedBox(height: 16),
                if (!widget.staff) ...[
                  for (final item in [
                    (hours, 'Working hours'),
                    (breaks, 'Breaks'),
                    (unavailable, 'Unavailable periods'),
                    (capacity, 'Concurrent visit capacity'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        controller: item.$1,
                        enabled: !busy,
                        decoration: InputDecoration(
                          label: AppText(item.$2),
                          helperText: item.$1 == capacity
                              ? tr(context, 'Default: one overlapping visit')
                              : tr(context, 'HH:mm-HH:mm, separated by commas'),
                        ),
                      ),
                    ),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const AppText('Available within working hours'),
                  subtitle: const AppText(
                    'This does not extend your permitted schedule.',
                  ),
                  value: available,
                  onChanged: busy ? null : (v) => setState(() => available = v),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const AppText('Flag affected visits for admin review'),
                  subtitle: const AppText(
                    'Existing assignments stay assigned. Inform the administrator before changing availability.',
                  ),
                  value: acknowledge,
                  onChanged: busy
                      ? null
                      : (v) => setState(() => acknowledge = v!),
                ),
                if (error != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: busy || (!widget.staff && uid.isEmpty)
                      ? null
                      : save,
                  child: AppText(busy ? 'Saving…' : 'Save availability'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AsyncPanel(
            value: ref.watch(assignmentSchedulesProvider(self)),
            builder: (items) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (items.isEmpty)
                  const EmptyState(
                    title: 'No working schedule configured',
                    detail:
                        'Ask an administrator to configure your schedule first.',
                  ),
                for (final s in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${staffNames[s['khadimId']] ?? tr(context, 'Your schedule')} · ${s['visitDate']}',
                          ),
                          StatusBadge(
                            '${tr(context, 'Available now')}: ${tr(context, availabilityNow(s, liveBookings))}',
                            neutral: true,
                          ),
                          const SizedBox(height: 8),
                          AppText(
                            s['available'] == true
                                ? 'Available within working hours'
                                : 'Unavailable',
                          ),
                          Text(
                            (s['hours'] as List? ?? [])
                                .map(
                                  (w) =>
                                      '${VisitClock.timeLabel('${w['start']}')} – ${VisitClock.timeLabel('${w['end']}')}',
                                )
                                .join(', '),
                          ),
                          Text('${tr(context, 'Capacity')}: ${s['capacity']}'),
                          TextButton(
                            onPressed: () => edit(s),
                            child: const AppText('Edit schedule'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
