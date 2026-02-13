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
    );

Map<String, dynamic> _$TaskModelToJson(TaskModel instance) => <String, dynamic>{
      'title': instance.title,
      'project': instance.project,
      'priority': instance.priority,
      'status': instance.status,
      'due_date': instance.dueDate,
    };
