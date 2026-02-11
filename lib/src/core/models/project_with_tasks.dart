import 'package:project_pm/src/core/database/database.dart';

// hydrated model
class ProjectWithTasks {
  final Project project;
  final List<TaskWithAssignees> tasks;

  ProjectWithTasks({required this.project, required this.tasks});

  // Helper to match React's "status" logic if needed
  bool get isActive => project.status == 'active';
  bool get isCompleted => project.status == 'completed';
}

class TaskWithAssignees {
  final Task task;
  final List<User> assignees;

  TaskWithAssignees({required this.task, required this.assignees});

  double get progress => task.progress.toDouble();
  DateTime get endDate => task.endDate;
}
