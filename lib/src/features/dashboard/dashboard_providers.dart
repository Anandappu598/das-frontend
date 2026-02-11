import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:project_pm/src/features/dashboard/dashboard_repository.dart';
import 'package:project_pm/src/features/dashboard/dashboard_service.dart';
import '../../core/database/database.dart';
import '../../core/database/database_provider.dart';
import '../../core/models/project_with_tasks.dart';

part 'dashboard_providers.g.dart';

@riverpod
DashboardRepository dashboardRepository(DashboardRepositoryRef ref) {
  final db = ref.watch(databaseProvider);
  return DashboardRepository(db);
}

@riverpod
Future<List<ProjectWithTasks>> dashboardProjects(
    DashboardProjectsRef ref) async {
  if (kIsWeb) {
    // Return mock projects for web
    return [
      ProjectWithTasks(
        project: const Project(
          id: 'p1',
          name: 'Web Demo Project',
          context: 'This is a demo project for the web version.',
          status: 'active',
          approvalStatus: null,
        ),
        tasks: [
          TaskWithAssignees(
            task: Task(
              id: 't1',
              name: 'Demo Task',
              projectId: 'p1',
              progress: 50,
              priority: 'High',
              startDate: DateTime.now(),
              endDate: DateTime.now().add(const Duration(days: 2)),
              assigneesJson: '[]',
              milestonesJson: '[]',
              approvalStatus: null,
              githubLink: null,
              figmaLink: null,
            ),
            assignees: [], // Single user (implicit "My Project")
          ),
        ],
      ),
      ProjectWithTasks(
        project: const Project(
          id: 'p2',
          name: 'E-Commerce Revamp',
          context: 'Overhauling the main store frontend.',
          status: 'active',
          approvalStatus: null,
        ),
        tasks: [
          TaskWithAssignees(
            task: Task(
              id: 't2',
              name: 'Design System',
              projectId: 'p2',
              progress: 80,
              priority: 'Critical',
              startDate: DateTime.now().subtract(const Duration(days: 5)),
              endDate: DateTime.now().add(const Duration(days: 10)),
              assigneesJson: '[]',
              milestonesJson: '[]',
              approvalStatus: null,
              githubLink: null,
              figmaLink: null,
            ),
            assignees: [
              // Multiple assignees make this a "Team Project"
              const User(
                id: 'u1',
                name: 'Alice',
                email: 'alice@example.com',
                role: 'admin',
                avatarUrl: '', // Empty to use initials and avoid network error
                reportingManagerId: null,
                department: null,
              ),
              const User(
                id: 'u2',
                name: 'Bob',
                email: 'bob@example.com',
                role: 'user',
                avatarUrl: '', // Empty to use initials and avoid network error
                reportingManagerId: null,
                department: null,
              ),
            ],
          ),
        ],
      ),
      ProjectWithTasks(
        project: const Project(
          id: 'p3',
          name: 'Mobile App Launch',
          context: 'Preparing for iOS and Android release.',
          status: 'completed',
          approvalStatus: null,
        ),
        tasks: [
          TaskWithAssignees(
            task: Task(
              id: 't3',
              name: 'Beta Testing',
              projectId: 'p3',
              progress: 100,
              priority: 'Medium',
              startDate: DateTime.now().subtract(const Duration(days: 20)),
              endDate: DateTime.now().subtract(const Duration(days: 2)),
              assigneesJson: '[]',
              milestonesJson: '[]',
              approvalStatus: null,
              githubLink: null,
              figmaLink: null,
            ),
            assignees: [
              const User(
                id: 'u2',
                name: 'Bob',
                email: 'bob@example.com',
                role: 'user',
                avatarUrl: '',
                reportingManagerId: null,
                department: null,
              ),
              const User(
                id: 'u3',
                name: 'Charlie',
                email: 'charlie@example.com',
                role: 'user',
                avatarUrl: '',
                reportingManagerId: null,
                department: null,
              ),
            ],
          ),
        ],
      ),
    ];
  }
  return ref.watch(dashboardRepositoryProvider).fetchProjectsWithTasks();
}

@riverpod
DashboardService dashboardService(DashboardServiceRef ref) {
  return DashboardService();
}

@riverpod
Future<DashboardMetrics> dashboardMetrics(DashboardMetricsRef ref) async {
  try {
    final projects = await ref.watch(dashboardProjectsProvider.future);
    final service = ref.watch(dashboardServiceProvider);
    final repo = ref.watch(dashboardRepositoryProvider);

    // Fetch team stats with error handling
    TeamActivityStats? teamStats;
    try {
      teamStats = await repo.fetchTeamActivityStats();
    } catch (e) {
      // If team stats fail, continue with null
      teamStats = null;
    }

    // Fetch recent activities with error handling
    List<RecentActivity> recentActivities = [];
    try {
      recentActivities = await repo.fetchRecentActivities();
    } catch (e) {
      // If recent activities fail, continue with empty list
      recentActivities = [];
    }

    return DashboardMetrics(
      risks: service.analyzeRisks(projects),
      focusItems: service.identifyFocusItems(projects),
      insights: service.generateAiInsights(projects),
      totalProjects: projects.length,
      teamStats: teamStats,
      recentActivities: recentActivities,
    );
  } catch (e) {
    // If everything fails, return empty metrics
    return DashboardMetrics(
      risks: [],
      focusItems: [],
      insights: [],
      totalProjects: 0,
      teamStats: null,
      recentActivities: [],
    );
  }
}

class DashboardMetrics {
  final List<Risk> risks;
  final List<FocusItem> focusItems;
  final List<Insight> insights;
  final int totalProjects;
  final TeamActivityStats? teamStats;
  final List<RecentActivity> recentActivities;

  DashboardMetrics({
    required this.risks,
    required this.focusItems,
    required this.insights,
    required this.totalProjects,
    this.teamStats,
    this.recentActivities = const [],
  });
}
