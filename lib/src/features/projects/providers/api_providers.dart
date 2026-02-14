import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/task_api_service.dart';
import '../models/task_model.dart';
import '../models/project_model.dart';
import '../models/catalog_model.dart';

part 'api_providers.g.dart';

/// Dio provider for HTTP requests
@riverpod
Dio dio(DioRef ref) {
  final dio = Dio();
  dio.options.connectTimeout = const Duration(seconds: 10);
  dio.options.receiveTimeout = const Duration(seconds: 10);
  return dio;
}

/// Task API service provider
@riverpod
TaskApiService taskApiService(TaskApiServiceRef ref) {
  final dio = ref.watch(dioProvider);
  return TaskApiService(dio);
}

/// Fetch all projects from API
@riverpod
Future<List<ProjectModel>> apiProjects(ApiProjectsRef ref) async {
  final apiService = ref.watch(taskApiServiceProvider);

  try {
    return await apiService.getProjects();
  } catch (e) {
    throw Exception('Failed to fetch projects: $e');
  }
}

/// Fetch all tasks from API
@riverpod
Future<List<TaskModel>> apiTasks(ApiTasksRef ref) async {
  final apiService = ref.watch(taskApiServiceProvider);

  try {
    return await apiService.getTasks();
  } catch (e) {
    throw Exception('Failed to fetch tasks: $e');
  }
}

/// Fetch specific project by ID from API
@riverpod
Future<ProjectModel> apiProject(ApiProjectRef ref, int projectId) async {
  final apiService = ref.watch(taskApiServiceProvider);

  try {
    return await apiService.getProject(projectId);
  } catch (e) {
    throw Exception('Failed to fetch project $projectId: $e');
  }
}

/// Fetch all catalog items from API
@riverpod
Future<List<CatalogModel>> apiCatalog(ApiCatalogRef ref) async {
  final apiService = ref.watch(taskApiServiceProvider);

  try {
    return await apiService.getCatalog();
  } catch (e) {
    throw Exception('Failed to fetch catalog: $e');
  }
}

/// Fetch courses from catalog API
@riverpod
Future<List<CatalogModel>> apiCourses(ApiCoursesRef ref) async {
  final apiService = ref.watch(taskApiServiceProvider);

  try {
    return await apiService.getCourses();
  } catch (e) {
    throw Exception('Failed to fetch courses: $e');
  }
}

/// Fetch routines from catalog API
@riverpod
Future<List<CatalogModel>> apiRoutines(ApiRoutinesRef ref) async {
  final apiService = ref.watch(taskApiServiceProvider);

  try {
    return await apiService.getRoutines();
  } catch (e) {
    throw Exception('Failed to fetch routines: $e');
  }
}

/// Fetch work items from catalog API (CUSTOM type)
@riverpod
Future<List<CatalogModel>> apiWorkItems(ApiWorkItemsRef ref) async {
  final apiService = ref.watch(taskApiServiceProvider);

  try {
    return await apiService.getWorkItems();
  } catch (e) {
    throw Exception('Failed to fetch work items: $e');
  }
}

/// Fetch today's planned items from API
@riverpod
Future<List<Map<String, dynamic>>> apiTodayPlan(ApiTodayPlanRef ref) async {
  final apiService = ref.watch(taskApiServiceProvider);

  try {
    return await apiService.getTodayPlan();
  } catch (e) {
    throw Exception('Failed to fetch today plan: $e');
  }
}
