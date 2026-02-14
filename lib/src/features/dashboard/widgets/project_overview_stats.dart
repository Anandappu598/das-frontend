import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project_pm/src/core/models/project_with_tasks.dart';
import 'package:project_pm/src/features/projects/project_providers.dart';
import 'package:project_pm/src/routes/app_router.dart';

enum StatCategory { portfolio, timeline, completion, attention }

class ProjectOverviewStats extends ConsumerWidget {
  final List<ProjectWithTasks> projects;

  const ProjectOverviewStats({super.key, required this.projects});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Always show the cards, even with empty projects (display zeros)
    final totalProjects = projects.length;
    final activeProjects = projects.where((p) => p.isActive).length;
    final completedProjects = projects.where((p) => p.isCompleted).length;

    // Timeline calculation
    final now = DateTime.now();
    final overdueCount = projects
        .where((p) =>
            p.isActive &&
            p.tasks.any((t) => t.progress < 100 && t.endDate.isBefore(now)))
        .length;
    final onTrackCount = activeProjects - overdueCount;

    // Task Completion
    final allTasks = projects.expand((p) => p.tasks).toList();
    final totalTasks = allTasks.length;
    final completedTasks = allTasks.where((t) => t.progress == 100).length;

    // Attention
    final criticalCount = allTasks
        .where((t) =>
            t.task.priority == 'High' &&
            t.progress < 100 &&
            t.endDate.isBefore(now))
        .length;

    void showCategoryModal(StatCategory category) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => _StatsModal(
          category: category,
          projects: projects,
          onSelectProject: (projectId) {
            Navigator.of(ctx).pop();
            ref.read(selectedProjectIdProvider.notifier).state = projectId;
            context.router.navigate(const ProjectPlanRoute());
          },
        ),
      );
    }

    return Column(
      children: [
        LayoutBuilder(builder: (context, constraints) {
          int crossAxisCount = 1;
          if (constraints.maxWidth > 600) crossAxisCount = 2;
          if (constraints.maxWidth > 1000) crossAxisCount = 4;

          return GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _StatCard(
                title: "PROJECT PORTFOLIO",
                count: totalProjects,
                sub1: activeProjects,
                sub1Label: "Active",
                sub2: completedProjects,
                sub2Label: "Done",
                icon: FontAwesomeIcons.briefcase,
                color: Colors.blue,
                onTap: () => showCategoryModal(StatCategory.portfolio),
              ),
              _StatCard(
                title: "TIMELINE HEALTH",
                count: activeProjects,
                sub1: onTrackCount,
                sub1Label: "On Track",
                sub2: overdueCount,
                sub2Label: "Overdue",
                icon: FontAwesomeIcons.timeline,
                color: Colors.green,
                isSub2Alert: overdueCount > 0,
                onTap: () => showCategoryModal(StatCategory.timeline),
              ),
              _StatCard(
                title: "TASK EFFICIENCY",
                count: totalTasks,
                sub1: completedTasks,
                sub1Label: "Completed",
                sub2: totalTasks - completedTasks,
                sub2Label: "Pending",
                icon: FontAwesomeIcons.checkDouble,
                color: Colors.purple,
                onTap: () => showCategoryModal(StatCategory.completion),
              ),
              _StatCard(
                title: "CRITICAL ATTENTION",
                count: criticalCount,
                sub1: criticalCount,
                sub1Label: "Critical",
                sub2: 0,
                sub2Label: "Rejected",
                icon: FontAwesomeIcons.triangleExclamation,
                color: Colors.red,
                isSub1Alert: criticalCount > 0,
                onTap: () => showCategoryModal(StatCategory.attention),
              ),
            ],
          );
        }),
      ],
    );
  }
}

/// Modal dialog showing list of projects/tasks for a category
class _StatsModal extends StatelessWidget {
  final StatCategory category;
  final List<ProjectWithTasks> projects;
  final ValueChanged<String> onSelectProject;

  const _StatsModal({
    required this.category,
    required this.projects,
    required this.onSelectProject,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    String title;
    List<_ModalItem> items;

    switch (category) {
      case StatCategory.portfolio:
        title = "Project Portfolio";
        items = projects.map((p) {
          final isDone = p.isCompleted;
          return _ModalItem(
            id: p.project.id,
            name: p.project.name,
            subtext: "${p.tasks.length} tasks",
            statusText: isDone ? "Closed" : "Active",
            statusColor: isDone ? Colors.green : Colors.blue,
            isClickable: true,
          );
        }).toList();
        break;

      case StatCategory.timeline:
        title = "Timeline Health (Active Projects)";
        items = projects.where((p) => p.isActive).map((p) {
          final hasOverdue =
              p.tasks.any((t) => t.progress < 100 && t.endDate.isBefore(now));
          return _ModalItem(
            id: p.project.id,
            name: p.project.name,
            subtext: hasOverdue ? "Contains overdue tasks" : "On Schedule",
            statusText: hasOverdue ? "At Risk" : "On Track",
            statusColor: hasOverdue ? Colors.red : Colors.teal,
            isClickable: true,
          );
        }).toList();
        break;

      case StatCategory.completion:
        title = "Task Completion Status";
        items = [];
        for (final p in projects) {
          for (final t in p.tasks) {
            final isDone = t.progress == 100;
            items.add(_ModalItem(
              id: t.task.id,
              name: t.task.name,
              subtext: p.project.name,
              statusText: isDone ? "Done" : "${t.progress}%",
              statusColor: isDone ? Colors.green : Colors.grey,
              isClickable: false,
            ));
          }
        }
        break;

      case StatCategory.attention:
        title = "Critical Attention & Blockers";
        items = [];
        for (final p in projects) {
          for (final t in p.tasks) {
            if (t.task.priority == 'High' &&
                t.progress < 100 &&
                t.endDate.isBefore(now)) {
              items.add(_ModalItem(
                id: t.task.id,
                name: t.task.name,
                subtext: "${p.project.name} • Due ${_formatDate(t.endDate)}",
                statusText: "CRITICAL",
                statusColor: Colors.red,
                isClickable: false,
              ));
            }
          }
        }
        if (items.isEmpty) {
          items.add(_ModalItem(
            id: "empty",
            name: "No critical issues found",
            subtext: "Great job keeping things on track!",
            statusText: "Safe",
            statusColor: Colors.green,
            isClickable: false,
          ));
        }
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color:
                        isDark ? const Color(0xFF374151) : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: isDark ? const Color(0xFF1F2937) : Colors.grey.shade50,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "NAME",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Text(
                    "STATUS",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Items list
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF374151).withAlpha(80)
                      : Colors.grey.shade100,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return InkWell(
                    onTap: item.isClickable
                        ? () => onSelectProject(item.id)
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.subtext,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: item.statusColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.statusText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: item.statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.grey.shade50,
                border: Border(
                  top: BorderSide(
                    color:
                        isDark ? const Color(0xFF374151) : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Close"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return "${months[date.month - 1]} ${date.day}";
  }
}

class _ModalItem {
  final String id;
  final String name;
  final String subtext;
  final String statusText;
  final Color statusColor;
  final bool isClickable;

  _ModalItem({
    required this.id,
    required this.name,
    required this.subtext,
    required this.statusText,
    required this.statusColor,
    required this.isClickable,
  });
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final int sub1;
  final String sub1Label;
  final int sub2;
  final String sub2Label;
  final IconData icon;
  final Color color;
  final bool isSub1Alert;
  final bool isSub2Alert;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.count,
    required this.sub1,
    required this.sub1Label,
    required this.sub2,
    required this.sub2Label,
    required this.icon,
    required this.color,
    this.isSub1Alert = false,
    this.isSub2Alert = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor:
            isDark ? Colors.blue.withAlpha(20) : Colors.blue.withAlpha(10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                top: 0,
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(icon, size: 48, color: color),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        count.toString(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text("total",
                          style: TextStyle(
                              color:
                                  isDark ? Colors.grey.shade500 : Colors.grey,
                              fontSize: 12)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sub1.toString(),
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSub1Alert ? Colors.red : null)),
                          Text(sub1Label,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Container(
                          width: 1,
                          height: 24,
                          color: isDark
                              ? const Color(0xFF4B5563)
                              : Colors.grey.shade200),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(sub2.toString(),
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSub2Alert ? Colors.red : null)),
                          Text(sub2Label,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500)),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
