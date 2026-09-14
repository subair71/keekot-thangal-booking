import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/components.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key, this.next = '/my-bookings'});
  final String next;
  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final phone = TextEditingController(text: '+91 '),
      code = TextEditingController();
  bool sent = false, busy = false, consent = false;
  String? error;
  int seconds = 0;
  Timer? timer;
  @override
  void dispose() {
    phone.dispose();
    code.dispose();
    timer?.cancel();
    super.dispose();
  }

  Future<void> submit() async {
    if (!consent) {
      setState(() => error = 'Please agree to receive the verification SMS.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
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
    ref.listen(authProvider, (_, next) {
      if (next.asData?.value != null) context.go(widget.next);
    });
    return PageContainer(
      width: 560,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: Emblem(size: 74)),
          const SizedBox(height: 28),
          PageHeading(
            sent ? 'Verify your mobile' : 'Welcome to your visit',
            subtitle: sent
                ? 'Enter the 6-digit code sent to your mobile.'
                : 'Sign in with your mobile number to reserve a visit and keep your pass.',
          ),
          SurfaceCard(
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: phone,
                    enabled: !sent && !busy,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                      helperText: 'Include country code, for example +91',
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
                      title: const Text(
                        'Send me a verification SMS',
                        style: TextStyle(fontSize: 15),
                      ),
                      subtitle: const Text(
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
                      style: const TextStyle(fontSize: 26, letterSpacing: 10),
                      decoration: const InputDecoration(
                        labelText: 'SMS verification code',
                        hintText: '000000',
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (error != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            sent
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
                      child: Text(
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
          const Text(
            'Your number stays with your account. It is never included in the QR code.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
