import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/database/database.dart';
import '../../core/database/database_provider.dart';
import 'project_repository.dart';
import '../../core/models/project_with_tasks.dart';
import 'providers/api_providers.dart';
import 'models/task_model.dart';

part 'project_providers.g.dart';

/// Selected project ID - set when user clicks a project card
final selectedProjectIdProvider = StateProvider<String?>((ref) => null);

final _mockProjects = [
  ProjectWithTasks(
    project: const Project(
      id: 'p1',
      name: 'Web Mock Project',
      context: 'Mock context',
      status: 'active',
      approvalStatus: null,
    ),
    tasks: [
      TaskWithAssignees(
        task: Task(
          id: 't1',
          name: 'Mock Task 1',
          projectId: 'p1',
          progress: 0,
          priority: 'Medium',
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 5)),
          assigneesJson: '[]',
          milestonesJson: '[]',
          approvalStatus: null,
          githubLink: null,
          figmaLink: null,
          taskType: 'standard',
        ),
        assignees: [],
      ),
    ],
  ),
];

@riverpod
ProjectRepository projectRepository(ProjectRepositoryRef ref) {
  final db = ref.watch(databaseProvider);
  return ProjectRepository(db);
}

@riverpod
Future<ProjectWithTasks?> currentProject(CurrentProjectRef ref) async {
  if (kIsWeb) {
    try {
      final projectsWithTasks =
          await ref.watch(projectsWithTasksProvider.future);
      final selectedId = ref.watch(selectedProjectIdProvider);

      if (projectsWithTasks.isEmpty) return null;

      if (selectedId == null) {
        return projectsWithTasks.first;
      }

      try {
        return projectsWithTasks.firstWhere((p) => p.project.id == selectedId);
      } catch (_) {
        return projectsWithTasks.first;
      }
    } catch (e) {
      // Fallback to mock data
      final selectedId = ref.watch(selectedProjectIdProvider);
      if (_mockProjects.isEmpty) return null;
      if (selectedId == null) {
        return _mockProjects.first;
      }
      try {
        return _mockProjects.firstWhere((p) => p.project.id == selectedId);
      } catch (_) {
        return _mockProjects.first;
      }
    }
  }

  final selectedId = ref.watch(selectedProjectIdProvider);
  if (selectedId == null) {
    // Default to first project if none selected
    return ref.watch(projectRepositoryProvider).watchProject('project-1').first;
  }
  return ref.watch(projectRepositoryProvider).watchProject(selectedId).first;
}

/// All projects with tasks for Activity Catalog
@riverpod
Future<List<ProjectWithTasks>> projectsWithTasks(
    ProjectsWithTasksRef ref) async {
  if (kIsWeb) {
    try {
      // Fetch projects and tasks from API
      final projects = await ref.watch(apiProjectsProvider.future);
      final tasks = await ref.watch(apiTasksProvider.future);

      // Group tasks by project ID
      final Map<int, List<TaskModel>> tasksByProject = {};
      for (final task in tasks) {
        tasksByProject.putIfAbsent(task.project, () => []).add(task);
      }

      // Convert to ProjectWithTasks
      final List<ProjectWithTasks> result = [];
      for (final project in projects) {
        final projectTasks = tasksByProject[project.id] ?? [];
        final localProject = project.toLocalProject();

        final tasksWithAssignees = projectTasks.map((task) {
          return TaskWithAssignees(
            task: task.toLocalTask(localProject.id),
            assignees: [],
          );
        }).toList();

        result.add(ProjectWithTasks(
          project: localProject,
          tasks: tasksWithAssignees,
        ));
      }

      return result;
    } catch (e) {
      // Fallback to mock data if API fails
      return _mockProjects;
    }
  }
  return ref.watch(projectRepositoryProvider).watchAllProjects().first;
}

@riverpod
Stream<List<Project>> pendingProjects(PendingProjectsRef ref) {
  if (kIsWeb) return Stream.value([]);
  return ref.watch(projectRepositoryProvider).watchPendingProjects();
}

@riverpod
Stream<List<Project>> pendingProjectClosures(PendingProjectClosuresRef ref) {
  if (kIsWeb) return Stream.value([]);
  return ref.watch(projectRepositoryProvider).watchPendingProjectClosures();
}

@riverpod
Stream<List<TaskWithProject>> pendingNewTasks(PendingNewTasksRef ref) {
  if (kIsWeb) return Stream.value([]);
  return ref.watch(projectRepositoryProvider).watchPendingNewTasks();
}

@riverpod
Stream<List<TaskWithProject>> pendingTaskCompletions(
    PendingTaskCompletionsRef ref) {
  if (kIsWeb) return Stream.value([]);
  return ref.watch(projectRepositoryProvider).watchPendingTaskCompletions();
}

@riverpod
Stream<List<ActivityTemplate>> pendingTemplates(PendingTemplatesRef ref) {
  if (kIsWeb) return Stream.value([]);
  final db = ref.watch(databaseProvider);
  return (db.select(db.activityTemplates)
        ..where((t) => t.status.equals('pending')))
      .watch();
}
