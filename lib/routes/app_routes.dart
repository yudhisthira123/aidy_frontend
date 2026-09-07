import 'package:frontend/features/requests/quick_help_view.dart';
import 'package:frontend/features/requests/requests_view.dart';
import 'package:frontend/features/start/start_view.dart';
import 'package:frontend/features/user_profile/user_profile_view.dart';
import 'package:frontend/features/whats_new/whats_new_view.dart';
import 'package:frontend/main.dart';
import 'package:go_router/go_router.dart';

// GoRouter configuration
final router = GoRouter(
  initialLocation: '/start',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainNavigationView(navigationShell: navigationShell);
      },
      branches: [
        // -------------------------------------------------------------------
        // Tab 1 - Start
        // -------------------------------------------------------------------
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/start',
              builder: (context, state) => const StartView(),
              routes: [
                GoRoute(
                  path: 'quickhelp',
                  builder: (context, state) => const QuickHelpView(),
                ),
              ],
            ),
          ],
        ),

        // -------------------------------------------------------------------
        // Tab 2 - Requests
        // -------------------------------------------------------------------
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/requests',
              builder: (context, state) => const RequestsView(),
            ),
          ],
        ),

        // -------------------------------------------------------------------
        // Tab 3 - Notifications
        // -------------------------------------------------------------------
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/whatsnew',
              builder: (context, state) => const WhatsNewView(),
            ),
          ],
        ),

        // -------------------------------------------------------------------
        // Tab 4 - Profile
        // -------------------------------------------------------------------
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileView(),
            ),
          ],
        ),
      ],
    ),
  ],
);
