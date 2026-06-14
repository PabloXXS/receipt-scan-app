/// Назначение: конфигурация навигации (GoRouter) с redirect и нижним меню.
///
/// Слой: core/router
/// Зависимости: go_router, flutter_riverpod, core/auth, core/navigation,
///   core/supabase, экраны фич auth/receipts/statistics/scan/profile.
/// Ключевые типы: appRouterProvider.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/check_email_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/receipts/presentation/screens/receipt_details_screen.dart';
import '../../features/receipts/presentation/screens/receipts_screen.dart';
import '../../features/scan/presentation/screens/scan_screen.dart';
import '../../features/statistics/presentation/screens/statistics_screen.dart';
import '../auth/auth_providers.dart';
import '../navigation/main_shell.dart';
import '../supabase/supabase_providers.dart';
import 'app_routes.dart';
import 'auth_redirect.dart';

/// Провайдер корневого роутера приложения.
final appRouterProvider = Provider<GoRouter>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final refreshStream = GoRouterRefreshStream(client.auth.onAuthStateChange);
  ref.onDispose(refreshStream.dispose);
  return GoRouter(
    initialLocation: AppRoutes.receipts,
    refreshListenable: refreshStream,
    redirect: (context, state) => authRedirect(
      isAuthenticated: client.auth.currentSession != null,
      location: state.matchedLocation,
    ),
    routes: [
      // Корневой путь — защитный redirect на первую вкладку (для cold deep-links
      // на '/'); основную развилку auth/гость делает глобальный redirect.
      GoRoute(
        path: AppRoutes.home,
        redirect: (context, state) => AppRoutes.receipts,
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkEmail,
        builder: (context, state) => const CheckEmailScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.receipts,
                builder: (context, state) => const ReceiptsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => ReceiptDetailsScreen(
                      id: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.statistics,
                builder: (context, state) => const StatisticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.scan,
                builder: (context, state) => const ScanScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
