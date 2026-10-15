import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/widgets/components.dart';

class ContactPage extends ConsumerStatefulWidget {
  const ContactPage({super.key});

  @override
  ConsumerState<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends ConsumerState<ContactPage> {
  static const mailbox = 'keekkottbungalowonline@gmail.com';
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final subject = TextEditingController();
  final message = TextEditingController();
  bool sending = false;
  bool sent = false;
  String? error;

  @override
  void dispose() {
    for (final controller in [name, email, phone, subject, message]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (sending || !formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      sending = true;
      error = null;
    });
    try {
      final result = await ref
          .read(firebaseBookingProvider)
          .functions
          .httpsCallable('submitContact')
          .call<Map<String, dynamic>>({
            'name': name.text.trim(),
            'email': email.text.trim(),
            'phone': phone.text.trim(),
            'subject': subject.text.trim(),
            'message': message.text.trim(),
          });
      if (result.data['sent'] != true) throw StateError('Email not accepted');
      if (!mounted) return;
      setState(() => sent = true);
      for (final controller in [name, email, phone, subject, message]) {
        controller.clear();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error =
            e is FirebaseFunctionsException && e.code == 'resource-exhausted'
            ? 'Too many messages. Please try again later.'
            : 'Your message could not be sent. Please try again later or email us directly.';
      });
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Widget field(
    TextEditingController controller,
    String label, {
    int minimum = 2,
    int maximum = 100,
    int lines = 1,
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      controller: controller,
      enabled: !sending,
      keyboardType: keyboard,
      minLines: lines,
      maxLines: lines == 1 ? 1 : 8,
      maxLength: maximum,
      textInputAction: lines == 1
          ? TextInputAction.next
          : TextInputAction.newline,
      decoration: InputDecoration(labelText: tr(context, label)),
      validator: (raw) {
        final value = (raw ?? '').trim();
        if (value.length < minimum || value.length > maximum) {
          return tr(context, 'Please complete this field.');
        }
        if (controller == email &&
            !RegExp(r'^[^\s@<>]+@[^\s@<>]+\.[^\s@<>]+$').hasMatch(value)) {
          return tr(context, 'Enter a valid email address.');
        }
        if (controller == phone &&
            value.isNotEmpty &&
            !RegExp(r'^[+\d ()-]{6,30}$').hasMatch(value)) {
          return tr(context, 'Enter a valid phone number.');
        }
        return null;
      },
    ),
  );

  @override
  Widget build(BuildContext context) => PageContainer(
    width: 850,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeading(
          'Contact us',
          eyebrow: 'KEEKKOTT SAYYID ATTAKOYA THANGAL MAQAM',
          subtitle: 'Have a question about your visit? Send us a message.',
        ),
        SurfaceCard(
          child: sent
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.mark_email_read_outlined,
                      color: AppColors.emerald,
                      size: 48,
                    ),
                    const SizedBox(height: 20),
                    Semantics(
                      liveRegion: true,
                      child: const AppText(
                        'Thank you. Your message has been sent to our team.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => setState(() => sent = false),
                      child: const AppText('Send another message'),
                    ),
                  ],
                )
              : Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      field(name, 'Your name'),
                      field(
                        email,
                        'Email address',
                        maximum: 254,
                        keyboard: TextInputType.emailAddress,
                      ),
                      field(
                        phone,
                        'Phone number (optional)',
                        minimum: 0,
                        maximum: 30,
                        keyboard: TextInputType.phone,
                      ),
                      field(subject, 'Subject', minimum: 3, maximum: 120),
                      field(
                        message,
                        'Your message',
                        minimum: 10,
                        maximum: 3000,
                        lines: 5,
                        keyboard: TextInputType.multiline,
                      ),
                      const AppText(
                        'Your contact details and message will be emailed to the Maqam team so we can respond to your enquiry.',
                        style: TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                      const SizedBox(height: 20),
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
                      FilledButton.icon(
                        onPressed: sending ? null : submit,
                        icon: sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_outlined),
                        label: AppText(sending ? 'Sending…' : 'Send message'),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 24),
        const AppText('You can also email us directly.'),
        const SizedBox(height: 8),
        const SelectableText(mailbox),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.email_outlined),
            label: const AppText('Open email app'),
            onPressed: () async {
              try {
                final opened = await launchUrl(
                  Uri(scheme: 'mailto', path: mailbox),
                );
                if (!opened && context.mounted) {
                  showMessage(
                    context,
                    'Please copy the email address into your email app.',
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  showMessage(
                    context,
                    'Please copy the email address into your email app.',
                  );
                }
              }
            },
          ),
        ),
      ],
    ),
  );
}
