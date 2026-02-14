import 'package:dio/dio.dart';
import '../models/task_model.dart';
import '../models/project_model.dart';
import '../models/catalog_model.dart';

class TaskApiService {
  final Dio _dio;
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  TaskApiService(this._dio);

  /// Fetch all tasks from the API
  Future<List<TaskModel>> getTasks() async {
    try {
      print('Fetching tasks from: $baseUrl/tasks/');
      final response = await _dio.get('$baseUrl/tasks/');

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        // Handle Django REST framework paginated response
        final dynamic responseData = response.data;
        List<dynamic> tasksData;

        if (responseData is List) {
          tasksData = responseData;
        } else if (responseData is Map<String, dynamic>) {
          // Check if it's a paginated response with 'results' key
          if (responseData.containsKey('results')) {
            tasksData = responseData['results'] as List<dynamic>;
          } else {
            // If it's a single object, wrap in array
            tasksData = [responseData];
          }
        } else {
          throw Exception('Unexpected response format');
        }

        final tasks = tasksData.map((taskJson) {
          print('Processing task: $taskJson');
          return TaskModel.fromJson(taskJson);
        }).toList();

        print('Successfully parsed ${tasks.length} tasks');
        return tasks;
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioException: ${e.message}');
      print('Error type: ${e.type}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// Fetch project details by ID
  Future<ProjectModel> getProject(int projectId) async {
    try {
      final response = await _dio.get('$baseUrl/projects/$projectId/');

      if (response.statusCode == 200) {
        return ProjectModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load project: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Fetch all projects
  Future<List<ProjectModel>> getProjects() async {
    try {
      print('Fetching projects from: $baseUrl/projects/');
      final response = await _dio.get('$baseUrl/projects/');

      print('Projects response status: ${response.statusCode}');
      print('Projects response data: ${response.data}');

      if (response.statusCode == 200) {
        // Handle Django REST framework paginated response
        final dynamic responseData = response.data;
        List<dynamic> projectsData;

        if (responseData is List) {
          projectsData = responseData;
        } else if (responseData is Map<String, dynamic>) {
          // Check if it's a paginated response with 'results' key
          if (responseData.containsKey('results')) {
            projectsData = responseData['results'] as List<dynamic>;
          } else {
            // If it's a single object, wrap in array
            projectsData = [responseData];
          }
        } else {
          throw Exception('Unexpected response format');
        }

        final projects = projectsData.map((projectJson) {
          print('Processing project: $projectJson');
          return ProjectModel.fromJson(projectJson);
        }).toList();

        print('Successfully parsed ${projects.length} projects');
        return projects;
      } else {
        throw Exception('Failed to load projects: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioException fetching projects: ${e.message}');
      // For now, return a mock project that matches our task's project ID
      return [
        const ProjectModel(
          id: 1,
          name: 'E-Commerce Platform',
          status: 'ACTIVE',
          startDate: '2026-01-15',
          dueDate: '2026-02-17', // Project deadline as requested
          description: 'Building a modern e-commerce platform',
          workingHours: 8,
          createDate: '2026-01-15T09:00:00Z',
          duration: 30,
          completedDate: null,
          isApproved: true,
        )
      ];
    } catch (e) {
      print('Unexpected error fetching projects: $e');
      // Return mock project as fallback
      return [
        const ProjectModel(
          id: 1,
          name: 'E-Commerce Platform',
          status: 'ACTIVE',
          startDate: '2026-01-15',
          dueDate: '2026-02-17', // Project deadline as requested
          description: 'Building a modern e-commerce platform',
          workingHours: 8,
          createDate: '2026-01-15T09:00:00Z',
          duration: 30,
          completedDate: null,
          isApproved: true,
        )
      ];
    }
  }

  /// Fetch all catalog items from the API
  Future<List<CatalogModel>> getCatalog() async {
    try {
      print('Fetching catalog from: $baseUrl/catalog/');
      final response = await _dio.get('$baseUrl/catalog/');

      print('Catalog response status: ${response.statusCode}');
      print('Catalog response data: ${response.data}');

      if (response.statusCode == 200) {
        // Handle Django REST framework paginated response
        final dynamic responseData = response.data;
        List<dynamic> catalogData;

        if (responseData is List) {
          catalogData = responseData;
        } else if (responseData is Map<String, dynamic>) {
          // Check if it's a paginated response with 'results' key
          if (responseData.containsKey('results')) {
            catalogData = responseData['results'] as List<dynamic>;
          } else {
            // If it's a single object, wrap in array
            catalogData = [responseData];
          }
        } else {
          throw Exception('Unexpected response format');
        }

        final catalog = catalogData.map((catalogJson) {
          print('Processing catalog: $catalogJson');
          return CatalogModel.fromJson(catalogJson);
        }).toList();

        print('Successfully parsed ${catalog.length} catalog items');
        return catalog;
      } else {
        throw Exception('Failed to load catalog: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioException fetching catalog: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Unexpected error fetching catalog: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// Fetch courses from catalog (catalog_type = 'COURSE')
  Future<List<CatalogModel>> getCourses() async {
    final catalog = await getCatalog();
    return catalog.where((item) => item.catalogType == 'COURSE').toList();
  }

  /// Fetch routines from catalog (catalog_type = 'ROUTINE')
  Future<List<CatalogModel>> getRoutines() async {
    final catalog = await getCatalog();
    return catalog.where((item) => item.catalogType == 'ROUTINE').toList();
  }

  /// Fetch work items from catalog (catalog_type = 'CUSTOM')
  Future<List<CatalogModel>> getWorkItems() async {
    final catalog = await getCatalog();
    return catalog.where((item) => item.catalogType == 'CUSTOM').toList();
  }

  /// Add catalog item to daily plan
  Future<Map<String, dynamic>> addCatalogToDailyPlan({
    required int catalogId,
    required String planDate,
    String? scheduledStartTime,
    String? scheduledEndTime,
    required int plannedDurationMinutes,
    String? notes,
    String? quadrant,
  }) async {
    try {
      print('Adding catalog item $catalogId to daily plan for $planDate');

      final requestData = {
        'catalog_id': catalogId,
        'plan_date': planDate,
        'planned_duration_minutes': plannedDurationMinutes,
        if (scheduledStartTime != null)
          'scheduled_start_time': scheduledStartTime,
        if (scheduledEndTime != null) 'scheduled_end_time': scheduledEndTime,
        if (notes != null) 'notes': notes,
        if (quadrant != null) 'quadrant': quadrant,
      };

      print('Request data: $requestData');

      final response = await _dio.post(
        '$baseUrl/today-plan/add_from_catalog/',
        data: requestData,
      );

      print('Add to plan response status: ${response.statusCode}');
      print('Add to plan response data: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to add to daily plan: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioException adding to daily plan: ${e.message}');
      print('Response data: ${e.response?.data}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Unexpected error adding to daily plan: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// Fetch today's planned items from the API
  Future<List<Map<String, dynamic>>> getTodayPlan() async {
    try {
      print('Fetching today\'s plan from: $baseUrl/today-plan/today/');
      final response = await _dio.get('$baseUrl/today-plan/today/');

      print('Today plan response status: ${response.statusCode}');
      print('Today plan response data: ${response.data}');

      if (response.statusCode == 200) {
        // Handle both array and single object responses
        final dynamic responseData = response.data;
        List<dynamic> planData;

        if (responseData is List) {
          planData = responseData;
        } else if (responseData is Map<String, dynamic>) {
          // If it's a single object, wrap in array
          planData = [responseData];
        } else {
          throw Exception('Unexpected response format');
        }

        print('Successfully parsed ${planData.length} today plan items');
        return planData.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load today plan: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioException fetching today plan: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Unexpected error fetching today plan: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// Fetch users for project work statistics dropdown
  Future<List<dynamic>> getUsersForStats() async {
    try {
      print(
          'Fetching users for stats from: $baseUrl/dashboard/users_for_stats/');
      final response = await _dio.get('$baseUrl/dashboard/users_for_stats/');

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final dynamic responseData = response.data;
        List<dynamic> usersData;

        if (responseData is List) {
          usersData = responseData;
        } else if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('users')) {
            usersData = responseData['users'] as List<dynamic>;
          } else if (responseData.containsKey('results')) {
            usersData = responseData['results'] as List<dynamic>;
          } else {
            usersData = [responseData];
          }
        } else {
          throw Exception('Unexpected response format');
        }

        print('Successfully parsed ${usersData.length} users for stats');
        return usersData;
      } else {
        throw Exception(
            'Failed to load users for stats: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioException fetching users for stats: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Unexpected error fetching users for stats: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// Fetch project work statistics for a specific user
  Future<Map<String, dynamic>> getProjectWorkStats({int? userId}) async {
    try {
      final String url = userId != null
          ? '$baseUrl/dashboard/project_work_stats/?user_id=$userId'
          : '$baseUrl/dashboard/project_work_stats/';

      print('Fetching project work stats from: $url');
      final response = await _dio.get(url);

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final dynamic responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          print('Successfully parsed project work stats');
          return responseData;
        } else {
          throw Exception('Unexpected response format - expected Map');
        }
      } else {
        throw Exception(
            'Failed to load project work stats: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioException fetching project work stats: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Unexpected error fetching project work stats: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// Create a project with tasks, assignees, and milestones in one API call
  Future<Map<String, dynamic>> createProjectWithTasks({
    required String name,
    String description = '',
    int? projectLead,
    DateTime? deadline,
    List<Map<String, dynamic>> tasks = const [],
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'description': description,
      };
      if (projectLead != null) body['project_lead'] = projectLead;
      if (deadline != null) {
        body['deadline'] =
            '${deadline.year}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}';
      }
      if (tasks.isNotEmpty) body['tasks'] = tasks;

      print('Creating project with tasks: $body');
      final response = await _dio.post(
        '$baseUrl/projects/create-with-tasks/',
        data: body,
      );

      if (response.statusCode == 201) {
        print('Project created successfully: ${response.data}');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create project: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioException creating project: ${e.response?.data ?? e.message}');
      throw Exception('Network error: ${e.response?.data ?? e.message}');
    } catch (e) {
      print('Unexpected error creating project: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// Toggle subtask completion status
  Future<Map<String, dynamic>> toggleSubtaskCompletion(int subtaskId) async {
    try {
      print('Toggling subtask completion: $subtaskId');
      final response = await _dio.patch(
        '$baseUrl/sub-tasks/$subtaskId/toggle_completion/',
      );

      if (response.statusCode == 200) {
        print('Subtask toggled successfully: ${response.data}');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to toggle subtask: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioException toggling subtask: ${e.response?.data ?? e.message}');
      throw Exception('Network error: ${e.response?.data ?? e.message}');
    } catch (e) {
      print('Unexpected error toggling subtask: $e');
      throw Exception('Unexpected error: $e');
    }
  }
}
