import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/bootstrap/providers.dart';
import '../../app/theme/app_theme.dart';
import '../localization/app_language.dart';
import '../utils/visit_clock.dart';
import 'components.dart';

/// The same navigation sheet serves mobile's left drawer and web's right drawer.
class SanctuaryNavigationDrawer extends ConsumerWidget {
  const SanctuaryNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = SanctuaryLayout.mobile(context);
    final user = ref.watch(authProvider).asData?.value;
    final uri = GoRouterState.of(context).uri;
    final bookings = ref.watch(myBookingsProvider).asData?.value;
    final notices = ref.watch(noticesProvider).asData?.value;
    final activePass = bookings?.any((booking) => booking.upcoming) ?? false;
    final unread = notices?.where((notice) => !notice.read).length ?? 0;

    bool selected(String route) => switch (route) {
      '/book' => uri.path == '/book' || uri.path.startsWith('/book/'),
      '/my-bookings' =>
        uri.path == '/my-bookings' ||
            uri.path.startsWith('/booking/') ||
            uri.path.startsWith('/pass/'),
      '/admin' => uri.path == '/admin' || uri.path.startsWith('/admin/'),
      '/auth' => uri.path == '/auth' || uri.path == '/login',
      _ => uri.toString() == route,
    };

    Widget link(String label, IconData icon, String route, {Widget? badge}) =>
        _NavigationItem(
          label: label,
          icon: icon,
          primary: route == '/book',
          selected: selected(route),
          badge: badge,
          onTap: () {
            Navigator.of(context).pop();
            context.go(route);
          },
        );

    final entries = <Widget>[
      link('Book a visit', Icons.edit_calendar_outlined, '/book'),
      const SizedBox(height: 8),
      link('Visitor guide', Icons.menu_book_outlined, '/?section=guide'),
      link('Videos', Icons.play_circle_outline, '/?section=videos'),
      link(
        'Questions before you visit',
        Icons.help_outline,
        '/?section=questions',
      ),
      const _NavigationDivider(),
      link(
        'My Pass',
        Icons.confirmation_number_outlined,
        '/my-bookings',
        badge: activePass ? const _NavigationBadge('Active pass') : null,
      ),
      link(
        'Notifications',
        Icons.notifications_none,
        '/notifications',
        badge: unread > 0 ? _NavigationBadge('$unread', dark: true) : null,
      ),
      link('Contact us', Icons.mail_outline, '/contact'),
      if (user == null) link('Sign in with mobile', Icons.login, '/auth'),
      if (user?.staff == true)
        link('Administration', Icons.verified_user_outlined, '/admin'),
      if (user?.gate == true && user?.admin != true)
        link('Validate visitor pass', Icons.qr_code_scanner, '/admin/gate'),
      if (user != null) ...[
        const _NavigationDivider(),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SanctuaryNavigationColors.container,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SanctuaryNavigationColors.border),
          ),
          child: InfoLine(
            Icons.account_circle_outlined,
            user.admin
                ? 'Administrator'
                : user.khadim
                ? 'Khadim'
                : 'Your account',
            user.maskedPhone,
          ),
        ),
        const SizedBox(height: 6),
        _NavigationItem(
          label: 'Sign out',
          icon: Icons.logout,
          onTap: () async {
            // Capture dependencies before closing the sheet disposes its ref.
            final auth = ref.read(authRepositoryProvider);
            final draft = ref.read(draftProvider.notifier);
            final router = GoRouter.of(context);
            final shellContext = Scaffold.of(context).context;
            final notificationCleanup = () async {
              try {
                await ref.read(notificationRepositoryProvider).disable();
              } catch (_) {
                // Notification failure must not prevent local sign-out.
              }
            }();
            Navigator.of(context).pop();
            try {
              await notificationCleanup;
              await auth.signOut();
              draft.clear();
              router.go('/');
            } catch (error) {
              if (shellContext.mounted) {
                showMessage(shellContext, failureMessage(error));
              }
            }
          },
        ),
      ],
    ];

    return Drawer(
      width: (MediaQuery.sizeOf(context).width * .88).clamp(0.0, 400.0),
      backgroundColor: AppColors.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 18,
      shadowColor: AppColors.forest.withValues(alpha: .3),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: SanctuaryNavigationColors.border),
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(mobile ? 0 : 20),
          right: Radius.circular(mobile ? 20 : 0),
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // On short screens / with larger text the footer scrolls with links.
            final pinFooter =
                constraints.maxHeight >= 640 &&
                MediaQuery.textScalerOf(context).scale(1) <= 1.4;
            return Column(
              children: [
                const _NavigationHeader(),
                Expanded(
                  child: ListView(
                    key: const ValueKey('navigation-links'),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    children: [
                      ...entries,
                      if (!pinFooter) const _NavigationFooter(),
                    ],
                  ),
                ),
                if (pinFooter) const _NavigationFooter(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class SanctuaryMenuButton extends StatelessWidget {
  const SanctuaryMenuButton({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: IconButton.filledTonal(
      key: const ValueKey('header-menu'),
      tooltip: tr(context, 'Menu'),
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: SanctuaryNavigationColors.container,
        foregroundColor: AppColors.emerald,
        side: const BorderSide(color: SanctuaryNavigationColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        FocusManager.instance.primaryFocus?.unfocus();
        final scaffold = Scaffold.of(context);
        if (SanctuaryLayout.mobile(context)) {
          scaffold.openDrawer();
        } else {
          scaffold.openEndDrawer();
        }
      },
      icon: const Icon(Icons.menu, size: 20),
    ),
  );
}

class _NavigationHeader extends StatelessWidget {
  const _NavigationHeader();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [SanctuaryNavigationColors.container, AppColors.canvas],
      ),
      border: Border(
        bottom: BorderSide(color: SanctuaryNavigationColors.border),
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: SanctuaryNavigationColors.gold.withValues(alpha: .5),
            ),
          ),
          child: const Emblem(size: 36),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: AppText(
            AppBrand.name,
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: .4,
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton.filledTonal(
          key: const ValueKey('close-navigation'),
          tooltip: tr(context, 'Close navigation'),
          style: IconButton.styleFrom(
            minimumSize: const Size(44, 44),
            backgroundColor: SanctuaryNavigationColors.container,
            foregroundColor: AppColors.emerald,
            side: const BorderSide(color: SanctuaryNavigationColors.border),
          ),
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: 18),
        ),
      ],
    ),
  );
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
    this.selected = false,
    this.badge,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary, selected;
  final Widget? badge;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Semantics(
      selected: selected,
      child: Container(
        decoration: primary
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald.withValues(alpha: .16),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
            : null,
        child: Material(
          color: primary
              ? AppColors.emerald
              : selected
              ? SanctuaryNavigationColors.container
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(primary ? 16 : 12),
            side: BorderSide(
              color: selected && !primary
                  ? SanctuaryNavigationColors.border
                  : Colors.transparent,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: primary ? 12 : 8,
              vertical: primary ? 10 : 0,
            ),
            minTileHeight: 52,
            minLeadingWidth: primary ? 40 : 32,
            horizontalTitleGap: 12,
            leading: Container(
              width: primary ? 40 : 32,
              height: primary ? 40 : 32,
              decoration: BoxDecoration(
                color: primary
                    ? AppColors.white.withValues(alpha: .08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: primary
                    ? SanctuaryNavigationColors.goldLight
                    : AppColors.emerald,
              ),
            ),
            title: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppText(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: primary ? AppColors.ivory : AppColors.primary,
                  ),
                ),
                if (primary) const _NavigationBadge('Free Pass', gold: true),
                ?badge,
              ],
            ),
            trailing: Container(
              width: primary ? 28 : 18,
              height: primary ? 28 : 18,
              decoration: primary
                  ? BoxDecoration(
                      color: AppColors.white.withValues(alpha: .1),
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Icon(
                Icons.chevron_right,
                size: 18,
                color: primary ? AppColors.ivory : AppColors.muted,
              ),
            ),
            onTap: onTap,
          ),
        ),
      ),
    ),
  );
}

class _NavigationBadge extends StatelessWidget {
  const _NavigationBadge(this.label, {this.gold = false, this.dark = false});
  final String label;
  final bool gold, dark;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: gold
          ? SanctuaryNavigationColors.gold.withValues(alpha: .16)
          : dark
          ? AppColors.emerald
          : SanctuaryNavigationColors.container,
      borderRadius: BorderRadius.circular(20),
      border: gold
          ? Border.all(
              color: SanctuaryNavigationColors.gold.withValues(alpha: .35),
            )
          : null,
    ),
    child: AppText(
      label,
      style: TextStyle(
        fontSize: 10,
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: gold
            ? SanctuaryNavigationColors.goldLight
            : dark
            ? AppColors.ivory
            : AppColors.emerald,
      ),
    ),
  );
}

class _NavigationDivider extends StatelessWidget {
  const _NavigationDivider();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 10),
    child: Divider(height: 1, color: SanctuaryNavigationColors.border),
  );
}

class _NavigationFooter extends ConsumerWidget {
  const _NavigationFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = AppLanguage.of(context);
    final day = VisitClock.today();
    final config = ref.watch(configurationProvider);
    final availability = ref.watch(availabilityProvider(day));
    final c = config.asData?.value;
    final a = availability.asData?.value;
    final hours = config.hasError || availability.hasError
        ? 'Visiting hours unavailable'
        : c == null || a == null
        ? 'Checking visiting hours…'
        : a.closed
        ? 'No visits today'
        : c.hoursForDate(day);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: SanctuaryNavigationColors.container,
        border: Border(
          top: BorderSide(color: SanctuaryNavigationColors.border),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: tr(context, 'Choose language'),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SanctuaryNavigationColors.border),
              ),
              child: Row(
                children: [
                  for (final entry in const [('en', 'EN'), ('ml', 'MA')])
                    Expanded(
                      child: Semantics(
                        selected: language == entry.$1,
                        child: TextButton(
                          key: ValueKey('navigation-language-${entry.$1}'),
                          onPressed: () =>
                              AppLanguage.select(context, entry.$1),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(44, 44),
                            backgroundColor: language == entry.$1
                                ? AppColors.emerald
                                : Colors.transparent,
                            foregroundColor: language == entry.$1
                                ? AppColors.ivory
                                : AppColors.emerald,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            entry.$2,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              const _FooterDetail(Icons.location_on, 'Chavakkad, Kerala'),
              _FooterDetail(Icons.schedule, hours),
            ],
          ),
          const SizedBox(height: 10),
          const AppText(
            'Free public access',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: AppColors.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _FooterDetail extends StatelessWidget {
  const _FooterDetail(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: AppColors.emerald),
      const SizedBox(width: 5),
      Flexible(
        child: AppText(
          text,
          style: const TextStyle(
            fontSize: 11,
            height: 1.5,
            color: AppColors.secondary,
          ),
        ),
      ),
    ],
  );
}
