import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import '../../../core/database/database.dart';

part 'task_model.g.dart';

@JsonSerializable()
class AssigneeModel {
  final int id;
  @JsonKey(name: 'user_email')
  final String userEmail;
  final String role;
  final int user;
  @JsonKey(name: 'task_title')
  final String taskTitle;
  @JsonKey(name: 'assigned_at')
  final String assignedAt;
  final int task;
  @JsonKey(name: 'profile_picture')
  final String? profilePicture;

  const AssigneeModel({
    required this.id,
    required this.userEmail,
    required this.role,
    required this.user,
    required this.taskTitle,
    required this.assignedAt,
    required this.task,
    this.profilePicture,
  });

  factory AssigneeModel.fromJson(Map<String, dynamic> json) =>
      _$AssigneeModelFromJson(json);
  Map<String, dynamic> toJson() => _$AssigneeModelToJson(this);

  /// Get name from email (before @ symbol)
  String get name {
    return userEmail.split('@')[0];
  }

  /// Get email
  String get email => userEmail;

  /// Convert to local database User model
  User toLocalUser() {
    return User(
      id: user.toString(),
      name: name,
      avatarUrl: profilePicture ?? '',
      email: userEmail,
      role: role,
      reportingManagerId: null,
      department: null,
    );
  }
}

@JsonSerializable()
class TaskModel {
  final int id;
  final String title;
  final int project;
  final String priority;
  final String status;
  @JsonKey(name: 'start_date')
  final String? startDate;
  @JsonKey(name: 'due_date')
  final String dueDate;
  final int progress;
  final List<SubTaskModel>? subtasks;
  @JsonKey(name: 'assignees_list')
  final List<AssigneeModel>? assigneesList;

  const TaskModel({
    required this.id,
    required this.title,
    required this.project,
    required this.priority,
    required this.status,
    this.startDate,
    required this.dueDate,
    required this.progress,
    this.subtasks,
    this.assigneesList,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      _$TaskModelFromJson(json);
  Map<String, dynamic> toJson() => _$TaskModelToJson(this);

  /// Convert to local database Task model
  Task toLocalTask(String projectId) {
    // Convert subtasks to milestones JSON format
    String milestonesJson = '[]';
    if (subtasks != null && subtasks!.isNotEmpty) {
      final milestones = subtasks!
          .map((subtask) => {
                'id': 'milestone_${subtask.id}',
                'name': subtask.title,
                'completed': subtask.status == 'DONE',
                'weight': subtask.progressWeight,
              })
          .toList();
      milestonesJson = jsonEncode(milestones);
    }

    // Convert assignees to JSON format
    String assigneesJsonStr = '[]';
    if (assigneesList != null && assigneesList!.isNotEmpty) {
      final assigneeIds = assigneesList!.map((a) => a.id.toString()).toList();
      assigneesJsonStr = jsonEncode(assigneeIds);
    }

    // Parse start date or use now as fallback
    DateTime taskStartDate;
    try {
      taskStartDate =
          startDate != null ? DateTime.parse(startDate!) : DateTime.now();
    } catch (e) {
      taskStartDate = DateTime.now();
    }

    return Task(
      id: 'api_task_$id',
      name: title,
      projectId: projectId,
      progress: progress,
      priority: priority,
      startDate: taskStartDate,
      endDate: DateTime.parse(dueDate),
      assigneesJson: assigneesJsonStr,
      milestonesJson: milestonesJson,
      approvalStatus: null,
      githubLink: null,
      figmaLink: null,
      taskType: 'standard',
    );
  }
}

@JsonSerializable()
class SubTaskModel {
  final int id;
  final String title;
  final String status;
  @JsonKey(name: 'progress_weight')
  final int progressWeight;
  @JsonKey(name: 'due_date')
  final String dueDate;

  const SubTaskModel({
    required this.id,
    required this.title,
    required this.status,
    required this.progressWeight,
    required this.dueDate,
  });

  factory SubTaskModel.fromJson(Map<String, dynamic> json) =>
      _$SubTaskModelFromJson(json);
  Map<String, dynamic> toJson() => _$SubTaskModelToJson(this);
}
