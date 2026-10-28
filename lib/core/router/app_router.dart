import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/calendar_screen.dart';
import '../../features/connect/connect_screen.dart';
import '../../features/inbox/inbox_screen.dart';
import '../../features/inbox/pending_screen.dart';
import '../../features/link/link_screen.dart';
import '../../features/lists/list_detail_screen.dart';
import '../../features/lists/lists_screen.dart';
import '../../features/more/help_screen.dart';
import '../../features/more/more_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/today/today_screen.dart';
import '../../features/welcome/welcome_screen.dart';
import '../auth/session.dart';
import '../models/models.dart';
import '../theme/yaadly_colors.dart';

abstract final class Routes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const link = '/link';
  static const connect = '/connect';
  static const today = '/today';
  static const inbox = '/inbox';
  static const calendar = '/calendar';
  static const lists = '/lists';
  static const more = '/more';
  static const help = '/help';

  static String pending(String id) => '/pending/$id';
  static String list(String id) => '/lists/$id';
}

const _public = {Routes.welcome, Routes.link};

final routerProvider = Provider<GoRouter>((ref) {
  // GoRouter re-runs `redirect` whenever the session changes (sign-in, sign-out, token rejected).
  final session = ValueNotifier<AsyncValue<SessionStatus>>(ref.read(sessionProvider));
  ref.listen(sessionProvider, (_, next) => session.value = next);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: session,
    redirect: (context, state) {
      final s = session.value;
      final loc = state.matchedLocation;
      if (!s.hasValue) return loc == Routes.splash ? null : Routes.splash;

      final signedIn = s.requireValue == SessionStatus.signedIn;
      if (!signedIn) return _public.contains(loc) ? null : Routes.welcome;
      // Just linked on the Link screen: continue onboarding with "Connect calendar".
      if (loc == Routes.link) return Routes.connect;
      if (loc == Routes.splash || loc == Routes.welcome) return Routes.today;
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const ColoredBox(color: YaadlyColors.butter)),
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: Routes.link, builder: (_, _) => const LinkScreen()),
      GoRoute(path: Routes.connect, builder: (_, _) => const ConnectScreen()),
      GoRoute(path: Routes.help, builder: (_, _) => const HelpScreen()),
      GoRoute(path: '/pending/:id', builder: (_, st) => PendingScreen(id: st.pathParameters['id']!, initial: st.extra as PendingItem?)),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.today, builder: (_, _) => const TodayScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.inbox, builder: (_, _) => const InboxScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.calendar, builder: (_, _) => const CalendarScreen())]),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.lists,
                builder: (_, _) => const ListsScreen(),
                routes: [GoRoute(path: ':id', builder: (_, st) => ListDetailScreen(id: st.pathParameters['id']!))],
              ),
            ],
          ),
          StatefulShellBranch(routes: [GoRoute(path: Routes.more, builder: (_, _) => const MoreScreen())]),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    session.dispose();
  });
  return router;
});
