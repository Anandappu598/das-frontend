import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:project_pm/src/features/admin/admin_user_management_page.dart';
import 'package:project_pm/src/features/approvals/approvals_page.dart';
import 'package:project_pm/src/features/team/team_overview_page.dart';
import 'package:project_pm/src/features/today/today_page.dart';
import 'package:project_pm/src/features/startup/startup_page.dart';
import 'package:project_pm/src/features/dashboard/dashboard_page.dart';
import 'package:project_pm/src/features/shell/shell_page.dart';
import 'package:project_pm/src/features/reports/reports_page.dart';
import 'package:project_pm/src/features/settings/settings_page.dart';
import 'package:project_pm/src/features/shell/placeholder_views.dart';
import 'package:project_pm/src/features/projects/views/project_plan_page.dart';
import 'package:project_pm/src/features/projects/views/project_gantt_page.dart';
import 'package:project_pm/src/features/projects/views/project_grid_page.dart';
import 'package:project_pm/src/features/projects/views/project_context_page.dart';
import 'package:project_pm/src/features/projects/views/project_reports_page.dart';
import 'package:project_pm/src/features/projects/views/project_settings_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends _$AppRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(path: '/', page: StartupRoute.page, initial: true),
        AutoRoute(path: '/app', page: ShellRoute.page, children: [
          AutoRoute(
              path: 'dashboard', page: DashboardRoute.page, initial: true),
          AutoRoute(path: 'today', page: TodayRoute.page),
          AutoRoute(path: 'projects', page: ProjectsPlaceholderRoute.page),
          AutoRoute(path: 'projects/plan', page: ProjectPlanRoute.page),
          AutoRoute(path: 'projects/gantt', page: ProjectGanttRoute.page),
          AutoRoute(path: 'projects/grid', page: ProjectGridRoute.page),
          AutoRoute(path: 'projects/context', page: ProjectContextRoute.page),
          AutoRoute(path: 'projects/reports', page: ProjectReportsRoute.page),
          AutoRoute(path: 'projects/settings', page: ProjectSettingsRoute.page),
          AutoRoute(path: 'reports', page: ReportsRoute.page),
          AutoRoute(path: 'settings', page: SettingsRoute.page),
          AutoRoute(path: 'admin', page: AdminUserManagementRoute.page),
          AutoRoute(path: 'approvals', page: ApprovalsRoute.page),
          AutoRoute(path: 'team', page: TeamOverviewRoute.page),
        ]),
      ];
}
