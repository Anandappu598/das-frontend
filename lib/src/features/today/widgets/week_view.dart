import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:project_pm/src/features/today/today_providers.dart';
import 'package:project_pm/src/features/today/today_repository.dart';
import 'package:project_pm/src/core/database/database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import 'package:project_pm/src/features/today/widgets/task_config_modal.dart';

class WeekView extends HookConsumerWidget {
  final VoidCallback onToggleCatalog;

  const WeekView({
    super.key,
    required this.onToggleCatalog,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Current date logic
    final currentWeekStart = useState(_startOfWeek(DateTime.now()));

    // Helpers to navigate
    void prevWeek() {
      currentWeekStart.value =
          currentWeekStart.value.subtract(const Duration(days: 7));
    }

    void nextWeek() {
      currentWeekStart.value =
          currentWeekStart.value.add(const Duration(days: 7));
    }

    void goToToday() {
      currentWeekStart.value = _startOfWeek(DateTime.now());
    }

    // Data
    final weekItemsAsync =
        ref.watch(weekPlannedItemsProvider(currentWeekStart.value));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Formatting
    final weekEnd = currentWeekStart.value.add(const Duration(days: 4)); // Fri
    final dateRangeText =
        "${DateFormat('MMM d').format(currentWeekStart.value)} - ${DateFormat('MMM d, yyyy').format(weekEnd)}";

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              IconButton(
                onPressed: onToggleCatalog,
                icon: const Icon(Icons.menu),
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8), // Increased for separation from Menu
              IconButton(
                onPressed: prevWeek,
                icon: const Icon(Icons.chevron_left),
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 0), // Tight group
              OutlinedButton(
                onPressed: goToToday,
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  minimumSize: const Size(0, 32),
                  side: BorderSide(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4), // Square-ish
                  ),
                  foregroundColor: isDark ? Colors.white : Colors.grey.shade800,
                ),
                child: const Text(
                  "Today",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 0), // Tight group
              IconButton(
                onPressed: nextWeek,
                icon: const Icon(Icons.chevron_right),
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              Text(
                dateRangeText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.calendar_month,
                size: 18, // Slightly smaller to match text
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Week Grid
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time Labels Column
                SizedBox(
                  width: 60,
                  child: Column(
                    children: [
                      const SizedBox(height: 50), // Header spacer
                      ...List.generate(9, (index) {
                        final hour = 9 + index;
                        return SizedBox(
                          height: 100, // Matching row height
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Transform.translate(
                              offset: const Offset(0, -8),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  _formatHour(hour),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),

                // Days Columns
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final dayWidth = constraints.maxWidth / 5;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(5, (dayIndex) {
                          final dayDate = currentWeekStart.value
                              .add(Duration(days: dayIndex));
                          final isToday = _isSameDay(dayDate, DateTime.now());

                          final itemsForDay = weekItemsAsync.value?[DateTime(
                                  dayDate.year, dayDate.month, dayDate.day)] ??
                              [];

                          return SizedBox(
                            width: dayWidth,
                            height:
                                950, // Total height for 9 hours * 100px/hour + 50px header
                            child: Stack(
                              children: [
                                // Background Lines with headers
                                Column(
                                  children: [
                                    // Day Header
                                    Container(
                                      height: 50,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: isDark
                                                ? Colors.grey.shade800
                                                : Colors.grey.shade200,
                                          ),
                                          right: BorderSide(
                                            color: isDark
                                                ? Colors.grey.shade800
                                                : Colors.grey.shade200,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            DateFormat('EEE')
                                                .format(dayDate)
                                                .toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isToday
                                                  ? Colors.blue
                                                  : Colors.grey.shade500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            dayDate.day.toString(),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isToday
                                                  ? Colors.blue
                                                  : (isDark
                                                      ? Colors.white
                                                      : Colors.black87),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Hour slots (Droppable)
                                    ...List.generate(9, (index) {
                                      final hour = 9 + index;
                                      return GestureDetector(
                                        onTap: () {
                                          // Quick-add dialog for tapping on empty slot
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => TaskConfigModal(
                                              onConfirm: ({
                                                required String name,
                                                required int duration,
                                                String? description,
                                                List<String>?
                                                    selectedMilestoneIds,
                                              }) async {
                                                final dropTime = DateTime(
                                                  dayDate.year,
                                                  dayDate.month,
                                                  dayDate.day,
                                                  hour,
                                                  0,
                                                );
                                                final repo = ref.read(
                                                    todayRepositoryProvider);
                                                final logId = await repo
                                                    .ensureDailyLogExists(
                                                        dayDate, 'u1');
                                                await repo.addPlannedItem(
                                                  logId,
                                                  PlannedItemsCompanion(
                                                    id: drift.Value(
                                                        const Uuid().v4()),
                                                    dailyLogId:
                                                        drift.Value(logId),
                                                    name: drift.Value(name),
                                                    description: drift.Value(
                                                        description ?? ''),
                                                    durationMinutes:
                                                        drift.Value(duration),
                                                    startTime:
                                                        drift.Value(dropTime),
                                                    quadrant:
                                                        const drift.Value('q2'),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                        child: DragTarget<Map<String, dynamic>>(
                                          onWillAcceptWithDetails: (details) =>
                                              true,
                                          onAcceptWithDetails: (details) async {
                                            final data = details.data;
                                            final duration =
                                                data['duration'] as int? ?? 60;
                                            final name = data['name'] as String;
                                            const description =
                                                ''; // Default empty

                                            // Calculate drop time
                                            final dropTime = DateTime(
                                                dayDate.year,
                                                dayDate.month,
                                                dayDate.day,
                                                hour,
                                                0);

                                            final repo = ref
                                                .read(todayRepositoryProvider);
                                            final logId =
                                                await repo.ensureDailyLogExists(
                                                    dayDate, 'u1');

                                            await repo.addPlannedItem(
                                              logId,
                                              PlannedItemsCompanion(
                                                id: drift.Value(
                                                    const Uuid().v4()),
                                                dailyLogId: drift.Value(logId),
                                                name: drift.Value(name),
                                                description: const drift.Value(
                                                    description),
                                                durationMinutes:
                                                    drift.Value(duration),
                                                startTime:
                                                    drift.Value(dropTime),
                                                quadrant: const drift.Value(
                                                    'q2'), // Default
                                              ),
                                            );
                                          },
                                          builder: (context, candidateData,
                                              rejectedData) {
                                            return Container(
                                              height: 100,
                                              decoration: BoxDecoration(
                                                color: candidateData.isNotEmpty
                                                    ? Colors.blue.withAlpha(20)
                                                    : null,
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: isDark
                                                        ? Colors.grey.shade800
                                                        : Colors.grey.shade200,
                                                  ),
                                                  right: BorderSide(
                                                    color: isDark
                                                        ? Colors.grey.shade800
                                                        : Colors.grey.shade200,
                                                  ),
                                                ),
                                              ),
                                              child: candidateData.isNotEmpty
                                                  ? Center(
                                                      child: Icon(
                                                        Icons
                                                            .add_circle_outline,
                                                        color: Colors.blue
                                                            .withAlpha(100),
                                                      ),
                                                    )
                                                  : null,
                                            );
                                          },
                                        ),
                                      );
                                    }),
                                  ],
                                ),

                                // Events
                                ...itemsForDay.map((item) {
                                  // Calculate position based on startTime
                                  // default to 9AM if null
                                  final start = item.startTime ??
                                      DateTime(dayDate.year, dayDate.month,
                                          dayDate.day, 9, 0);

                                  // Calculate offset from 9 AM
                                  // Grid starts at 9 AM.
                                  // If starts before 9 AM, we might clamp or show at top?
                                  // Let's assume 9 AM - 6 PM grid for now.

                                  int startHour = start.hour;
                                  if (startHour < 9) {
                                    startHour = 9; // Clamp visually
                                  }

                                  final minutesFrom9 =
                                      (startHour - 9) * 60 + start.minute;
                                  const pixelsPerMinute = 100.0 / 60.0;
                                  final topOffset =
                                      50.0 + (minutesFrom9 * pixelsPerMinute);

                                  final height =
                                      (item.durationMinutes * pixelsPerMinute);

                                  return Positioned(
                                    top: topOffset,
                                    left: 2,
                                    right: 2,
                                    height: height,
                                    child: _EventCard(
                                      item: item,
                                      isDark: isDark,
                                      dayDate: dayDate,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DateTime _startOfWeek(DateTime date) {
    // Find monday
    return date.subtract(Duration(days: date.weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatHour(int hour) {
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : hour;
    return '$h $amPm';
  }
}

class _EventCard extends ConsumerWidget {
  final PlannedItem item;
  final bool isDark;
  final DateTime dayDate;

  const _EventCard({
    required this.item,
    required this.isDark,
    required this.dayDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        // Show edit dialog for event
        showDialog(
          context: context,
          builder: (ctx) => TaskConfigModal(
            plannedItem: item,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E3A8A) : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? Colors.blue.shade800 : Colors.blue.shade100,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.blue.shade100 : Colors.blue.shade900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                item.description,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const Spacer(),
            Text(
              "${(item.durationMinutes / 60).toStringAsFixed(1).replaceAll('.0', '')}h",
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.blue.shade300 : Colors.blue.shade400,
              ),
            )
          ],
        ),
      ),
    );
  }
}
