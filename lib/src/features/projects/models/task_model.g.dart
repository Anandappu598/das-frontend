// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskModel _$TaskModelFromJson(Map<String, dynamic> json) => TaskModel(
      title: json['title'] as String,
      project: (json['project'] as num).toInt(),
      priority: json['priority'] as String,
      status: json['status'] as String,
      dueDate: json['due_date'] as String,
      subtasks: (json['subtasks'] as List<dynamic>?)
          ?.map((e) => SubTaskModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TaskModelToJson(TaskModel instance) => <String, dynamic>{
      'title': instance.title,
      'project': instance.project,
      'priority': instance.priority,
      'status': instance.status,
      'due_date': instance.dueDate,
      'subtasks': instance.subtasks,
    };

SubTaskModel _$SubTaskModelFromJson(Map<String, dynamic> json) => SubTaskModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      status: json['status'] as String,
      progressWeight: (json['progress_weight'] as num).toInt(),
      dueDate: json['due_date'] as String,
    );

Map<String, dynamic> _$SubTaskModelToJson(SubTaskModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'status': instance.status,
      'progress_weight': instance.progressWeight,
      'due_date': instance.dueDate,
    };
