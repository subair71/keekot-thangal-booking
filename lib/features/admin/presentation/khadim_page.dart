import '../../../core/localization/app_language.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../core/widgets/components.dart';

// The query is unchanged; a provider makes loading/error/mobile states testable.
final khadimAccountsProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>(
      (ref) => FirebaseFirestore.instance
          .collection('khadims')
          .orderBy('name')
          .snapshots()
          .map(
            (snapshot) => [
              for (final doc in snapshot.docs) {...doc.data(), 'uid': doc.id},
            ],
          ),
    );

const _permissions = {
  'bookings': 'Book visits for visitors',
  'slots': 'Slots, closures and date hours',
  'settings': 'Booking settings',
  'gate': 'Scan and confirm visitor passes',
};

class KhadimLoginPage extends ConsumerStatefulWidget {
  const KhadimLoginPage({super.key});
  @override
  ConsumerState<KhadimLoginPage> createState() => _LoginState();
}

class _LoginState extends ConsumerState<KhadimLoginPage> {
  final phone = TextEditingController(text: '+91');
  final password = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await ref.read(firebaseBookingProvider).call(
        'khadimLogin',
        {'phone': phone.text, 'password': password.text},
      );
      await FirebaseAuth.instance.signInWithCustomToken(
        result['token'] as String,
      );
      password.clear();
    } catch (e) {
      if (mounted) setState(() => error = failureMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageContainer(
    width: 560,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: Emblem(size: 64)),
        const SizedBox(height: 24),
        const PageHeading(
          'Khadim login',
          subtitle:
              'Use the phone number and six-digit password provided by the administrator.',
        ),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: phone,
                enabled: !busy,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  label: AppText('Phone number'),
                  helperText: tr(
                    context,
                    'Include country code, for example +91',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: password,
                enabled: !busy,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (_) => login(),
                decoration: InputDecoration(
                  label: AppText('Six-digit password'),
                ),
              ),
              if (error != null)
                AppText(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: busy ? null : login,
                child: AppText(busy ? 'Signing in…' : 'Sign in'),
              ),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const AppText('Visitor login'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class KhadimManagementPage extends ConsumerStatefulWidget {
  const KhadimManagementPage({super.key});
  @override
  ConsumerState<KhadimManagementPage> createState() => _ManagementState();
}

class _ManagementState extends ConsumerState<KhadimManagementPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      phone = TextEditingController(text: '+91'),
      password = TextEditingController();
  String? uid;
  Set<String> selected = {};
  bool enabled = true, busy = false;
  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  void reset() => setState(() {
    uid = null;
    name.clear();
    phone.text = '+91';
    password.clear();
    selected = {};
    enabled = true;
  });
  Future<void> save() async {
    if (!form.currentState!.validate() || busy) return;
    setState(() => busy = true);
    try {
      await ref.read(firebaseBookingProvider).call('adminSaveKhadim', {
        'uid': uid,
        'name': name.text.trim(),
        'phone': phone.text,
        'password': password.text,
        'permissions': selected.toList(),
        'enabled': enabled,
      });
      if (mounted) {
        reset();
        showMessage(
          context,
          'Khadim account saved. Share the login details privately.',
        );
      }
    } catch (e) {
      if (mounted) showMessage(context, failureMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> deleteKhadim(String targetUid, String targetName) async {
    if (busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: const AppText('Delete Khadim?'),
        content: AppText(
          'Delete $targetName permanently? Reassign active visits first. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const AppText('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const AppText('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      await ref.read(firebaseBookingProvider).call('adminDeleteKhadim', {
        'uid': targetUid,
      });
      if (mounted) {
        if (uid == targetUid) reset();
        showMessage(context, 'Khadim account deleted.');
      }
    } catch (e) {
      if (mounted) showMessage(context, failureMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageContainer(
    width: 800,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton(
          onPressed: () => context.go('/admin/settings'),
          child: const AppText('Back to settings'),
        ),
        const PageHeading(
          'Khadim accounts',
          subtitle:
              'Every enabled Khadim can view their own visits. Choose additional operational permissions below. Booking reports and assignments are administrator-only.',
        ),
        SurfaceCard(
          child: LocalizedForm(
            formKey: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppText(
                  uid == null ? 'Create Khadim' : 'Edit Khadim',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: name,
                  enabled: !busy,
                  maxLength: 100,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? tr(context, 'Enter a name')
                      : null,
                  decoration: InputDecoration(label: const AppText('Name')),
                ),
                TextFormField(
                  controller: phone,
                  enabled: !busy,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? tr(context, 'Enter a phone number')
                      : null,
                  decoration: InputDecoration(
                    label: AppText('Phone number'),
                    helperText: tr(
                      context,
                      'Include country code, for example +91',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: password,
                  enabled: !busy,
                  obscureText: true,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => uid != null && (v ?? '').isEmpty
                      ? null
                      : RegExp(r'^\d{6}$').hasMatch(v ?? '')
                      ? null
                      : tr(context, 'Enter exactly six digits'),
                  decoration: InputDecoration(
                    label: AppText(
                      uid == null
                          ? 'Six-digit password'
                          : 'New six-digit password',
                    ),
                    helperText: uid == null
                        ? tr(context, 'Keep this password private')
                        : tr(
                            context,
                            'Leave blank to keep the current password',
                          ),
                  ),
                ),
                for (final item in _permissions.entries)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: AppText(item.value),
                    value: selected.contains(item.key),
                    onChanged: busy
                        ? null
                        : (v) => setState(() {
                            if (v == true) {
                              selected.add(item.key);
                            } else {
                              selected.remove(item.key);
                            }
                          }),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const AppText('Account enabled'),
                  value: enabled,
                  onChanged: busy ? null : (v) => setState(() => enabled = v),
                ),
                const AppText(
                  'Changes invalidate the current staff session. The Khadim must sign in again.',
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: busy ? null : save,
                  child: AppText(
                    busy
                        ? 'Saving…'
                        : uid == null
                        ? 'Create Khadim'
                        : 'Save changes',
                  ),
                ),
                if (uid != null)
                  TextButton(
                    onPressed: busy ? null : reset,
                    child: const AppText('Cancel editing'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        AsyncPanel(
          value: ref.watch(khadimAccountsProvider),
          onRetry: () => ref.invalidate(khadimAccountsProvider),
          builder: (accounts) {
            if (accounts.isEmpty) {
              return const EmptyState(title: 'No Khadim accounts yet.');
            }
            return Column(
              children: [
                for (final doc in accounts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppText(
                            doc['name'] as String,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text('${doc['phone']}'),
                          const SizedBox(height: 8),
                          StatusBadge(
                            doc['enabled'] == true ? 'Enabled' : 'Disabled',
                            neutral: doc['enabled'] != true,
                          ),
                          const SizedBox(height: 8),
                          AppText(
                            (doc['permissions'] as List)
                                .map((p) => tr(context, _permissions[p] ?? p))
                                .join(', '),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              TextButton.icon(
                                onPressed: busy
                                    ? null
                                    : () => deleteKhadim(
                                        doc['uid'] as String,
                                        doc['name'] as String,
                                      ),
                                icon: const Icon(Icons.delete_outline),
                                label: const AppText('Delete'),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: busy
                                    ? null
                                    : () => setState(() {
                                        uid = doc['uid'];
                                        name.text = doc['name'];
                                        phone.text = doc['phone'];
                                        password.clear();
                                        enabled = doc['enabled'] == true;
                                        selected = Set<String>.from(
                                          doc['permissions'],
                                        );
                                      }),
                                icon: const Icon(Icons.edit_outlined),
                                label: const AppText('Edit Khadim'),
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
    ),
  );
}
