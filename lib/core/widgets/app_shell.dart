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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(wide ? 96 : 76),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.ivory,
            border: Border(bottom: BorderSide(color: AppColors.outline)),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1344),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 32 : 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => context.go('/'),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Emblem(size: wide ? 52 : 42),
                              const SizedBox(width: 10),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Keekot Thangal',
                                    style: TextStyle(
                                      fontFamily: 'Newsreader',
                                      fontWeight: FontWeight.w600,
                                      fontSize: wide ? 26 : 22,
                                      color: AppColors.emerald,
                                    ),
                                  ),
                                  const Text(
                                    'Chavakkad, Kerala',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (wide) ...[
                        for (var i = 0; i < routes.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: TextButton(
                              onPressed: () => context.go(routes[i]),
                              style: TextButton.styleFrom(
                                backgroundColor: selected == i
                                    ? AppColors.mint
                                    : null,
                              ),
                              child: Text(labels[i]),
                            ),
                          ),
                        const SizedBox(width: 8),
                      ],
                      IconButton(
                        tooltip: 'Notifications',
                        onPressed: () => context.go('/notifications'),
                        icon: const Icon(Icons.notifications_none),
                      ),
                      PopupMenuButton<String>(
                        tooltip: user == null ? 'Sign in' : 'Account',
                        icon: const Icon(Icons.account_circle_outlined),
                        onSelected: (value) async {
                          if (value == 'signout') {
                            try {
                              await ref
                                  .read(notificationRepositoryProvider)
                                  .disable();
                              await ref.read(authRepositoryProvider).signOut();
                              ref.read(draftProvider.notifier).clear();
                              if (context.mounted) context.go('/');
                            } catch (e) {
                              if (context.mounted)
                                showMessage(context, failureMessage(e));
                            }
                          } else {
                            context.go(value);
                          }
                        },
                        itemBuilder: (_) => [
                          if (user == null)
                            const PopupMenuItem(
                              value: '/auth',
                              child: Text('Sign in with mobile'),
                            ),
                          if (user != null)
                            PopupMenuItem(
                              enabled: false,
                              child: Text(user.maskedPhone),
                            ),
                          if (user?.admin == true)
                            const PopupMenuItem(
                              value: '/admin',
                              child: Text('Administration'),
                            ),
                          if (user?.gate == true && user?.admin != true)
                            const PopupMenuItem(
                              value: '/admin/gate',
                              child: Text('Validate visitor pass'),
                            ),
                          if (user != null)
                            const PopupMenuItem(
                              value: 'signout',
                              child: Text('Sign out'),
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
              selectedIndex: selected,
              onDestinationSelected: (i) => context.go(routes[i]),
              destinations: [
                for (var i = 0; i < routes.length; i++)
                  NavigationDestination(
                    icon: Icon(icons[i]),
                    label: ['Home', 'Book', 'Bookings', 'Info'][i],
                  ),
              ],
            ),
    );
  }
}
