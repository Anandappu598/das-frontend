import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project_pm/src/features/projects/project_providers.dart';
import 'package:project_pm/src/core/models/project_with_tasks.dart';
import 'package:project_pm/src/features/projects/widgets/gantt_chart_painter.dart';

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
          return const Scaffold(
              body: Center(child: Text("No tasks in this project yet.")));
        }
        return _GanttChartView(project: data);
      },
      error: (err, st) => Scaffold(body: Center(child: Text("Error: $err"))),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class _GanttChartView extends StatefulWidget {
  final ProjectWithTasks project;
  const _GanttChartView({required this.project});

  @override
  State<_GanttChartView> createState() => _GanttChartViewState();
}

class _GanttChartViewState extends State<_GanttChartView> {
  double dayWidth = 50.0;

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Timeline Range
    final tasks = widget.project.tasks.map((t) => t).toList();
    if (tasks.isEmpty) return const SizedBox();

    tasks.sort((a, b) => a.task.startDate.compareTo(b.task.startDate));

    final projectStart = tasks.first.task.startDate;
    final projectEnd = tasks
        .fold(tasks.first.task.endDate,
            (prev, t) => t.task.endDate.isAfter(prev) ? t.task.endDate : prev)
        .add(const Duration(days: 2));

    final totalDays = projectEnd.difference(projectStart).inDays + 1;

    const double rowHeight = 40.0;
    const double headerHeight = 50.0;
    const double taskNameWidth = 200.0;

    final totalHeight = headerHeight + (tasks.length * rowHeight);
    final totalWidth = taskNameWidth + (totalDays * dayWidth);

    return Scaffold(
      body: Column(
        children: [
          // Toolbar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text("Zoom: ",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                SegmentedButton<double>(
                  segments: const [
                    ButtonSegment(value: 30.0, label: Text("Compact")),
                    ButtonSegment(value: 50.0, label: Text("Day")),
                    ButtonSegment(value: 100.0, label: Text("Wide")),
                  ],
                  selected: {dayWidth},
                  onSelectionChanged: (Set<double> newSelection) {
                    setState(() {
                      dayWidth = newSelection.first;
                    });
                  },
                )
              ],
            ),
          ),
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
                                ),
                              ),
                              // Assignee Avatars Overflowing at the end of bars
                              ...tasks.asMap().entries.expand((entry) {
                                final i = entry.key;
                                final t = entry.value;
                                final task = t.task;
                                final y = headerHeight + (i * rowHeight);
                                final startOffset = task.startDate
                                    .difference(projectStart)
                                    .inDays;
                                final duration = task.endDate
                                        .difference(task.startDate)
                                        .inDays +
                                    1;

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
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 4)
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundImage: a.avatarUrl.isNotEmpty
                                            ? NetworkImage(a.avatarUrl)
                                            : null,
                                        backgroundColor: Colors.blue.shade100,
                                        child: a.avatarUrl.isEmpty
                                            ? Text(a.name[0],
                                                style: const TextStyle(
                                                    fontSize: 10))
                                            : null,
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
                            onTap: () {
                              // ScaffoldMessenger.of(context).showSnackBar(
                              //     const SnackBar(content: Text("Add Item clicked")));
                              // Logic to add item would go here
                            },
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
