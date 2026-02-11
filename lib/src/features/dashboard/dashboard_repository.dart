import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:project_pm/src/core/database/database.dart';
import 'package:project_pm/src/core/database/database_provider.dart';
import 'package:project_pm/src/core/models/project_with_tasks.dart';
import 'package:rxdart/rxdart.dart';

part 'dashboard_repository.g.dart';

@riverpod
DashboardRepository dashboardRepository(DashboardRepositoryRef ref) {
  return DashboardRepository(ref.watch(databaseProvider));
}

class DashboardRepository {
  final AppDatabase _db;

  DashboardRepository(this._db);

  Stream<List<ProjectWithTasks>> watchProjects() {
    // Watch all relevant tables
    return _db.select(_db.projects).watch().switchMap((projects) {
      // For each update to projects, we re-query tasks and users
      // Ideally we should use joins, but for flexibility/MVP we query separately
      return Stream.fromFuture(_hydrateProjects(projects));
    });
  }

  Future<List<ProjectWithTasks>> _hydrateProjects(
      List<Project> projects) async {
    if (projects.isEmpty) return [];

    // Fetch all users for lookup
    final allUsers = await _db.select(_db.users).get();
    final userMap = {for (var u in allUsers) u.id: u};

    final result = <ProjectWithTasks>[];

    for (var project in projects) {
      // Fetch tasks for this project
      final tasks = await (_db.select(_db.tasks)
            ..where((t) => t.projectId.equals(project.id)))
          .get();

      final tasksWithAssignees = tasks.map((task) {
        // Parse assigneesJson
        List<String> assigneeIds = [];
        try {
          assigneeIds =
              List<String>.from(jsonDecode(task.assigneesJson) as List);
        } catch (_) {
          // invalid json or empty
        }

        final assignees =
            assigneeIds.map((id) => userMap[id]).whereType<User>().toList();

        return TaskWithAssignees(task: task, assignees: assignees);
      }).toList();

      result.add(ProjectWithTasks(project: project, tasks: tasksWithAssignees));
    }

    return result;
  }

  Future<List<ProjectWithTasks>> fetchProjectsWithTasks() async {
    final projects = await _db.select(_db.projects).get();
    return _hydrateProjects(projects);
  }

  Future<TeamActivityStats> fetchTeamActivityStats() async {
    // Return mock data for web since database operations don't work on web
    if (kIsWeb) {
      return TeamActivityStats(
        totalUsers: 5,
        filledCount: 3,
        notFilledCount: 2,
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final allUsers = await _db.select(_db.users).get();
    int totalUsers = allUsers.length;
    int filledCount = 0;

    for (var user in allUsers) {
      final dailyLog = await (_db.select(_db.dailyLogs)
            ..where((t) => t.userId.equals(user.id) & t.date.equals(today)))
          .getSingleOrNull();

      if (dailyLog != null) {
        final items = await (_db.select(_db.loggedItems)
              ..where((t) => t.dailyLogId.equals(dailyLog.id)))
            .get();

        int minutes = 0;
        for (var item in items) {
          if (item.endTime != null) {
            minutes += item.endTime!.difference(item.startTime).inMinutes;
          } else {
            // Include running tasks
            minutes += DateTime.now().difference(item.startTime).inMinutes;
          }
        }

        if (minutes >= 9 * 60) {
          filledCount++;
        }
      }
    }

    return TeamActivityStats(
      totalUsers: totalUsers,
      filledCount: filledCount,
      notFilledCount: totalUsers - filledCount,
    );
  }

  Future<List<RecentActivity>> fetchRecentActivities() async {
    // Return mock data for web
    if (kIsWeb) {
      return [
        RecentActivity(
          id: '1',
          title: 'Completed UI Design',
          time: DateTime.now().subtract(const Duration(hours: 2)),
          userAvatarUrl: '',
          userName: 'Demo User',
          description: 'Finished the dashboard redesign',
        ),
      ];
    }

    // Join LoggedItems with Tasks and DailyLogs/Users if needed
    // For MVP, just get LoggedItems and basic info
    final query = _db.select(_db.loggedItems).join([
      leftOuterJoin(
          _db.tasks, _db.tasks.id.equalsExp(_db.loggedItems.relatedTaskId)),
      innerJoin(_db.dailyLogs,
          _db.dailyLogs.id.equalsExp(_db.loggedItems.dailyLogId)),
      innerJoin(_db.users, _db.users.id.equalsExp(_db.dailyLogs.userId)),
    ]);

    query.orderBy([OrderingTerm.desc(_db.loggedItems.startTime)]);
    query.limit(5);

    final rows = await query.get();

    return rows.map((row) {
      final item = row.readTable(_db.loggedItems);
      final task = row.readTableOrNull(_db.tasks);
      final user = row.readTable(_db.users);

      String title = item.name;
      if (title.isEmpty && task != null) {
        title = task.name;
      }

      return RecentActivity(
        id: item.id,
        title: title,
        time: item.startTime,
        userAvatarUrl: user.avatarUrl,
        userName: user.name,
        description:
            item.description.isNotEmpty ? item.description : (task?.name ?? ''),
      );
    }).toList();
  }
}

class TeamActivityStats {
  final int totalUsers;
  final int filledCount;
  final int notFilledCount;

  TeamActivityStats({
    required this.totalUsers,
    required this.filledCount,
    required this.notFilledCount,
  });
}

class RecentActivity {
  final String id;
  final String title;
  final DateTime time;
  final String userAvatarUrl;
  final String userName;
  final String description;

  RecentActivity({
    required this.id,
    required this.title,
    required this.time,
    required this.userAvatarUrl,
    required this.userName,
    required this.description,
  });
}
