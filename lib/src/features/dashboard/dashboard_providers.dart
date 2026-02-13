import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project_pm/src/features/dashboard/dashboard_repository.dart';
import 'package:project_pm/src/features/dashboard/dashboard_service.dart';
import '../../core/database/database_provider.dart';
import '../../core/models/project_with_tasks.dart';
import '../projects/providers/api_providers.dart';

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
    // Fetch real data from API for web
    try {
      final apiProjects = await ref.watch(apiProjectsProvider.future);
      final apiTasks = await ref.watch(apiTasksProvider.future);

      // Group tasks by project
      final projectsWithTasks = <ProjectWithTasks>[];

      for (final apiProject in apiProjects) {
        // Convert API project to local Project model
        final project = apiProject.toLocalProject();

        // Find all tasks for this project
        final projectTasks = apiTasks
            .where((task) => task.project == apiProject.id)
            .map((apiTask) {
          final localTask = apiTask.toLocalTask(project.id);
          return TaskWithAssignees(
            task: localTask,
            assignees: [], // Empty assignees for now
          );
        }).toList();

        projectsWithTasks.add(ProjectWithTasks(
          project: project,
          tasks: projectTasks,
        ));
      }

      return projectsWithTasks;
    } catch (e) {
      print('Error fetching projects from API: $e');
      // Return empty list on error
      return [];
    }
  }
  return ref.watch(dashboardRepositoryProvider).fetchProjectsWithTasks();
}

/// Selected user ID for project work statistics
final selectedStatsUserIdProvider = StateProvider<int?>((ref) => null);

/// Provider for fetching users list for stats dropdown
@riverpod
Future<List<dynamic>> usersForStats(UsersForStatsRef ref) async {
  final apiService = ref.watch(taskApiServiceProvider);
  try {
    return await apiService.getUsersForStats();
  } catch (e) {
    print('Error fetching users for stats: $e');
    return [];
  }
}

/// Provider for fetching project work statistics
@riverpod
Future<Map<String, dynamic>> projectWorkStats(ProjectWorkStatsRef ref) async {
  final selectedUserId = ref.watch(selectedStatsUserIdProvider);
  if (selectedUserId == null) {
    return {'projects': [], 'user': null};
  }

  final apiService = ref.watch(taskApiServiceProvider);
  try {
    return await apiService.getProjectWorkStats(userId: selectedUserId);
  } catch (e) {
    print('Error fetching project work stats: $e');
    return {'projects': [], 'user': null};
  }
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
