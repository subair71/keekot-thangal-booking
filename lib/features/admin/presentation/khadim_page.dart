import '../../../core/localization/app_language.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../core/widgets/components.dart';

const _permissions = {
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
                  labelText: tr(context, 'Phone number'),
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
                  labelText: tr(context, 'Six-digit password'),
                ),
              ),
              if (error != null)
                Text(
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

  @override
  Widget build(BuildContext context) => PageContainer(
    width: 800,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton(
          onPressed: () => context.go('/admin/settings'),
          child: const Text('Back to settings'),
        ),
        const PageHeading(
          'Khadim accounts',
          subtitle:
              'Every enabled Khadim can view their own visits. Choose additional operational permissions below. Booking reports and assignments are administrator-only.',
        ),
        SurfaceCard(
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  uid == null ? 'Create Khadim' : 'Edit Khadim',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: name,
                  enabled: !busy,
                  maxLength: 100,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter a name' : null,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextFormField(
                  controller: phone,
                  enabled: !busy,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter a phone number'
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    helperText: 'Include country code, for example +91',
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
                      : 'Enter exactly six digits',
                  decoration: InputDecoration(
                    labelText: uid == null
                        ? 'Six-digit password'
                        : 'New six-digit password',
                    helperText: uid == null
                        ? 'Keep this password private'
                        : 'Leave blank to keep the current password',
                  ),
                ),
                for (final item in _permissions.entries)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.value),
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
                  title: const Text('Account enabled'),
                  value: enabled,
                  onChanged: busy ? null : (v) => setState(() => enabled = v),
                ),
                const Text(
                  'Changes invalidate the current staff session. The Khadim must sign in again.',
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: busy ? null : save,
                  child: Text(
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
                    child: const Text('Cancel editing'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('khadims')
              .orderBy('name')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text(
                'Could not load Khadim accounts. Please try again.',
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.docs.isEmpty) {
              return const Text('No Khadim accounts yet.');
            }
            return Column(
              children: [
                for (final doc in snapshot.data!.docs)
                  ListTile(
                    title: Text(doc.data()['name'] as String),
                    subtitle: Text(
                      '${doc.data()['phone']} · ${doc.data()['enabled'] == true ? 'Enabled' : 'Disabled'}\n${(doc.data()['permissions'] as List).map((p) => _permissions[p] ?? p).join(', ')}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      tooltip: 'Edit access or reset password',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: busy
                          ? null
                          : () => setState(() {
                              uid = doc.id;
                              name.text = doc.data()['name'];
                              phone.text = doc.data()['phone'];
                              password.clear();
                              enabled = doc.data()['enabled'] == true;
                              selected = Set<String>.from(
                                doc.data()['permissions'],
                              );
                            }),
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
