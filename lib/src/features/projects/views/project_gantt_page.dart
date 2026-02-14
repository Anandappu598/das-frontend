import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project_pm/src/features/projects/project_providers.dart';
import 'package:project_pm/src/core/models/project_with_tasks.dart';
import 'package:project_pm/src/features/projects/widgets/gantt_chart_painter.dart';
import 'package:project_pm/src/core/providers/user_providers.dart';
import 'package:project_pm/src/features/projects/modals/add_item_modal.dart';

@RoutePage()
class ProjectGanttPage extends HookConsumerWidget {
  const ProjectGanttPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(currentProjectProvider);

    return projectAsync.when(
      data: (data) {
        if (data == null) {
          return const Scaffold(body: Center(child: Text("Project not found")));
        }
        if (data.tasks.isEmpty) {
          // Even if empty, show the structure so user can add item
          return _GanttChartView(project: data);
        }
        return _GanttChartView(project: data);
      },
      error: (err, st) => Scaffold(body: Center(child: Text("Error: $err"))),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class _GanttChartView extends ConsumerStatefulWidget {
  final ProjectWithTasks project;
  const _GanttChartView({required this.project});

  @override
  ConsumerState<_GanttChartView> createState() => _GanttChartViewState();
}

class _GanttChartViewState extends ConsumerState<_GanttChartView> {
  final double dayWidth = 50.0; // Fixed width as per request

  void _showAddItemModal(BuildContext context, String projectId) {
    showDialog(
      context: context,
      builder: (context) =>
          AddItemModal(projectId: projectId), // Use custom modal
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if dark mode is enabled
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Calculate Timeline Range
    final tasks = widget.project.tasks.map((t) => t).toList();
    // if (tasks.isEmpty) return const SizedBox(); // Allow empty to show "Add Item"

    DateTime projectStart;
    DateTime projectEnd;

    // Use project start date from API if available
    if (widget.project.projectModel != null) {
      try {
        projectStart = DateTime.parse(widget.project.projectModel!.startDate);
      } catch (_) {
        projectStart = DateTime.now();
      }
    } else if (tasks.isEmpty) {
      projectStart = DateTime.now();
    } else {
      tasks.sort((a, b) => a.task.startDate.compareTo(b.task.startDate));
      projectStart = tasks.first.task.startDate;
    }

    // Calculate project end date from tasks or use project due date
    if (tasks.isEmpty) {
      if (widget.project.projectModel != null) {
        try {
          projectEnd = DateTime.parse(widget.project.projectModel!.dueDate)
              .add(const Duration(days: 2));
        } catch (_) {
          projectEnd = DateTime.now().add(const Duration(days: 14));
        }
      } else {
        projectEnd = DateTime.now().add(const Duration(days: 14));
      }
    } else {
      projectEnd = tasks
          .fold(tasks.first.task.endDate,
              (prev, t) => t.task.endDate.isAfter(prev) ? t.task.endDate : prev)
          .add(const Duration(days: 2));
    }

    // Ensure minimal range
    if (projectEnd.difference(projectStart).inDays < 7) {
      projectEnd = projectStart.add(const Duration(days: 7));
    }

    // Calculate working days (excluding Sundays)
    int countWorkingDays(DateTime start, DateTime end) {
      int count = 0;
      for (var date = start;
          date.isBefore(end) || date.isAtSameMomentAs(end);
          date = date.add(const Duration(days: 1))) {
        if (date.weekday != DateTime.sunday) {
          count++;
        }
      }
      return count;
    }

    final totalDays = countWorkingDays(projectStart, projectEnd);

    const double rowHeight = 40.0;
    const double headerHeight = 50.0;
    const double taskNameWidth = 200.0;

    // Minimum height to fill screen roughly
    final minContentHeight = MediaQuery.of(context).size.height * 0.7;
    final calculatedHeight = headerHeight +
        (tasks.length * rowHeight) +
        100; // +100 for button space
    final totalHeight = calculatedHeight < minContentHeight
        ? minContentHeight
        : calculatedHeight;

    final totalWidth = taskNameWidth + (totalDays * dayWidth);

    return Scaffold(
      body: Column(
        children: [
          // Toolbar Removed as requested

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Stack(
                            children: [
                              CustomPaint(
                                size: Size(totalWidth, totalHeight),
                                painter: GanttChartPainter(
                                  tasks: tasks,
                                  projectStart: projectStart,
                                  projectEnd: projectEnd,
                                  dayWidth: dayWidth,
                                  rowHeight: rowHeight,
                                  headerHeight: headerHeight,
                                  taskNameWidth: taskNameWidth,
                                  isDark: isDark,
                                ),
                              ),
                              // Assignee Avatars Overflowing at the end of bars
                              ...tasks.asMap().entries.expand((entry) {
                                final i = entry.key;
                                final t = entry.value;
                                final task = t.task;
                                final y = headerHeight + (i * rowHeight);

                                // Calculate working day offset and duration (excluding Sundays)
                                int getWorkingDayOffset(
                                    DateTime start, DateTime target) {
                                  int count = 0;
                                  for (var date = start;
                                      date.isBefore(target);
                                      date =
                                          date.add(const Duration(days: 1))) {
                                    if (date.weekday != DateTime.sunday) {
                                      count++;
                                    }
                                  }
                                  return count;
                                }

                                int countWorkingDaysDuration(
                                    DateTime start, DateTime end) {
                                  int count = 0;
                                  for (var date = start;
                                      date.isBefore(end) ||
                                          date.isAtSameMomentAs(end);
                                      date =
                                          date.add(const Duration(days: 1))) {
                                    if (date.weekday != DateTime.sunday) {
                                      count++;
                                    }
                                  }
                                  return count;
                                }

                                final startOffset = getWorkingDayOffset(
                                    projectStart, task.startDate);
                                final duration = countWorkingDaysDuration(
                                    task.startDate, task.endDate);

                                final barX =
                                    taskNameWidth + (startOffset * dayWidth);
                                final barWidth = duration * dayWidth;

                                // Position avatars at the end of the bar, offsetting if multiple
                                return t.assignees.asMap().entries.map((entry) {
                                  final assigneeIdx = entry.key;
                                  final a = entry.value;
                                  return Positioned(
                                    left: barX +
                                        barWidth -
                                        15 -
                                        (assigneeIdx * 10),
                                    top: y + (rowHeight - 24) / 2,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          // Impersonate / View Dashboard Logic
                                          final currentId =
                                              ref.read(currentUserIdProvider);
                                          ref
                                              .read(
                                                  impersonatingFromUserIdProvider
                                                      .notifier)
                                              .state = currentId;
                                          ref
                                              .read(currentUserIdProvider
                                                  .notifier)
                                              .state = a.id;
                                          context.router
                                              .navigateNamed('/app/dashboard');
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white, width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  blurRadius: 4)
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            radius: 12,
                                            backgroundImage:
                                                a.avatarUrl.isNotEmpty
                                                    ? NetworkImage(a.avatarUrl)
                                                    : null,
                                            backgroundColor:
                                                Colors.blue.shade100,
                                            child: a.avatarUrl.isEmpty
                                                ? Text(a.name[0],
                                                    style: const TextStyle(
                                                        fontSize: 10))
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                });
                              }),
                            ],
                          ),
                        ),
                        // Add Item Button
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 16.0, top: 12.0, bottom: 24.0),
                          child: InkWell(
                            onTap: () => _showAddItemModal(
                                context, widget.project.project.id),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add,
                                    color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "Add Item",
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
