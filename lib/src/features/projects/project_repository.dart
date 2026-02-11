import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';
import '../../core/database/database.dart';
import '../../core/models/project_with_tasks.dart';
import '../../core/models/milestone.dart';

class ProjectRepository {
  final AppDatabase _db;

  ProjectRepository(this._db);

  Stream<ProjectWithTasks?> watchProject(String projectId) {
    final projectStream = (_db.select(_db.projects)
          ..where((p) => p.id.equals(projectId)))
        .watchSingleOrNull();

    return projectStream.switchMap((project) {
      if (project == null) return Stream.value(null);

      return (_db.select(_db.tasks)
            ..where((t) => t.projectId.equals(projectId)))
          .watch()
          .switchMap((tasks) => Stream.fromFuture(_hydrateTasks(tasks)))
          .map((tasksWithAssignees) => ProjectWithTasks(
                project: project,
                tasks: tasksWithAssignees,
              ));
    });
  }

  Future<List<TaskWithAssignees>> _hydrateTasks(List<Task> tasks) async {
    if (tasks.isEmpty) return [];

    // Fetch all users for lookup
    final allUsers = await _db.select(_db.users).get();
    final userMap = {for (var u in allUsers) u.id: u};

    return tasks.map((task) {
      // Parse assigneesJson
      List<String> assigneeIds = [];
      try {
        assigneeIds = List<String>.from(jsonDecode(task.assigneesJson) as List);
      } catch (_) {
        // invalid json or empty
      }

      final assignees =
          assigneeIds.map((id) => userMap[id]).whereType<User>().toList();

      return TaskWithAssignees(task: task, assignees: assignees);
    }).toList();
  }

  Future<void> updateTaskMilestones(
      String taskId, List<Milestone> milestones) async {
    final jsonStr = jsonEncode(milestones.map((m) => m.toJson()).toList());
    final progress = _calculateProgress(milestones);

    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        milestonesJson: Value(jsonStr),
        progress: Value(progress),
        approvalStatus: progress >= 100
            ? const Value('pending_completion')
            : const Value(null),
      ),
    );
  }

  int _calculateProgress(List<Milestone> milestones) {
    if (milestones.isEmpty) return 0;
    int completedWeight = milestones
        .where((m) => m.completed)
        .fold(0, (sum, m) => sum + m.weight);
    return completedWeight > 100 ? 100 : completedWeight;
  }

  Future<void> updateProject(ProjectsCompanion project) async {
    await (_db.update(_db.projects)
          ..where((p) => p.id.equals(project.id.value)))
        .write(project);
  }

  Future<void> updateProjectContext(String projectId, String context) async {
    await (_db.update(_db.projects)..where((p) => p.id.equals(projectId)))
        .write(
      ProjectsCompanion(context: Value(context)),
    );
  }

  Stream<List<TaskWithAssignees>> watchPendingApprovals() {
    return (_db.select(_db.tasks)
          ..where((t) => t.approvalStatus.equals('pending')))
        .watch()
        .map((tasks) => tasks
            .map((t) => TaskWithAssignees(task: t, assignees: []))
            .toList());
  }

  Future<void> createProject(ProjectsCompanion project) async {
    await _db.into(_db.projects).insert(project);
  }

  Future<void> createTask(TasksCompanion task) async {
    await _db.into(_db.tasks).insert(task);
  }

  Future<void> updateTask(TasksCompanion task) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id.value)))
        .write(task);
  }

  /// Watch all projects with their tasks for Activity Catalog
  Stream<List<ProjectWithTasks>> watchAllProjects() {
    final projectsStream = _db.select(_db.projects).watch();

    return projectsStream.switchMap((projects) {
      if (projects.isEmpty) return Stream.value(<ProjectWithTasks>[]);

      // Get all tasks at once
      return _db.select(_db.tasks).watch().switchMap((allTasks) {
        return Stream.fromFuture(_hydrateTasks(allTasks)).map((hydratedTasks) {
          return projects.map((project) {
            final projectTasks = hydratedTasks
                .where((t) => t.task.projectId == project.id)
                .toList();

            return ProjectWithTasks(project: project, tasks: projectTasks);
          }).toList();
        });
      });
    });
  }

  // ========== APPROVAL WORKFLOWS ==========

  /// Watch projects pending creation approval
  Stream<List<Project>> watchPendingProjects() {
    return (_db.select(_db.projects)
          ..where((p) => p.approvalStatus.equals('pending_creation')))
        .watch();
  }

  /// Watch projects pending completion/closure approval
  Stream<List<Project>> watchPendingProjectClosures() {
    return (_db.select(_db.projects)
          ..where((p) => p.approvalStatus.equals('pending_completion')))
        .watch();
  }

  /// Watch tasks pending creation approval (with project info)
  Stream<List<TaskWithProject>> watchPendingNewTasks() {
    final query = _db.select(_db.tasks).join([
      innerJoin(_db.projects, _db.projects.id.equalsExp(_db.tasks.projectId)),
    ])
      ..where(_db.tasks.approvalStatus.equals('pending_creation'));

    return query.watch().map((rows) {
      return rows.map((row) {
        return TaskWithProject(
          task: row.readTable(_db.tasks),
          project: row.readTable(_db.projects),
        );
      }).toList();
    });
  }

  /// Watch tasks pending completion approval (with project info)
  Stream<List<TaskWithProject>> watchPendingTaskCompletions() {
    final query = _db.select(_db.tasks).join([
      innerJoin(_db.projects, _db.projects.id.equalsExp(_db.tasks.projectId)),
    ])
      ..where(_db.tasks.approvalStatus.equals('pending_completion'));

    return query.watch().map((rows) {
      return rows.map((row) {
        return TaskWithProject(
          task: row.readTable(_db.tasks),
          project: row.readTable(_db.projects),
        );
      }).toList();
    });
  }

  // --- Approve/Reject Actions ---

  Future<void> approveProject(String projectId) async {
    await (_db.update(_db.projects)..where((p) => p.id.equals(projectId)))
        .write(const ProjectsCompanion(approvalStatus: Value('approved')));
  }

  Future<void> rejectProject(String projectId) async {
    await (_db.update(_db.projects)..where((p) => p.id.equals(projectId)))
        .write(const ProjectsCompanion(approvalStatus: Value('rejected')));
  }

  Future<void> approveProjectCompletion(String projectId) async {
    await (_db.update(_db.projects)..where((p) => p.id.equals(projectId)))
        .write(const ProjectsCompanion(
            approvalStatus: Value('approved'), status: Value('completed')));
  }

  Future<void> rejectProjectCompletion(String projectId) async {
    // Keep it open - revert to approved status
    await (_db.update(_db.projects)..where((p) => p.id.equals(projectId)))
        .write(const ProjectsCompanion(approvalStatus: Value('approved')));
  }

  Future<void> approveTask(String taskId) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId)))
        .write(const TasksCompanion(approvalStatus: Value('approved')));
  }

  Future<void> rejectTask(String taskId) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId)))
        .write(const TasksCompanion(approvalStatus: Value('rejected')));
  }

  Future<void> approveTaskCompletion(String taskId) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
        const TasksCompanion(
            approvalStatus: Value('approved'), progress: Value(100)));
  }

  Future<void> rejectTaskCompletion(String taskId) async {
    // Revoke completion - set back to approved and lower progress
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId)))
        .write(const TasksCompanion(approvalStatus: Value('approved')));
  }

  /// Request project closure - sets approval status to pending_completion
  Future<void> requestProjectClosure(String projectId) async {
    await (_db.update(_db.projects)..where((p) => p.id.equals(projectId)))
        .write(const ProjectsCompanion(
      approvalStatus: Value('pending_completion'),
    ));
  }

  /// Request task completion approval - marks task as 100% and pending approval
  Future<void> requestTaskCompletion(String taskId) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId)))
        .write(const TasksCompanion(
      approvalStatus: Value('pending_completion'),
      progress: Value(100),
    ));
  }

  /// Revoke task completion - revert to approved status with previous progress
  Future<void> revokeTaskCompletion(String taskId, int previousProgress) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId)))
        .write(TasksCompanion(
      approvalStatus: const Value('approved'),
      progress: Value(previousProgress),
    ));
  }
}

/// Model for task with its parent project
class TaskWithProject {
  final Task task;
  final Project project;

  TaskWithProject({required this.task, required this.project});
}
