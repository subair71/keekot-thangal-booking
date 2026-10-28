import 'package:keekot_thangal/core/localization/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import 'components.dart';
import 'sanctuary_mobile_shell.dart';
import 'sanctuary_navigation_drawer.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});
  final Widget child;
  static const routes = ['/', '/book', '/my-bookings', '/information'];
  static const labels = [
    'Home',
    'Book Visit',
    'My Bookings',
    'Visitor Information',
  ];
  static const icons = [
    Icons.home_outlined,
    Icons.calendar_month_outlined,
    Icons.confirmation_number_outlined,
    Icons.info_outline,
  ];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final selected = path.startsWith('/book')
        ? 1
        : path.startsWith('/my-bookings') || path.startsWith('/pass')
        ? 2
        : path == '/information'
        ? 3
        : 0;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final wide = MediaQuery.sizeOf(context).width > 1200 && textScale <= 1.15;
    final mobile = MediaQuery.sizeOf(context).width < 768;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    const drawer = SanctuaryNavigationDrawer();
    return Scaffold(
      backgroundColor: mobile ? AppColors.canvas : null,
      drawerScrimColor: AppColors.forest.withValues(alpha: .46),
      drawer: mobile ? drawer : null,
      endDrawer: mobile ? null : drawer,
      appBar: mobile
          ? null
          : PreferredSize(
              preferredSize: Size.fromHeight(
                (wide ? 96 : 106) * textScale.clamp(1.0, 2.5),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  border: const Border(
                    bottom: BorderSide(color: AppColors.outline),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emerald.withValues(alpha: .025),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: wide ? 32 : 12,
                          vertical: wide ? 6 : 4,
                        ),
                        child: Flex(
                          direction: textScale > 1.3
                              ? Axis.vertical
                              : Axis.horizontal,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              fit: textScale > 1.3
                                  ? FlexFit.loose
                                  : FlexFit.tight,
                              child: InkWell(
                                onTap: () => context.go('/'),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Row(
                                    children: [
                                      Emblem(size: wide ? 48 : 30),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            AppText(
                                              textScale > 1.3
                                                  ? 'Keekkott Bungalow'
                                                  : 'KEEKKOTT SAYYID ATTAKOYA THANGAL',
                                              maxLines: wide ? 2 : 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: 'Playfair Display',
                                                fontWeight: FontWeight.w700,
                                                fontSize: wide ? 22 : 16,
                                                height: 1.2,
                                                color: AppColors.emerald,
                                              ),
                                            ),
                                            if (AppLanguage.of(context) != 'ml')
                                              AppText(
                                                'MAQAM · CHAVAKKAD',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: wide ? 12 : 11,
                                                  height: 1.2,
                                                  color: AppColors.muted,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (wide) ...[
                              for (var i = 0; i < routes.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Semantics(
                                    selected: selected == i,
                                    child: TextButton(
                                      onPressed: () => context.go(routes[i]),
                                      style: TextButton.styleFrom(
                                        backgroundColor: selected == i
                                            ? AppColors.emerald
                                            : null,
                                        foregroundColor: selected == i
                                            ? AppColors.white
                                            : AppColors.muted,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                      ),
                                      child: AppText(
                                        AppLanguage.of(context) == 'ml'
                                            ? [
                                                'ഹോം',
                                                'ബുക്കിംഗ്',
                                                'എന്റെ പാസ്',
                                                'വിവരങ്ങൾ',
                                              ][i]
                                            : labels[i],
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                            ],
                            Flex(
                              direction: wide || textScale > 1.3
                                  ? Axis.horizontal
                                  : Axis.vertical,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SanctuaryMenuButton(),
                                    IconButton(
                                      tooltip: tr(context, 'Notifications'),
                                      onPressed: () =>
                                          context.go('/notifications'),
                                      icon: const Icon(
                                        Icons.notifications_none,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
      body: mobile
          ? Column(
              children: [
                SanctuaryMobileHeader(keyboardOpen: keyboardOpen),
                Expanded(child: child),
              ],
            )
          : child,
      bottomNavigationBar: keyboardOpen && mobile
          ? null
          : mobile
          ? const SanctuaryMobileNavigation()
          : wide
          ? null
          : NavigationBar(
              height: textScale > 1.3 ? 88 : 64,
              labelTextStyle: AppLanguage.of(context) == 'ml'
                  ? WidgetStateProperty.resolveWith(
                      (states) => Theme.of(context)
                          .navigationBarTheme
                          .labelTextStyle!
                          .resolve(states)
                          ?.copyWith(fontFamily: 'Noto Sans Malayalam'),
                    )
                  : null,
              selectedIndex: selected,
              onDestinationSelected: (i) => context.go(routes[i]),
              destinations: [
                for (var i = 0; i < routes.length; i++)
                  NavigationDestination(
                    icon: Icon(icons[i], size: 20),
                    selectedIcon: Icon(
                      [
                        Icons.home_rounded,
                        Icons.calendar_month_rounded,
                        Icons.confirmation_number_rounded,
                        Icons.info_rounded,
                      ][i],
                      size: 21,
                    ),
                    label: tr(context, ['Home', 'Book', 'Bookings', 'Info'][i]),
                  ),
              ],
            ),
    );
  }
}
