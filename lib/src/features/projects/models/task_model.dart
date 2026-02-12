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

  const TaskModel({
    required this.title,
    required this.project,
    required this.priority,
    required this.status,
    required this.dueDate,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      _$TaskModelFromJson(json);
  Map<String, dynamic> toJson() => _$TaskModelToJson(this);

  /// Convert to local database Task model
  Task toLocalTask(String projectId) {
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
      milestonesJson: '[]',
      approvalStatus: null,
      githubLink: null,
      figmaLink: null,
      taskType: 'standard',
    );
  }
}
