import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import '../../../core/database/database.dart';

part 'task_model.g.dart';

@JsonSerializable()
class TaskModel {
  final String title;
  final int project;
  final String priority;
  final String status;
  @JsonKey(name: 'due_date')
  final String dueDate;
  final List<SubTaskModel>? subtasks;

  const TaskModel({
    required this.title,
    required this.project,
    required this.priority,
    required this.status,
    required this.dueDate,
    this.subtasks,
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

    return Task(
      id: 'api_${title.replaceAll(' ', '_').toLowerCase()}',
      name: title,
      projectId: projectId,
      progress:
          status == 'COMPLETED' ? 100 : (status == 'IN_PROGRESS' ? 50 : 0),
      priority: priority,
      startDate: DateTime.now(),
      endDate: DateTime.parse(dueDate),
      assigneesJson: '[]',
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
