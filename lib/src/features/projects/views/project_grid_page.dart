import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:project_pm/src/features/projects/project_providers.dart';
import 'package:project_pm/src/core/database/database.dart';
import 'package:project_pm/src/core/models/project_with_tasks.dart';

@RoutePage()
class ProjectGridPage extends HookConsumerWidget {
  const ProjectGridPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(currentProjectProvider);

    return projectAsync.when(
      data: (data) {
        if (data == null) {
          return const Scaffold(
            body: Center(child: Text("Project not found")),
          );
        }
        return _ProjectGridView(project: data);
      },
      error: (err, st) => Scaffold(body: Center(child: Text("Error: $err"))),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class _ProjectGridView extends StatelessWidget {
  final ProjectWithTasks project;
  const _ProjectGridView({required this.project});

  @override
  Widget build(BuildContext context) {
    // Sort tasks by start date
    final sortedTasks = [...project.tasks]
      ..sort((a, b) => a.task.startDate.compareTo(b.task.startDate));

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
        body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 1000),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(theme.cardColor),
                headingRowHeight: 50,
                dataRowMinHeight: 60,
                dataRowMaxHeight: 60,
                columnSpacing: 24,
                horizontalMargin: 24,
                dividerThickness: 1,
                columns: const [
                  DataColumn(
                      label: Text("TASK NAME",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey))),
                  DataColumn(
                      label: Text("ASSIGNEES",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey))),
                  DataColumn(
                      label: Text("START DATE",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey))),
                  DataColumn(
                      label: Text("END DATE",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey))),
                  DataColumn(
                      label: Text("PROGRESS",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey))),
                  DataColumn(
                      label: Text("STATUS",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey))),
                ],
                rows: sortedTasks.map((t) {
                  final task = t.task;
                  return DataRow(cells: [
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(task.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        if (task.approvalStatus == 'pending_creation')
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.yellow.shade900.withAlpha(80)
                                    : Colors.yellow.shade100,
                                borderRadius: BorderRadius.circular(4)),
                            child: Text("NEW",
                                style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? Colors.yellow.shade300
                                        : Colors.yellow.shade800,
                                    fontWeight: FontWeight.bold)),
                          )
                      ],
                    )),
                    // Assignees column with avatars
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...t.assignees.take(3).map((a) => Container(
                              margin: const EdgeInsets.only(right: 4),
                              child: CircleAvatar(
                                radius: 14,
                                backgroundImage: a.avatarUrl.isNotEmpty
                                    ? NetworkImage(a.avatarUrl)
                                    : null,
                                backgroundColor: Colors.blue.shade100,
                                child: a.avatarUrl.isEmpty
                                    ? Text(a.name[0],
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade700))
                                    : null,
                              ),
                            )),
                        if (t.assignees.length > 3)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF374151)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+${t.assignees.length - 3}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                      ],
                    )),
                    DataCell(Text(DateFormat('MMM d').format(task.startDate),
                        style: const TextStyle(fontSize: 13))),
                    DataCell(Text(DateFormat('MMM d').format(task.endDate),
                        style: const TextStyle(fontSize: 13))),
                    DataCell(SizedBox(
                      width: 120,
                      child: Row(
                        children: [
                          Expanded(
                              child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                                value: task.progress / 100,
                                minHeight: 6,
                                backgroundColor: isDark
                                    ? const Color(0xFF374151)
                                    : Colors.grey.shade200,
                                color: task.progress >= 100
                                    ? Colors.green
                                    : Colors.blue),
                          )),
                          const SizedBox(width: 12),
                          Text("${task.progress.toInt()}%",
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
                    DataCell(_buildStatusBadge(task, isDark)),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildStatusBadge(Task task, bool isDark) {
    final today = DateTime.now();
    Color bg;
    Color text;
    String label;

    if (task.approvalStatus == 'pending_creation') {
      bg = isDark
          ? Colors.yellow.shade900.withAlpha(80)
          : Colors.yellow.shade100;
      text = isDark ? Colors.yellow.shade300 : Colors.yellow.shade800;
      label = "New / Pending";
    } else if (task.approvalStatus == 'pending_completion') {
      bg = isDark
          ? Colors.orange.shade900.withAlpha(80)
          : Colors.orange.shade100;
      text = isDark ? Colors.orange.shade300 : Colors.orange.shade800;
      label = "Awaiting Approval";
    } else if (task.approvalStatus == 'approved' && task.progress >= 100) {
      bg = isDark ? Colors.green.shade900.withAlpha(80) : Colors.green.shade100;
      text = isDark ? Colors.green.shade300 : Colors.green.shade800;
      label = "Verified";
    } else if (task.approvalStatus == 'rejected') {
      bg = isDark ? Colors.red.shade900.withAlpha(80) : Colors.red.shade100;
      text = isDark ? Colors.red.shade300 : Colors.red.shade800;
      label = "Rejected";
    } else if (task.progress < 100 && task.endDate.isBefore(today)) {
      final days = today.difference(task.endDate).inDays;
      bg = isDark ? Colors.red.shade900.withAlpha(80) : Colors.red.shade50;
      text = isDark ? Colors.red.shade300 : Colors.red;
      label = "Delayed (${days}d)";
    } else if (task.progress >= 100) {
      bg = isDark ? Colors.green.shade900.withAlpha(80) : Colors.green.shade100;
      text = isDark ? Colors.green.shade300 : Colors.green.shade800;
      label = "Completed";
    } else {
      bg = isDark ? Colors.blue.shade900.withAlpha(80) : Colors.blue.shade50;
      text = isDark ? Colors.blue.shade300 : Colors.blue.shade700;
      label = "In Progress";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: text, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
