import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/role_routes.dart';
import 'models/report.dart';
import 'models/technician_job.dart';
import 'models/user.dart';
import 'models/vendor_request.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/landlord/auto_approval_setting_screen.dart';
import 'screens/landlord/landlord_dashboard_screen.dart';
import 'screens/landlord/landlord_requests_screen.dart';
import 'screens/landlord/landlord_units_screen.dart';
import 'screens/landlord/landlord_visit_schedule_screen.dart';
import 'screens/landlord/request_detail_screen.dart';
import 'screens/landlord/request_rejected_screen.dart';
import 'screens/settings/account_info_screen.dart';
import 'screens/settings/landlord_link_screen.dart';
import 'screens/settings/notification_settings_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/technician/job_detail_screen.dart';
import 'screens/technician/new_request_detail_screen.dart';
import 'screens/technician/new_request_list_screen.dart';
import 'screens/technician/repair_complete_screen.dart';
import 'screens/technician/technician_home_screen.dart';
import 'screens/technician/technician_job_list_screen.dart';
import 'screens/tenant/report_additional_info_screen.dart';
import 'screens/tenant/report_create_screen.dart';
import 'screens/tenant/report_detail_screen.dart';
import 'screens/tenant/report_list_screen.dart';
import 'screens/tenant/report_progress_screen.dart';
import 'screens/tenant/report_result_screen.dart';
import 'screens/tenant/report_visit_schedule_screen.dart';
import 'screens/tenant/tenant_home_screen.dart';

String _homePathFor(UserRole role) => homePathForRole(role);

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
      GoRoute(
        path: '/tenant',
        pageBuilder: (context, state) => const NoTransitionPage(child: TenantHomeScreen()),
      ),
      GoRoute(path: '/tenant/reports', builder: (context, state) => const ReportListScreen()),
      GoRoute(path: '/tenant/reports/new', builder: (context, state) => const ReportCreateScreen()),
      GoRoute(
        path: '/tenant/reports/new/details',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ReportAdditionalInfoScreen(
            description: extra['description'] as String,
            photos: (extra['photos'] as List).cast<File>(),
          );
        },
      ),
      GoRoute(
        path: '/tenant/reports/result',
        builder: (context, state) => ReportResultScreen(report: state.extra as Report),
      ),
      GoRoute(
        path: '/tenant/reports/:id',
        builder: (context, state) => ReportDetailScreen(report: state.extra as Report),
      ),
      GoRoute(
        path: '/tenant/reports/:id/visit-schedule',
        builder: (context, state) => ReportVisitScheduleScreen(report: state.extra as Report),
      ),
      GoRoute(
        path: '/tenant/reports/:id/progress',
        builder: (context, state) => ReportProgressScreen(report: state.extra as Report),
      ),

      // 임대인
      GoRoute(
        path: '/landlord',
        pageBuilder: (context, state) => const NoTransitionPage(child: LandlordDashboardScreen()),
      ),
      GoRoute(path: '/landlord/requests', builder: (context, state) => const LandlordRequestsScreen()),
      GoRoute(
        path: '/landlord/requests/:id',
        builder: (context, state) => RequestDetailScreen(requestId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/landlord/requests/:id/rejected',
        builder: (context, state) => RequestRejectedScreen(reason: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: '/landlord/requests/:id/visit-schedule',
        builder: (context, state) => LandlordVisitScheduleScreen(requestId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/landlord/auto-approval', builder: (context, state) => const AutoApprovalSettingScreen()),
      GoRoute(path: '/landlord/units', builder: (context, state) => const LandlordUnitsScreen()),

      // 수리기사
      GoRoute(
        path: '/technician',
        pageBuilder: (context, state) => const NoTransitionPage(child: TechnicianHomeScreen()),
      ),
      GoRoute(path: '/technician/jobs', builder: (context, state) => const TechnicianJobListScreen()),
      GoRoute(
        path: '/technician/jobs/:id',
        builder: (context, state) => JobDetailScreen(job: state.extra as TechnicianJob),
      ),
      GoRoute(
        path: '/technician/jobs/:id/complete',
        builder: (context, state) => RepairCompleteScreen(job: state.extra as TechnicianJob),
      ),
      GoRoute(path: '/technician/requests', builder: (context, state) => const NewRequestListScreen()),
      GoRoute(
        path: '/technician/requests/:id',
        builder: (context, state) => NewRequestDetailScreen(request: state.extra as VendorRequest),
      ),

      // 공용 설정
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/settings/account', builder: (context, state) => const AccountInfoScreen()),
      GoRoute(path: '/settings/notifications', builder: (context, state) => const NotificationSettingsScreen()),
      GoRoute(path: '/settings/landlord-link', builder: (context, state) => const LandlordLinkScreen()),
    ],
  );
}
