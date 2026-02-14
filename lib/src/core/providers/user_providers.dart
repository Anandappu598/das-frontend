import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pm/src/core/database/database.dart';
import 'package:project_pm/src/core/database/database_provider.dart';
// import 'package:project_pm/src/core/constants/enums.dart'; // Unused now

/// Current user ID - can be changed via user switcher
final currentUserIdProvider = StateProvider<String>((ref) => 'u1');

/// User being impersonated from (for manager view-as feature)
final impersonatingFromUserIdProvider = StateProvider<String?>((ref) => null);

/// Whether the app is in read-only mode (when impersonating)
final isReadOnlyProvider = Provider<bool>((ref) {
  return ref.watch(impersonatingFromUserIdProvider) != null;
});

/// All users from database
final allUsersProvider = FutureProvider<List<User>>((ref) async {
  if (kIsWeb) {
    // Return mock users for web to bypass DB issues
    return [
      const User(
        id: 'u1',
        name: 'Alice Admin',
        avatarUrl:
            'https://ui-avatars.com/api/?name=Alice+Admin&background=0D8ABC&color=fff',
        email: 'alice@company.com',
        role: 'ADMIN',
        department: 'Management',
        reportingManagerId: null,
      ),
      const User(
        id: 'u2',
        name: 'Bob Manager',
        avatarUrl:
            'https://ui-avatars.com/api/?name=Bob+Manager&background=6D28D9&color=fff',
        email: 'bob@company.com',
        role: 'MANAGER',
        department: 'Engineering',
        reportingManagerId: 'u1',
      ),
      const User(
        id: 'u3',
        name: 'Charlie Lead',
        avatarUrl:
            'https://ui-avatars.com/api/?name=Charlie+Lead&background=EC4899&color=fff',
        email: 'charlie@company.com',
        role: 'TEAM_LEAD',
        department: 'Frontend',
        reportingManagerId: 'u2',
      ),
      const User(
        id: 'u4',
        name: 'Diana Dev',
        avatarUrl:
            'https://ui-avatars.com/api/?name=Diana+Dev&background=10B981&color=fff',
        email: 'diana@company.com',
        role: 'EMPLOYEE',
        department: 'Frontend',
        reportingManagerId: 'u3',
      ),
      const User(
        id: 'u5',
        name: 'Eve Lead',
        avatarUrl:
            'https://ui-avatars.com/api/?name=Eve+Lead&background=F59E0B&color=fff',
        email: 'eve@company.com',
        role: 'TEAM_LEAD',
        department: 'Backend',
        reportingManagerId: 'u2',
      ),
      const User(
        id: 'u6',
        name: 'Frank Employee',
        avatarUrl:
            'https://ui-avatars.com/api/?name=Frank+Employee&background=6366F1&color=fff',
        email: 'frank@company.com',
        role: 'ADMIN', // As per seed, Frank is Admin
        department: 'Backend',
        reportingManagerId: 'u5',
      ),
    ];
  }
  final db = ref.read(databaseProvider);
  return db.select(db.users).get();
});

/// Current user object
final currentUserProvider = FutureProvider<User?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (kIsWeb) {
    final allUsers = await ref.watch(allUsersProvider.future);
    try {
      return allUsers.firstWhere((u) => u.id == userId);
    } catch (_) {
      return null;
    }
  }
  final db = ref.read(databaseProvider);
  return (db.select(db.users)..where((t) => t.id.equals(userId)))
      .getSingleOrNull();
});

/// Provider to fetch stats for all users in a single query
final teamStatsProvider =
    FutureProvider<Map<String, Map<String, int>>>((ref) async {
  final db = ref.read(databaseProvider);
  final allTasks = await db.select(db.tasks).get();

  // Map to store stats per user: userId -> {active, completed, workload}
  final Map<String, Map<String, int>> stats = {};

  for (final task in allTasks) {
    // Parse assignees (primitive parse for speed, assumes valid JSON)
    // In a real app, use a proper join table or robust parsing
    final assigneesStr = task.assigneesJson; // e.g. ["u1", "u2"]

    // We can iterate all known users or just parse IDs from string
    // Let's rely on string matching for now as in original code
    // A better approach would be to decode JSON once
    List<String> assigneeIds = [];
    try {
      // Remove brackets and quotes to get raw IDs
      assigneeIds = assigneesStr
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      continue;
    }

    final isCompleted = task.progress >= 100;

    for (final userId in assigneeIds) {
      if (!stats.containsKey(userId)) {
        stats[userId] = {'active': 0, 'completed': 0, 'workload': 0};
      }

      if (isCompleted) {
        stats[userId]!['completed'] = (stats[userId]!['completed'] ?? 0) + 1;
      } else {
        stats[userId]!['active'] = (stats[userId]!['active'] ?? 0) + 1;
        // Workload logic: 10% per active task, max 100
        int currentWorkload = stats[userId]!['workload'] ?? 0;
        stats[userId]!['workload'] = (currentWorkload + 10).clamp(0, 100);
      }
    }
  }

  return stats;
});

/// Utility to get all reports (direct + indirect) for a manager
List<User> getReports(String managerId, List<User> allUsers) {
  final directReports =
      allUsers.where((u) => u.reportingManagerId == managerId).toList();
  List<User> allReports = [...directReports];
  for (final report in directReports) {
    allReports.addAll(getReports(report.id, allUsers));
  }
  return allReports;
}

/// Team members visible to current user based on role
final visibleTeamMembersProvider = Provider<List<User>>((ref) {
  final currentUserAsync = ref.watch(currentUserProvider);
  final allUsersAsync = ref.watch(allUsersProvider);

  return currentUserAsync.maybeWhen(
    data: (currentUser) {
      if (currentUser == null) return [];
      return allUsersAsync.maybeWhen(
        data: (allUsers) {
          switch (currentUser.role) {
            case 'ADMIN':
              return allUsers.where((u) => u.id != currentUser.id).toList();
            case 'MANAGER':
              return getReports(currentUser.id, allUsers);
            case 'TEAM_LEAD':
              return getReports(currentUser.id, allUsers);
            default:
              return []; // Employees can't see team
          }
        },
        orElse: () => [],
      );
    },
    orElse: () => [],
  );
});

// UserRole enum is now in src/core/constants/enums.dart
