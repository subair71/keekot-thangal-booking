import 'package:keekot_thangal/core/localization/app_language.dart';

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/components.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key, this.next = '/my-bookings', this.admin = false});
  final String next;
  final bool admin;
  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final phone = TextEditingController(text: '+91 '),
      code = TextEditingController();
  final username = TextEditingController(), password = TextEditingController();
  bool hidePassword = true;
  bool sent = false, busy = false, consent = false;
  String? error;
  int seconds = 0;
  Timer? timer;
  @override
  void dispose() {
    username.dispose();
    password.dispose();
    phone.dispose();
    code.dispose();
    timer?.cancel();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy) return;
    if (!widget.admin && !consent) {
      setState(() => error = 'Please agree to receive the verification SMS.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (widget.admin) {
        final result = await ref.read(firebaseBookingProvider).call(
          'adminLogin',
          {'username': username.text.trim(), 'password': password.text},
        );
        await FirebaseAuth.instance.signInWithCustomToken(
          result['token'] as String,
        );
        password.clear();
        return;
      }
      final auth = ref.read(authRepositoryProvider);
      if (!sent) {
        await auth.sendCode(phone.text.replaceAll(RegExp(r'\s'), ''));
        if (!mounted) return;
        setState(() {
          sent = true;
          seconds = 60;
        });
        timer?.cancel();
        timer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) return;
          setState(() => seconds--);
          if (seconds <= 0) t.cancel();
        });
      } else {
        await auth.verifyCode(code.text.trim());
      }
    } catch (e) {
      if (mounted) setState(() => error = failureMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      width: 560,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Emblem(size: 64),
            ),
          ),
          const SizedBox(height: 28),
          PageHeading(
            sent
                ? 'Verify your mobile'
                : widget.admin
                ? 'Administrator login'
                : 'Welcome to your visit',
            subtitle: sent
                ? 'Enter the 6-digit code sent to your mobile.'
                : widget.admin
                ? 'Sign in with your administrator username and password.'
                : 'Sign in with your mobile number to reserve a visit and keep your pass.',
          ),
          SurfaceCard(
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.admin) ...[
                    TextField(
                      controller: username,
                      enabled: !busy,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        label: const AppText('Username'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: password,
                      enabled: !busy,
                      obscureText: hidePassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => submit(),
                      decoration: InputDecoration(
                        label: AppText('Password'),
                        suffixIcon: IconButton(
                          tooltip: hidePassword
                              ? tr(context, 'Show password')
                              : tr(context, 'Hide password'),
                          onPressed: () =>
                              setState(() => hidePassword = !hidePassword),
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: phone,
                      enabled: !sent && !busy,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      decoration: InputDecoration(
                        label: AppText('Mobile number'),
                        helperText: tr(
                          context,
                          'Include country code, for example +91',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!sent)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: consent,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: busy
                            ? null
                            : (v) => setState(() => consent = v ?? false),
                        title: const AppText(
                          'Send me a verification SMS',
                          style: TextStyle(fontSize: 15),
                        ),
                        subtitle: const AppText(
                          'Google processes your number for verification and abuse prevention.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    if (sent) ...[
                      TextField(
                        controller: code,
                        autofocus: true,
                        enabled: !busy,
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => busy ? null : submit(),
                        style: const TextStyle(fontSize: 22, letterSpacing: 3),
                        decoration: InputDecoration(
                          label: AppText('SMS verification code'),
                          hintText: tr(context, '000000'),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (busy && !sent) ...[
                      const AppText(
                        'Waiting for phone verification. Complete the security '
                        'check if it appears. This can take up to 90 seconds.',
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                  const SizedBox(height: 16),
                  if (error != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: AppText(
                        error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  FilledButton(
                    onPressed: busy ? null : submit,
                    child: busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.ivory,
                            ),
                          )
                        : AppText(
                            widget.admin
                                ? 'Sign in'
                                : sent
                                ? 'Verify and continue'
                                : 'Send verification code',
                          ),
                  ),
                  if (sent)
                    TextButton(
                      onPressed: seconds > 0 || busy
                          ? null
                          : () {
                              setState(() {
                                sent = false;
                                code.clear();
                              });
                            },
                      child: AppText(
                        seconds > 0
                            ? 'Request a new code in ${seconds}s'
                            : 'Change number or send a new code',
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (!widget.admin)
            const AppText(
              'Your number stays with your account. It is never included in the QR code.',
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
