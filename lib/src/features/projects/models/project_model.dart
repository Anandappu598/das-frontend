import 'package:json_annotation/json_annotation.dart';
import '../../../core/database/database.dart';

part 'project_model.g.dart';

@JsonSerializable()
class ProjectModel {
  final int id;
  final String name;
  final String status;
  @JsonKey(name: 'start_date')
  final String startDate;
  @JsonKey(name: 'due_date')
  final String dueDate;
  final String description;
  @JsonKey(name: 'working_hours')
  final int workingHours;
  @JsonKey(name: 'create_date')
  final String createDate;
  final int duration;
  @JsonKey(name: 'completed_date')
  final String? completedDate;
  @JsonKey(name: 'is_approved')
  final bool isApproved;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.status,
    required this.startDate,
    required this.dueDate,
    required this.description,
    required this.workingHours,
    required this.createDate,
    required this.duration,
    this.completedDate,
    required this.isApproved,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) =>
      _$ProjectModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectModelToJson(this);

  /// Convert to local database Project model
  Project toLocalProject() {
    return Project(
      id: 'api_project_$id',
      name: name,
      context: description,
      status: status.toLowerCase(),
      approvalStatus: isApproved ? 'approved' : 'pending',
    );
  }
}
