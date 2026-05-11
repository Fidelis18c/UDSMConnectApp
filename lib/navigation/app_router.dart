import 'package:go_router/go_router.dart';
import 'route_names.dart';

import '../core/models/post.dart';
import '../core/models/event.dart';

import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/verification_screen.dart';
import '../features/auth/presentation/screens/new_password_screen.dart';
import '../features/for_you/presentation/screens/preferences_screen.dart';

import '../features/profile/presentation/screens/profile_screen.dart';

import '../features/for_you/presentation/screens/for_you_screen.dart';

import 'main_shell.dart';
import '../features/announcements/news_feed/news_feed_screen.dart';
import '../features/announcements/post_detail/post_detail_screen.dart';
import 'package:udsm_connect/features/compose/presentation/screens/create_story_screen.dart';
import '../features/compose/presentation/screens/compose_announcement_screen.dart';
import '../features/feedback/presentation/screens/feedback_screen.dart';
import '../features/events/presentation/screens/events_screen.dart';
import '../features/events/presentation/screens/event_detail_screen.dart';
import '../features/compose/presentation/screens/create_event_screen.dart';

import '../features/lost_and_found/presentation/screens/lost_found_screen.dart';
import '../features/compose/presentation/screens/create_lost_found_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // --- Splash & Auth ---
    GoRoute(
      path: '/',
      name: RouteNames.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: RouteNames.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: RouteNames.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/preferences',
      name: RouteNames.preferences,
      builder: (context, state) => const PreferencesScreen(),
    ),

    // --- Password Reset Flow ---
    GoRoute(
      path: '/forgot-password',
      name: RouteNames.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/verify-otp',
      name: RouteNames.verifyOtp,
      builder: (context, state) => const VerificationScreen(),
    ),
    GoRoute(
      path: '/new-password',
      name: RouteNames.newPassword,
      builder: (context, state) => const NewPasswordScreen(),
    ),

    GoRoute(
      path: '/create-story',
      name: RouteNames.createStory,
      builder: (context, state) => const CreateStoryScreen(),
    ),
    // --- Standalone Flows ---
    GoRoute(
      path: '/profile',
      name: RouteNames.profile,
      builder: (context, state) => const ProfileScreen(),
    ),

    // --- Main Shell (Bottom Nav) ---
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        // Announcements Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/announcements',
              name: RouteNames.announcements,
              builder: (context, state) => const NewsFeedScreen(),
              routes: [
                GoRoute(
                  path: 'create',
                  name: RouteNames.composeAnnouncement,
                  builder: (context, state) => const ComposeAnnouncementScreen(),
                ),
                GoRoute(
                  path: ':id',
                  name: RouteNames.postDetail,
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    final extra = state.extra;
                    return PostDetailScreen(
                      announcementId: id,
                      prefetchPost: extra is Post ? extra : null,
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        // Feedback Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/feedback',
              name: RouteNames.feedback,
              builder: (context, state) => const FeedbackScreen(),
            ),
          ],
        ),

        // For You Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/for-you',
              name: RouteNames.forYou,
              builder: (context, state) => const ForYouScreen(),
            ),
          ],
        ),

        // Events Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/events',
              name: RouteNames.events,
              builder: (context, state) => const EventsScreen(),
              routes: [
                GoRoute(
                  path: 'create',
                  name: RouteNames.createEvent,
                  builder: (context, state) => const CreateEventScreen(),
                ),
                GoRoute(
                  path: ':id',
                  name: RouteNames.eventDetail,
                  builder: (context, state) {
                    final event = state.extra as Event;
                    return EventDetailScreen(event: event);
                  },
                ),
              ],
            ),
          ],
        ),

        // Lost & Found Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/lost-and-found',
              name: RouteNames.lostFound,
              builder: (context, state) => const LostFoundScreen(),
              routes: [
                GoRoute(
                  path: 'create',
                  name: RouteNames.createLostFound,
                  builder: (context, state) => const CreateLostFoundScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
