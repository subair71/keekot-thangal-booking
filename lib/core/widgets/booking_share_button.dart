import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_language.dart';
import '../services/sharing/booking_share.dart';
import 'components.dart';

class BookingShareButton extends StatefulWidget {
  const BookingShareButton({super.key, this.compact = false});
  final bool compact;

  @override
  State<BookingShareButton> createState() => _BookingShareButtonState();
}

class _BookingShareButtonState extends State<BookingShareButton> {
  bool busy = false;

  Future<void> share() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final handled = await shareBookingMessage(bookingShareMessage);
      if (handled || !mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const AppText('Share booking link'),
          content: const SingleChildScrollView(
            child: SelectableText(
              bookingShareMessage,
              style: TextStyle(fontFamily: 'Noto Sans Malayalam', height: 1.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const AppText('Close'),
            ),
            TextButton.icon(
              icon: const Icon(Icons.copy_outlined),
              label: const AppText('Copy message'),
              onPressed: () async {
                try {
                  await Clipboard.setData(
                    const ClipboardData(text: bookingShareMessage),
                  );
                  if (dialogContext.mounted) {
                    showMessage(dialogContext, 'Message copied');
                    Navigator.pop(dialogContext);
                  }
                } catch (_) {
                  if (dialogContext.mounted) {
                    showMessage(
                      dialogContext,
                      'Select the message to copy it.',
                    );
                  }
                }
              },
            ),
            FilledButton.icon(
              icon: const Icon(Icons.chat_outlined),
              label: const AppText('WhatsApp'),
              onPressed: () async {
                try {
                  final opened = await launchUrl(
                    Uri.https('wa.me', '/', {'text': bookingShareMessage}),
                    mode: LaunchMode.externalApplication,
                  );
                  if (!opened && dialogContext.mounted) {
                    showMessage(
                      dialogContext,
                      'Please copy the message instead.',
                    );
                  }
                } catch (_) {
                  if (dialogContext.mounted) {
                    showMessage(
                      dialogContext,
                      'Please copy the message instead.',
                    );
                  }
                }
              },
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => widget.compact
      ? IconButton(
          tooltip: tr(context, 'Share booking link'),
          onPressed: busy ? null : share,
          icon: const Icon(Icons.share_outlined),
        )
      : OutlinedButton.icon(
          onPressed: busy ? null : share,
          icon: const Icon(Icons.share_outlined),
          label: const AppText('Share booking link'),
        );
}
