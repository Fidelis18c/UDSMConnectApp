import 'package:flutter/material.dart';
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
import 'package:udsm_connect/core/utils/story_grouping.dart';
import 'package:udsm_connect/features/stories/presentation/screens/story_viewer_screen.dart';
import '../features/compose/presentation/screens/compose_announcement_screen.dart';
import '../features/feedback/presentation/screens/feedback_screen.dart';
import '../features/events/presentation/screens/events_screen.dart';
import '../features/events/presentation/screens/event_detail_screen.dart';
import '../features/compose/presentation/screens/create_event_screen.dart';

import '../features/lost_and_found/data/models/lost_found.dart';

import '../features/lost_and_found/presentation/screens/lost_found_screen.dart';
import '../features/lost_and_found/presentation/screens/lost_found_detail_screen.dart';
import '../features/compose/presentation/screens/create_lost_found_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/comments/presentation/screens/comments_screen.dart';
import '../features/comments/presentation/screens/reply_screen.dart';
import '../features/comments/data/models/comment.dart';

/// Root navigator — post detail and other full-screen routes use this so they
/// can be opened from outside the bottom-nav shell (e.g. notifications).
final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
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
    GoRoute(
      path: '/story-viewer',
      name: RouteNames.storyViewer,
      builder: (context, state) {
        final args = state.extra as StoryViewerArgs;
        return StoryViewerScreen(args: args);
      },
    ),
    // --- Standalone Flows ---
    GoRoute(
      path: '/profile',
      name: RouteNames.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/notifications',
      name: RouteNames.notifications,
      builder: (context, state) => const NotificationsScreen(),
    ),

    // Public share / App Link: https://www.udsminfo.com/posts/:id
    GoRoute(
      path: '/posts/:id',
      name: RouteNames.postShare,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return PostDetailScreen(announcementId: id);
      },
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
                  builder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>?;
                    return ComposeAnnouncementScreen(
                      title: extra?['title'] as String?,
                      bodyHint: extra?['bodyHint'] as String?,
                      postType: extra?['postType'] as String?,
                    );
                  },
                ),
                GoRoute(
                  path: ':id',
                  name: RouteNames.postDetail,
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    final extra = state.extra;
                    return PostDetailScreen(
                      announcementId: id,
                      prefetchPost: extra is Post ? extra : null,
                    );
                  },
                  routes: [
                    GoRoute(
                      path: 'comments',
                      name: RouteNames.postComments,
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        final id = state.pathParameters['id']!;
                        return CommentsScreen(targetId: id);
                      },
                      routes: [
                        GoRoute(
                          path: 'reply',
                          name: RouteNames.commentReply,
                          parentNavigatorKey: rootNavigatorKey,
                          builder: (context, state) {
                            final id = state.pathParameters['id']!;
                            final comment = state.extra as Comment;
                            return ReplyScreen(targetId: id, comment: comment);
                          },
                        ),
                      ],
                    ),
                  ],
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
                  parentNavigatorKey: rootNavigatorKey,
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
                  builder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>?;
                    return CreateLostFoundScreen(
                      initialType: extra?['type'] as String? ?? 'LOST',
                    );
                  },
                ),
                GoRoute(
                  path: ':id',
                  name: RouteNames.lostFoundDetail,
                  builder: (context, state) {
                    final item = state.extra as LostFoundItem;
                    return LostFoundDetailScreen(item: item);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
