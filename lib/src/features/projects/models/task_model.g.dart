// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssigneeModel _$AssigneeModelFromJson(Map<String, dynamic> json) =>
    AssigneeModel(
      id: (json['id'] as num).toInt(),
      userEmail: json['user_email'] as String,
      role: json['role'] as String,
      user: (json['user'] as num).toInt(),
      taskTitle: json['task_title'] as String,
      assignedAt: json['assigned_at'] as String,
      task: (json['task'] as num).toInt(),
      profilePicture: json['profile_picture'] as String?,
    );

Map<String, dynamic> _$AssigneeModelToJson(AssigneeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_email': instance.userEmail,
      'role': instance.role,
      'user': instance.user,
      'task_title': instance.taskTitle,
      'assigned_at': instance.assignedAt,
      'task': instance.task,
      'profile_picture': instance.profilePicture,
    };

TaskModel _$TaskModelFromJson(Map<String, dynamic> json) => TaskModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      project: (json['project'] as num).toInt(),
      priority: json['priority'] as String,
      status: json['status'] as String,
      startDate: json['start_date'] as String?,
      dueDate: json['due_date'] as String,
      progress: (json['progress'] as num).toInt(),
      subtasks: (json['subtasks'] as List<dynamic>?)
          ?.map((e) => SubTaskModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      assigneesList: (json['assignees_list'] as List<dynamic>?)
          ?.map((e) => AssigneeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TaskModelToJson(TaskModel instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'project': instance.project,
      'priority': instance.priority,
      'status': instance.status,
      'start_date': instance.startDate,
      'due_date': instance.dueDate,
      'progress': instance.progress,
      'subtasks': instance.subtasks,
      'assignees_list': instance.assigneesList,
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
