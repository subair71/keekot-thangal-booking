import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'app/app.dart';
import 'app/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'core/widgets/components.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  const config = AppConfig();
  // Error metadata contains no names, numbers, tokens, or booking payloads.
  FlutterError.onError = (details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    } else {
      debugPrint('Flutter error: ${details.exception.runtimeType}');
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled app error: ${error.runtimeType}');
    return true;
  };
  try {
    if (!config.configured) throw StateError('Missing project configuration');
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: config.apiKey,
        appId: config.appId,
        messagingSenderId: config.senderId,
        projectId: config.projectId,
        authDomain: config.authDomain,
        storageBucket: config.storageBucket,
      ),
    );
    if (config.emulators) {
      if (config.environment == 'production' ||
          !config.projectId.startsWith('demo-')) {
        throw StateError('Emulators require a demo project');
      }
      await FirebaseAuth.instance.useAuthEmulator(config.host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(config.host, 8080);
      FirebaseFunctions.instanceFor(
        region: config.region,
      ).useFunctionsEmulator(config.host, 5001);
    } else {
      if (config.appCheckKey.isEmpty) {
        throw StateError('App Check configuration is required');
      }
      await FirebaseAppCheck.instance.activate(
        providerWeb: ReCaptchaV3Provider(config.appCheckKey),
      );
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(
        config.analytics,
      );
      if (config.analytics) {
        unawaited(
          FirebaseAnalytics.instance.logAppOpen().catchError((Object _) {}),
        );
      }
    }
    // Persistent Firestore disk caching is deliberately not enabled for shared visitor devices.
    runApp(const ProviderScope(child: KeekotApp()));
  } catch (e) {
    debugPrint('Startup failed: ${e.runtimeType}');
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const Scaffold(
          body: PageContainer(
            width: 620,
            child: EmptyState(
              title: 'Visit booking will be available soon',
              detail:
                  'The service is being prepared. Please check again later.',
            ),
          ),
        ),
      ),
    );
  }
}
