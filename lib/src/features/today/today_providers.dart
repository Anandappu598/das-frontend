import 'package:project_pm/src/core/models/daily_log_with_details.dart';
import 'package:project_pm/src/features/today/today_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:project_pm/src/core/database/database.dart';
import 'package:project_pm/src/core/providers/user_providers.dart';

part 'today_providers.g.dart';

@Riverpod(keepAlive: true)
Stream<DailyLogWithDetails?> todayLog(TodayLogRef ref) {
  final repository = ref.watch(todayRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  // Default to today
  return repository.watchDailyLog(DateTime.now(), userId);
}

@riverpod
Stream<Map<DateTime, List<PlannedItem>>> monthPlannedItems(
    MonthPlannedItemsRef ref, DateTime month) {
  final repository = ref.watch(todayRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  // Watch from first day of grid (needs calculation or just conservative range)
  // For simplicity, watch the whole month plus padding for grid
  final start =
      DateTime(month.year, month.month, 1).subtract(const Duration(days: 7));
  final end =
      DateTime(month.year, month.month + 1, 1).add(const Duration(days: 14));

  return repository.watchPlannedItemsForRange(start, end, userId);
}

@riverpod
Stream<Map<DateTime, List<PlannedItem>>> weekPlannedItems(
    WeekPlannedItemsRef ref, DateTime startOfWeek) {
  final repository = ref.watch(todayRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  final end = startOfWeek.add(const Duration(days: 7));
  return repository.watchPlannedItemsForRange(startOfWeek, end, userId);
}
