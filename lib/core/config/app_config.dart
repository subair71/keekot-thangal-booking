import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'app_config.g.dart';

@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) => const AppConfig();

class AppConfig {
  const AppConfig();
  String get environment =>
      const String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  bool get emulators => const bool.fromEnvironment('USE_EMULATORS');
  String get host =>
      const String.fromEnvironment('EMULATOR_HOST', defaultValue: '127.0.0.1');
  String get projectId => const String.fromEnvironment('FIREBASE_PROJECT_ID');
  String get apiKey => const String.fromEnvironment('FIREBASE_API_KEY');
  String get appId => const String.fromEnvironment('FIREBASE_APP_ID');
  String get senderId =>
      const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  String get authDomain => const String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  String get storageBucket =>
      const String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  String get region => const String.fromEnvironment(
    'FUNCTIONS_REGION',
    defaultValue: 'asia-south1',
  );
  String get vapidKey => const String.fromEnvironment('VAPID_KEY');
  String get appCheckKey => const String.fromEnvironment('APP_CHECK_SITE_KEY');
  bool get analytics => const bool.fromEnvironment('ENABLE_ANALYTICS');
  bool get configured =>
      projectId.isNotEmpty &&
      !projectId.startsWith('REPLACE_') &&
      apiKey.isNotEmpty &&
      appId.isNotEmpty;
}
