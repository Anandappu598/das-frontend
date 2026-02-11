import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/database/database.dart';
import '../../core/database/database_provider.dart';
import 'project_repository.dart';
import '../../core/models/project_with_tasks.dart';

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
Stream<ProjectWithTasks?> currentProject(CurrentProjectRef ref) {
  if (kIsWeb) {
    final selectedId = ref.watch(selectedProjectIdProvider);
    if (_mockProjects.isEmpty) return Stream.value(null);
    if (selectedId == null) {
      return Stream.value(_mockProjects.first);
    }
    try {
      return Stream.value(
          _mockProjects.firstWhere((p) => p.project.id == selectedId));
    } catch (_) {
      return Stream.value(_mockProjects.first);
    }
  }

  final selectedId = ref.watch(selectedProjectIdProvider);
  if (selectedId == null) {
    // Default to first project if none selected
    return ref.watch(projectRepositoryProvider).watchProject('project-1');
  }
  return ref.watch(projectRepositoryProvider).watchProject(selectedId);
}

/// All projects with tasks for Activity Catalog
@riverpod
Stream<List<ProjectWithTasks>> projectsWithTasks(ProjectsWithTasksRef ref) {
  if (kIsWeb) return Stream.value(_mockProjects);
  return ref.watch(projectRepositoryProvider).watchAllProjects();
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
