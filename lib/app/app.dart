import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/app_config.dart';
import 'router/app_router.dart';
import 'bootstrap/providers.dart';
import 'theme/app_theme.dart';

class KeekotApp extends ConsumerWidget {
  const KeekotApp({super.key});
  static final _messenger = GlobalKey<ScaffoldMessengerState>();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    return MaterialApp.router(
      scaffoldMessengerKey: _messenger,
      title: 'Keekot Thangal | Visit Booking',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        final config = ref.watch(appConfigProvider);
        if (config.environment == 'production') return child!;
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
            Expanded(child: child!),
          ],
        );
      },
    );
  }
}
