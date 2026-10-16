import 'package:keekot_thangal/core/localization/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/bootstrap/providers.dart';
import '../../app/theme/app_theme.dart';
import 'components.dart';

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
    final wide = MediaQuery.sizeOf(context).width > 1024;
    final user = ref.watch(authProvider).asData?.value;
    return Scaffold(
      endDrawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Builder(
                  builder: (drawerContext) => IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.of(drawerContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
              for (final item in const [
                ('Book a visit', Icons.calendar_month_outlined, '/book'),
                ('Visitor guide', Icons.menu_book_outlined, '/?section=guide'),
                ('Videos', Icons.play_circle_outline, '/?section=videos'),
                (
                  'Questions before you visit',
                  Icons.help_outline,
                  '/?section=questions',
                ),
              ])
                Builder(
                  builder: (drawerContext) => ListTile(
                    leading: Icon(item.$2, color: AppColors.emerald),
                    title: AppText(
                      item.$1,
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () {
                      Navigator.of(drawerContext).pop();
                      context.go(item.$3);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(wide ? 136 : 108),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(bottom: BorderSide(color: AppColors.outline)),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 32 : 12,
                    vertical: wide ? 10 : 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
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
                                        'KEEKKOTT SAYYID ATTAKOYA THANGAL',
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Newsreader',
                                          fontWeight: FontWeight.w700,
                                          fontSize: wide ? 24 : 16,
                                          height: 1.2,
                                          color: AppColors.emerald,
                                        ),
                                      ),
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
                                      ? AppColors.mint
                                      : null,
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
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const HeaderLanguageToggle(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Builder(
                                builder: (scaffoldContext) => IconButton(
                                  key: const ValueKey('header-menu'),
                                  tooltip: AppLanguage.of(context) == 'ml'
                                      ? 'മെനു'
                                      : 'Menu',
                                  onPressed: () => Scaffold.of(
                                    scaffoldContext,
                                  ).openEndDrawer(),
                                  icon: const Icon(Icons.menu),
                                ),
                              ),
                              IconButton(
                                tooltip: tr(context, 'Notifications'),
                                onPressed: () => context.go('/notifications'),
                                icon: const Icon(Icons.notifications_none),
                              ),
                              PopupMenuButton<String>(
                                tooltip: tr(
                                  context,
                                  user == null ? 'Sign in' : 'Account',
                                ),
                                icon: const Icon(Icons.account_circle_outlined),
                                onSelected: (value) async {
                                  if (value == 'signout') {
                                    try {
                                      try {
                                        await ref
                                            .read(
                                              notificationRepositoryProvider,
                                            )
                                            .disable();
                                      } catch (_) {
                                        // Notification network failure must not prevent local sign-out.
                                      }
                                      await ref
                                          .read(authRepositoryProvider)
                                          .signOut();
                                      ref.read(draftProvider.notifier).clear();
                                      if (context.mounted) context.go('/');
                                    } catch (e) {
                                      if (context.mounted) {
                                        showMessage(context, failureMessage(e));
                                      }
                                    }
                                  } else {
                                    context.go(value);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: '/contact',
                                    child: AppText('Contact us'),
                                  ),
                                  if (user == null)
                                    const PopupMenuItem(
                                      value: '/auth',
                                      child: AppText('Sign in with mobile'),
                                    ),
                                  if (user != null)
                                    PopupMenuItem(
                                      enabled: false,
                                      child: Text(user.maskedPhone),
                                    ),
                                  if (user?.staff == true)
                                    const PopupMenuItem(
                                      value: '/admin',
                                      child: AppText('Administration'),
                                    ),
                                  if (user?.gate == true && user?.admin != true)
                                    const PopupMenuItem(
                                      value: '/admin/gate',
                                      child: AppText('Validate visitor pass'),
                                    ),
                                  if (user != null)
                                    const PopupMenuItem(
                                      value: 'signout',
                                      child: AppText('Sign out'),
                                    ),
                                ],
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
      body: child,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              height: 64,
              selectedIndex: selected,
              onDestinationSelected: (i) => context.go(routes[i]),
              destinations: [
                for (var i = 0; i < routes.length; i++)
                  NavigationDestination(
                    icon: Icon(icons[i], size: 20),
                    label: tr(context, ['Home', 'Book', 'Bookings', 'Info'][i]),
                  ),
              ],
            ),
    );
  }
}
