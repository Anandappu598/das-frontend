import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project_pm/src/features/dashboard/dashboard_providers.dart';

class WorkStatisticsChart extends HookConsumerWidget {
  final String? selectedStatus;
  final Function(String?)? onStatusSelected;

  const WorkStatisticsChart({
    super.key,
    this.selectedStatus,
    this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersForStatsProvider);
    final statsAsync = ref.watch(projectWorkStatsProvider);
    final selectedUserId = ref.watch(selectedStatsUserIdProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error loading users: $error')),
      data: (users) {
        if (users.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'No users available for statistics',
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }

        // Auto-select first user if none selected
        if (selectedUserId == null && users.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedStatsUserIdProvider.notifier).state =
                users.first['id'] as int;
          });
        }

        return statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text('Error loading stats: $error')),
          data: (stats) => _buildChart(
              context, ref, users.cast<Map<String, dynamic>>(), stats),
        );
      },
    );
  }

  Widget _buildChart(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> users,
    Map<String, dynamic> stats,
  ) {
    final selectedUserId = ref.watch(selectedStatsUserIdProvider);
    final projects = stats['projects'] as List<dynamic>? ?? [];
    final overallPercentage = stats['overall_completion_percentage'] ?? 0;
    final totalTasks = stats['total_tasks'] ?? 0;
    final completedTasks = stats['completed_tasks'] ?? 0;
    // User data available at: stats['user'] as Map<String, dynamic>?

    // Define a palette for projects
    final List<Color> palette = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
    ];

    // Calculate project stats
    final Map<String, int> projectCounts = {};
    final Map<String, Color> projectColors = {};

    int colorIndex = 0;
    for (var project in projects) {
      final projectName = project['name'] as String;
      final taskCount = project['total_tasks'] as int;

      if (taskCount > 0) {
        projectCounts[projectName] = taskCount;
        projectColors[projectName] = palette[colorIndex % palette.length];
        colorIndex++;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Project Work Stats",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                // User Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedUserId,
                      hint: const Text('Select User'),
                      items: users.map((user) {
                        return DropdownMenuItem<int>(
                          value: user['id'] as int,
                          child: Row(
                            children: [
                              const Icon(Icons.person,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(user['name'] as String),
                              const SizedBox(width: 8),
                              Text(
                                '(${user['role_display']})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(selectedStatsUserIdProvider.notifier).state =
                              value;
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (projects.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text(
                    'No projects handled by this user',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              Column(
                children: [
                  // Overall completion percentage
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Overall Completion',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$overallPercentage%',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Completed: $completedTasks/$totalTasks tasks',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Projects: ${projects.length}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pie Chart
                  if (projectCounts.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: projectCounts.entries.map((entry) {
                            final percentage =
                                (entry.value / totalTasks * 100).round();
                            return PieChartSectionData(
                              color: projectColors[entry.key],
                              value: entry.value.toDouble(),
                              title: '$percentage%',
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Legend
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: projectCounts.entries.map((entry) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: projectColors[entry.key],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${entry.key} (${entry.value})',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Project Details Table
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Project Name',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Total',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Done',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Pending',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Progress',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Rows
                        ...projects.map((project) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(project['name'] as String),
                                ),
                                Expanded(
                                  child: Text(
                                    '${project['total_tasks']}',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${project['completed_tasks']}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${project['pending_tasks']}',
                                    textAlign: TextAlign.center,
                                    style:
                                        const TextStyle(color: Colors.orange),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${project['completion_percentage']}%',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
