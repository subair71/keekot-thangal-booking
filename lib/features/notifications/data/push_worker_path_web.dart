import 'package:web/web.dart' as web;

String get pushWorkerPath => Uri.parse(
  web.document.baseURI,
).resolve('firebase-messaging-sw.js').toString();
