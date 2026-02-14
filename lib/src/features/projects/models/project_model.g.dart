// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectModel _$ProjectModelFromJson(Map<String, dynamic> json) => ProjectModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      status: json['status'] as String,
      startDate: json['start_date'] as String,
      dueDate: json['due_date'] as String,
      description: json['description'] as String,
      workingHours: (json['working_hours'] as num).toInt(),
      createDate: json['create_date'] as String,
      duration: (json['duration'] as num).toInt(),
      completedDate: json['completed_date'] as String?,
      isApproved: json['is_approved'] as bool,
    );

Map<String, dynamic> _$ProjectModelToJson(ProjectModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'status': instance.status,
      'start_date': instance.startDate,
      'due_date': instance.dueDate,
      'description': instance.description,
      'working_hours': instance.workingHours,
      'create_date': instance.createDate,
      'duration': instance.duration,
      'completed_date': instance.completedDate,
      'is_approved': instance.isApproved,
    };
