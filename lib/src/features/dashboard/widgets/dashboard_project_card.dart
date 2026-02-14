import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:project_pm/src/core/models/project_with_tasks.dart';
import 'package:project_pm/src/shared/widgets/circular_progress.dart';
import 'package:project_pm/src/features/projects/project_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Since I don't know where CircularProgressWidget is exactly (it was used in dashboard_page without explicit import besides local ones),
// I'll check its definition in dashboard_page.dart or assume it's a common widget.
// Actually, I saw it used in dashboard_page.dart. I'll search for its definition.

class DashboardProjectCard extends HookConsumerWidget {
  final ProjectWithTasks project;
  final bool isDark;
  final VoidCallback? onTap;
  final bool isListView;

  const DashboardProjectCard({
    super.key,
    required this.project,
    required this.isDark,
    this.onTap,
    this.isListView = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = project.tasks;
    final totalProgress = tasks.isEmpty
        ? 0.0
        : tasks.fold<double>(0, (sum, t) => sum + t.task.progress) /
            tasks.length;
    final isFormallyClosed = project.project.status == 'archived' ||
        project.project.status == 'completed';
    final isPendingClosure =
        project.project.approvalStatus == 'pending_completion';
    // Tasks are done but project not closed
    final isTasksDone = totalProgress >= 100 && !isFormallyClosed;

    final criticalTasks = tasks
        .where((t) =>
            t.task.priority == "High" &&
            t.task.endDate.isBefore(DateTime.now()) &&
            t.task.progress < 100)
        .toList();
    final isCritical = criticalTasks.isNotEmpty;

    DateTime? projectEndDate;
    if (tasks.isNotEmpty) {
      projectEndDate = tasks
          .map((t) => t.task.endDate)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }

    final overdueDays =
        projectEndDate != null && projectEndDate.isBefore(DateTime.now())
            ? DateTime.now().difference(projectEndDate).inDays
            : 0;

    final borderColor = isDark ? const Color(0xFF374151) : Colors.grey.shade200;

    // Sort tasks: high priority first, then by progress
    final sortedTasks = [...tasks]..sort((a, b) {
        if (a.task.priority == "High" && b.task.priority != "High") return -1;
        if (a.task.priority != "High" && b.task.priority == "High") return 1;
        return a.task.progress.compareTo(b.task.progress);
      });

    return Container(
      width: 400,
      margin: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              children: [
                // ===== HEADER =====
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor)),
                    color: isDark
                        ? Colors.white.withAlpha(5)
                        : Colors.grey.shade50.withAlpha(150),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    project.project.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.grey.shade900,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isCritical)
                                  AnimatedBadge(
                                    label: "ATTENTION",
                                    color: Colors.red,
                                    isDark: isDark,
                                    animate: true,
                                  )
                                else if (isFormallyClosed)
                                  AnimatedBadge(
                                    label: "COMPLETED",
                                    color: Colors.green,
                                    isDark: isDark,
                                    icon: FontAwesomeIcons.circleCheck,
                                  )
                                else if (isPendingClosure)
                                  AnimatedBadge(
                                    label: "PENDING CLOSURE",
                                    color: Colors.orange,
                                    isDark: isDark,
                                    icon: FontAwesomeIcons.clock,
                                  )
                                else if (isTasksDone)
                                  AnimatedBadge(
                                    label: "TASKS DONE",
                                    color: Colors.teal,
                                    isDark: isDark,
                                    icon: FontAwesomeIcons.check,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  "${project.tasks.where((t) => t.progress < 100).length} active tasks",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                if (projectEndDate != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isFormallyClosed
                                          ? (isDark
                                              ? Colors.grey.shade800
                                              : Colors.grey.shade100)
                                          : (isCritical
                                              ? (isDark
                                                  ? Colors.red.shade900
                                                      .withAlpha(80)
                                                  : Colors.red.shade100)
                                              : (isDark
                                                  ? Colors.blue.shade900
                                                      .withAlpha(80)
                                                  : Colors.blue.shade100)),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isFormallyClosed
                                            ? (isDark
                                                ? Colors.grey.shade700
                                                : Colors.grey.shade300)
                                            : (isCritical
                                                ? Colors.red.shade300
                                                : Colors.blue.shade300),
                                      ),
                                    ),
                                    child: Text(
                                      isFormallyClosed
                                          ? "Closed"
                                          : "Due: ${_formatDate(projectEndDate)}",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isFormallyClosed
                                            ? (isDark
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600)
                                            : (isCritical
                                                ? Colors.red
                                                : Colors.blue),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      CircularProgressWidget(
                        progress: totalProgress,
                        size: 52,
                        strokeWidth: 5,
                        color: isFormallyClosed
                            ? Colors.green
                            : (isCritical ? Colors.red : null),
                      ),
                    ],
                  ),
                ),

                // ===== TASK GRID (Scrollable Body) =====
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isCritical && overdueDays > 0)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.red.shade900.withAlpha(60)
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? Colors.red.shade800
                                    : Colors.red.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(FontAwesomeIcons.circleExclamation,
                                    size: 12, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Critical Issues: Overdue by $overdueDays days.",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.red.shade200
                                          : Colors.red.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (sortedTasks.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                "No tasks yet.",
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: sortedTasks.map((taskItem) {
                              return SizedBox(
                                width: (MediaQuery.of(context).size.width > 800)
                                    ? 160
                                    : double.infinity,
                                child: TaskMiniCard(
                                  taskItem: taskItem,
                                  isDark: isDark,
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),

                // ===== FOOTER =====
                if (!isFormallyClosed && !isPendingClosure)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: borderColor)),
                      color: isDark
                          ? Colors.white.withAlpha(5)
                          : Colors.grey.shade50.withAlpha(150),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(11)),
                    ),
                    child: Row(
                      children: [
// Footer content modified to remove Add Task button
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Request Project Closure'),
                                content: Text(
                                  'Are you sure you want to request closure for "${project.project.name}"? This will send a request to Approvals.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      ref
                                          .read(projectRepositoryProvider)
                                          .requestProjectClosure(
                                              project.project.id);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Project closure requested. Pending approval.'),
                                          backgroundColor: Colors.blue,
                                        ),
                                      );
                                    },
                                    child: const Text('Request Closure'),
                                  ),
                                ],
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: isTasksDone
                                  ? Colors.green.withAlpha(20)
                                  : null, // Highlight if ready to close
                            ),
                            child: Row(
                              children: [
                                if (isTasksDone)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: Text(
                                      "Submit for Closure",
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green),
                                    ),
                                  ),
                                const Icon(FontAwesomeIcons.circleCheck,
                                    size: 14, color: Colors.green),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isPendingClosure)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.orange.shade900.withAlpha(30)
                          : Colors.orange.shade50,
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(11)),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hourglass_empty,
                              size: 14, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text(
                            "Closure Pending Approval",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.green.shade900.withAlpha(30)
                          : Colors.green.shade50,
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(11)),
                    ),
                    child: const Center(
                      child: Text(
                        "Project Archived",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
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

class AnimatedBadge extends StatefulWidget {
  final String label;
  final Color color;
  final bool isDark;
  final bool animate;
  final IconData? icon;

  const AnimatedBadge({
    super.key,
    required this.label,
    required this.color,
    required this.isDark,
    this.animate = false,
    this.icon,
  });

  @override
  State<AnimatedBadge> createState() => _AnimatedBadgeState();
}

class _AnimatedBadgeState extends State<AnimatedBadge>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _pulseController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticInOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _bounceController.repeat(reverse: true);
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: widget.isDark
            ? widget.color.withAlpha(40)
            : widget.color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.color.withAlpha(150)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.animate)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _pulseAnimation.value,
                  child: Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          if (widget.icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(widget.icon, size: 10, color: widget.color),
            ),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: widget.color,
            ),
          ),
        ],
      ),
    );

    if (widget.animate) {
      return AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _bounceAnimation.value),
            child: badge,
          );
        },
      );
    }
    return badge;
  }
}

class TaskMiniCard extends StatelessWidget {
  final TaskWithAssignees taskItem;
  final bool isDark;

  const TaskMiniCard({
    super.key,
    required this.taskItem,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final task = taskItem.task;
    final today = DateTime.now();
    final isOverdue = task.endDate.isBefore(today) && task.progress < 100;
    final isDueSoon =
        task.endDate.difference(today).inDays <= 3 && task.progress < 100;
    final isComplete = task.progress >= 100;

    Color cardBg;
    Color borderColor;

    if (isComplete) {
      cardBg =
          isDark ? Colors.grey.shade800.withAlpha(80) : Colors.grey.shade50;
      borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade200;
    } else if (isOverdue) {
      cardBg = isDark ? Colors.red.shade900.withAlpha(40) : Colors.red.shade50;
      borderColor = isDark ? Colors.red.shade800 : Colors.red.shade200;
    } else if (isDueSoon) {
      cardBg =
          isDark ? Colors.orange.shade900.withAlpha(40) : Colors.orange.shade50;
      borderColor = isDark ? Colors.orange.shade800 : Colors.orange.shade200;
    } else {
      cardBg = Theme.of(context).cardColor;
      borderColor = isDark ? const Color(0xFF374151) : Colors.grey.shade200;
    }

    Color priorityText;
    if (task.priority == "High") {
      priorityText = isDark ? Colors.red.shade300 : Colors.red.shade700;
    } else if (task.priority == "Medium") {
      priorityText = isDark ? Colors.yellow.shade300 : Colors.yellow.shade700;
    } else {
      priorityText = isDark ? Colors.blue.shade300 : Colors.blue.shade700;
    }

    return Container(
      height: 140,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                task.priority.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: priorityText,
                ),
              ),
              Text(
                _formatDate(task.endDate),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isOverdue
                      ? Colors.red
                      : (isDueSoon ? Colors.orange : Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              task.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isComplete
                    ? Colors.grey
                    : (isDark ? Colors.white : Colors.grey.shade900),
                decoration: isComplete ? TextDecoration.lineThrough : null,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: taskItem.assignees
                      .take(2)
                      .map((a) => CircleAvatar(
                            radius: 12,
                            backgroundImage: a.avatarUrl.isNotEmpty
                                ? NetworkImage(a.avatarUrl)
                                : null,
                            backgroundColor: Colors.blue.shade100,
                            child: a.avatarUrl.isEmpty
                                ? Text(a.name[0],
                                    style: const TextStyle(fontSize: 10))
                                : null,
                          ))
                      .toList(),
                ),
                CircularProgressWidget(
                  progress: task.progress.toDouble(),
                  size: 32,
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        ],
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
