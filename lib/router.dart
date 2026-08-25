import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/report.dart';
import 'models/user.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/landlord/auto_approval_setting_screen.dart';
import 'screens/landlord/landlord_dashboard_screen.dart';
import 'screens/landlord/request_detail_screen.dart';
import 'screens/technician/technician_job_list_screen.dart';
import 'screens/tenant/report_create_screen.dart';
import 'screens/tenant/report_list_screen.dart';
import 'screens/tenant/report_result_screen.dart';
import 'screens/tenant/tenant_home_screen.dart';

/// role에 따라 진입할 홈 경로를 결정한다.
String _homePathFor(UserRole role) {
  switch (role) {
    case UserRole.landlord:
      return '/landlord';
    case UserRole.technician:
      return '/technician';
    case UserRole.tenant:
    case UserRole.unknown:
      return '/tenant';
  }
}

GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (context, state) {
      if (!authProvider.isInitialized) return null;

      final loggedIn = authProvider.isLoggedIn;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      if (!loggedIn && !isAuthRoute) return '/login';
      if (loggedIn && isAuthRoute) return _homePathFor(authProvider.role);
      if (loggedIn && state.matchedLocation == '/') return _homePathFor(authProvider.role);

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(path: '/', builder: (context, state) => const SizedBox.shrink()),

      // 세입자
      GoRoute(path: '/tenant', builder: (context, state) => const TenantHomeScreen()),
      GoRoute(path: '/tenant/reports', builder: (context, state) => const ReportListScreen()),
      GoRoute(path: '/tenant/reports/new', builder: (context, state) => const ReportCreateScreen()),
      GoRoute(
        path: '/tenant/reports/result',
        builder: (context, state) => ReportResultScreen(report: state.extra as Report),
      ),

      // 임대인
      GoRoute(path: '/landlord', builder: (context, state) => const LandlordDashboardScreen()),
      GoRoute(
        path: '/landlord/requests/:id',
        builder: (context, state) => RequestDetailScreen(requestId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/landlord/auto-approval', builder: (context, state) => const AutoApprovalSettingScreen()),

      // 수리기사
      GoRoute(path: '/technician', builder: (context, state) => const TechnicianJobListScreen()),
    ],
  );
}
