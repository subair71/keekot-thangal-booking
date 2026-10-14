import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

// True means the share sheet handled the action, including user cancellation.
// False asks the UI to offer copy and WhatsApp alternatives.
Future<bool> shareBookingMessage(String message) async {
  final navigator = web.window.navigator;
  if (navigator.getProperty<JSAny?>('share'.toJS) == null) return false;
  try {
    // Keep the URL in the text so recipients receive the exact invitation once.
    await navigator.share(web.ShareData(text: message)).toDart;
    return true;
  } catch (error) {
    try {
      return (error as JSObject).getProperty<JSString?>('name'.toJS)?.toDart ==
          'AbortError';
    } catch (_) {
      return false;
    }
  }
}
