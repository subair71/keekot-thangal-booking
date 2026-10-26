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
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final wide = MediaQuery.sizeOf(context).width > 1200 && textScale <= 1.15;
    final user = ref.watch(authProvider).asData?.value;
    return Scaffold(
      endDrawer: Drawer(
        width: (MediaQuery.sizeOf(context).width * 0.88)
            .clamp(0.0, 360.0)
            .toDouble(),
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Row(
                children: [
                  const Emblem(size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppText(
                      'KEEKKOTT SAYYID ATTAKOYA THANGAL',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emerald,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Builder(
                      builder: (drawerContext) => IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        onPressed: () => Navigator.of(drawerContext).pop(),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
                  builder: (drawerContext) => _MenuItem(
                    icon: item.$2,
                    label: item.$1,
                    primary: item.$3 == '/book',
                    selected:
                        GoRouterState.of(context).uri.toString() == item.$3,
                    onTap: () {
                      Navigator.of(drawerContext).pop();
                      context.go(item.$3);
                    },
                  ),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: AppColors.outline),
              ),
              for (final item in [
                ('Contact us', Icons.mail_outline, '/contact'),
                if (user == null) ('Sign in with mobile', Icons.login, '/auth'),
                if (user != null && user.staff)
                  (
                    user.khadim ? 'Your visits' : 'Administration',
                    Icons.admin_panel_settings_outlined,
                    user.staffHome,
                  ),
                if (user != null &&
                    !user.admin &&
                    (user.khadim || user.can('gate')))
                  (
                    'Validate visitor pass',
                    Icons.qr_code_scanner,
                    user.khadim ? '/khadim/scan' : '/admin/gate',
                  ),
              ])
                Builder(
                  builder: (drawerContext) => _MenuItem(
                    icon: item.$2,
                    label: item.$1,
                    primary: item.$3 == '/book',
                    selected:
                        GoRouterState.of(context).uri.toString() == item.$3,
                    onTap: () {
                      Navigator.of(drawerContext).pop();
                      context.go(item.$3);
                    },
                  ),
                ),
              if (user != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: AppColors.outline),
                ),
                ListTile(
                  leading: const Icon(Icons.account_circle_outlined),
                  title: Text(user.maskedPhone),
                ),
                Builder(
                  builder: (drawerContext) => ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.emerald),
                    title: const AppText('Sign out'),
                    onTap: () async {
                      Navigator.of(drawerContext).pop();
                      try {
                        try {
                          await ref
                              .read(notificationRepositoryProvider)
                              .disable();
                        } catch (_) {
                          // Notification network failure must not prevent local sign-out.
                        }
                        await ref.read(authRepositoryProvider).signOut();
                        ref.read(draftProvider.notifier).clear();
                        if (context.mounted) context.go('/');
                      } catch (e) {
                        if (context.mounted) {
                          showMessage(context, failureMessage(e));
                        }
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          (wide ? 120 : 108) * textScale.clamp(1.0, 1.5),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            border: const Border(bottom: BorderSide(color: AppColors.outline)),
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
                constraints: const BoxConstraints(maxWidth: 1320),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 32 : 12,
                    vertical: wide ? 6 : 4,
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
                                          fontSize: wide ? 22 : 16,
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

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final foreground = primary ? AppColors.white : AppColors.emerald;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        selected: selected,
        child: Material(
          color: primary
              ? AppColors.emerald
              : selected
              ? AppColors.mint
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 2,
            ),
            minLeadingWidth: 24,
            horizontalTitleGap: 12,
            leading: Icon(icon, size: 22, color: foreground),
            title: AppText(
              label,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                fontWeight: primary || selected
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: foreground,
              ),
            ),
            trailing: Icon(Icons.chevron_right, size: 18, color: foreground),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
