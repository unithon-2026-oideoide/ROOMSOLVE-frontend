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
import 'services/report_service.dart';
import 'services/technician_job_loader.dart';
import 'widgets/extra_or_fetch.dart';

String _homePathFor(UserRole role) => homePathForRole(role);

/// `state.extra`가 넘겨받은 타입과 맞을 때만 값을 꺼내고, 아니면(웹 새로고침 등
/// extra가 유실된 경우) null을 돌려준다. `as T`로 강제 캐스팅하면 여기서 바로
/// 예외가 나서 화면 자체가 뜨지 못한다.
T? _extraAs<T>(Object? extra) => extra is T ? extra : null;

/// 배정 작업 목록(technicianId 기준)에서 id가 일치하는 하나를 찾는다.
/// JobDetailScreen/RepairCompleteScreen이 extra 없이 새로고침됐을 때 쓴다.
Future<TechnicianJob?> _findTechnicianJob(AuthProvider authProvider, String id) async {
  final technicianId = authProvider.currentUser?.id;
  if (technicianId == null || technicianId.isEmpty) return null;
  final jobs = await loadTechnicianJobs(technicianId);
  for (final job in jobs) {
    if (job.id == id) return job;
  }
  return null;
}

/// 새 일감 목록(technicianId 기준)에서 id가 일치하는 하나를 찾는다.
/// GET /api/vendors/requests에 단건 조회 API가 없어 목록에서 찾는 방식이다.
Future<VendorRequest?> _findVendorRequest(AuthProvider authProvider, String id) async {
  final technicianId = authProvider.currentUser?.id;
  if (technicianId == null || technicianId.isEmpty) return null;
  final requests = await ReportService.instance.getVendorRequests(technicianId: technicianId);
  for (final request in requests) {
    if (request.id == id) return request;
  }
  return null;
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
      GoRoute(
        path: '/tenant',
        pageBuilder: (context, state) => const NoTransitionPage(child: TenantHomeScreen()),
      ),
      GoRoute(path: '/tenant/reports', builder: (context, state) => const ReportListScreen()),
      GoRoute(path: '/tenant/reports/new', builder: (context, state) => const ReportCreateScreen()),
      GoRoute(
        path: '/tenant/reports/new/details',
        // 2단계 입력값(description/photos)은 1단계에서만 만들어지는 임시
        // 상태라 URL만으로는 재구성할 수 없다 — extra가 없으면(새로고침 등)
        // 1단계로 돌려보낸다.
        builder: (context, state) {
          final extra = _extraAs<Map<String, dynamic>>(state.extra);
          final photos = extra?['photos'];
          if (extra == null || extra['description'] is! String || photos is! List) {
            return const ReportCreateScreen();
          }
          return ReportAdditionalInfoScreen(
            description: extra['description'] as String,
            photos: photos.cast<File>(),
          );
        },
      ),
      GoRoute(
        path: '/tenant/reports/result',
        // 이 경로는 :id가 없어 새로고침 시 서버에서 다시 불러올 방법이 없다
        // (분석 직후 응답 그대로를 보여주는 화면이라서다). extra가 없으면
        // 신고 목록으로 보낸다.
        builder: (context, state) {
          final report = _extraAs<Report>(state.extra);
          if (report == null) return const ReportListScreen();
          return ReportResultScreen(report: report);
        },
      ),
      GoRoute(
        path: '/tenant/reports/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ExtraOrFetch<Report>(
            initial: _extraAs<Report>(state.extra),
            loader: () => ReportService.instance.getReport(id),
            notFoundMessage: '신고 내역을 찾을 수 없습니다.',
            fallbackRoute: '/tenant/reports',
            builder: (context, report) => ReportDetailScreen(report: report),
          );
        },
      ),
      GoRoute(
        path: '/tenant/reports/:id/visit-schedule',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ExtraOrFetch<Report>(
            initial: _extraAs<Report>(state.extra),
            loader: () => ReportService.instance.getReport(id),
            notFoundMessage: '신고 내역을 찾을 수 없습니다.',
            fallbackRoute: '/tenant/reports',
            builder: (context, report) => ReportVisitScheduleScreen(report: report),
          );
        },
      ),
      GoRoute(
        path: '/tenant/reports/:id/progress',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ExtraOrFetch<Report>(
            initial: _extraAs<Report>(state.extra),
            loader: () => ReportService.instance.getReport(id),
            notFoundMessage: '신고 내역을 찾을 수 없습니다.',
            fallbackRoute: '/tenant/reports',
            builder: (context, report) => ReportProgressScreen(report: report),
          );
        },
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
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ExtraOrFetch<TechnicianJob>(
            initial: _extraAs<TechnicianJob>(state.extra),
            loader: () => _findTechnicianJob(authProvider, id),
            notFoundMessage: '배정된 작업을 찾을 수 없습니다.',
            fallbackRoute: '/technician/jobs',
            builder: (context, job) => JobDetailScreen(job: job),
          );
        },
      ),
      GoRoute(
        path: '/technician/jobs/:id/complete',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ExtraOrFetch<TechnicianJob>(
            initial: _extraAs<TechnicianJob>(state.extra),
            loader: () => _findTechnicianJob(authProvider, id),
            notFoundMessage: '배정된 작업을 찾을 수 없습니다.',
            fallbackRoute: '/technician/jobs',
            builder: (context, job) => RepairCompleteScreen(job: job),
          );
        },
      ),
      GoRoute(path: '/technician/requests', builder: (context, state) => const NewRequestListScreen()),
      GoRoute(
        path: '/technician/requests/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ExtraOrFetch<VendorRequest>(
            initial: _extraAs<VendorRequest>(state.extra),
            loader: () => _findVendorRequest(authProvider, id),
            notFoundMessage: '새 일감을 찾을 수 없습니다.',
            fallbackRoute: '/technician/requests',
            builder: (context, request) => NewRequestDetailScreen(request: request),
          );
        },
      ),

      // 공용 설정
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/settings/account', builder: (context, state) => const AccountInfoScreen()),
      GoRoute(path: '/settings/notifications', builder: (context, state) => const NotificationSettingsScreen()),
      GoRoute(path: '/settings/landlord-link', builder: (context, state) => const LandlordLinkScreen()),
    ],
  );
}
