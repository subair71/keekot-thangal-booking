import 'package:web/web.dart' as web;

String? readLanguage() {
  try {
    return web.window.localStorage.getItem('keekkott.language');
  } catch (_) {
    return null;
  }
}

void saveLanguage(String value) {
  try {
    web.window.localStorage.setItem('keekkott.language', value);
  } catch (_) {
    /* Language switching also works when storage is unavailable. */
  }
}
