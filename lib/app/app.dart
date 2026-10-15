import '../core/localization/app_language.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import 'router/app_router.dart';
import 'bootstrap/providers.dart';
import 'theme/app_theme.dart';

class KeekotApp extends ConsumerStatefulWidget {
  const KeekotApp({super.key});
  @override
  ConsumerState<KeekotApp> createState() => _KeekotAppState();
}

class _KeekotAppState extends ConsumerState<KeekotApp> {
  SemanticsHandle? _semantics;
  @override
  void initState() {
    super.initState();
    if (kIsWeb) _semantics = SemanticsBinding.instance.ensureSemantics();
  }

  @override
  void dispose() {
    _semantics?.dispose();
    super.dispose();
  }

  static final _messenger = GlobalKey<ScaffoldMessengerState>();
  @override
  Widget build(BuildContext context) {
    if (ref.watch(appConfigProvider).configured) {
      ref.listen(foregroundMessagesProvider, (_, next) {
        final message = next.asData?.value;
        if (message != null) {
          _messenger.currentState?.showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      });
    }
    return LanguageRoot(
      child: Builder(
        builder: (context) => MaterialApp.router(
          locale: Locale(AppLanguage.of(context)),
          supportedLocales: const [Locale('en'), Locale('ml')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          scaffoldMessengerKey: _messenger,
          title: 'KEEKKOTT SAYYID ATTAKOYA THANGAL MAQAM',
          debugShowCheckedModeBanner: false,
          theme: AppLanguage.of(context) == 'ml'
              ? buildTheme().copyWith(
                  textTheme: buildTheme().textTheme.apply(
                    fontFamily: 'Noto Sans Malayalam',
                  ),
                )
              : buildTheme(),
          routerConfig: ref.watch(routerProvider),
          builder: (context, child) {
            final config = ref.watch(appConfigProvider);
            final content = child!;
            if (config.environment == 'production') return content;
            return Column(
              children: [
                Material(
                  color: AppColors.gold,
                  child: SafeArea(
                    bottom: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Text(
                          '${config.environment.toUpperCase()} · Test bookings only',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
  }
}
