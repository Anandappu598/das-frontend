import 'dart:convert';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project_pm/src/features/projects/project_providers.dart';
import 'package:project_pm/src/features/projects/providers/api_providers.dart';
import 'package:project_pm/src/core/models/project_with_tasks.dart';
import 'package:project_pm/src/core/models/milestone.dart';

@RoutePage()
class ProjectPlanPage extends HookConsumerWidget {
  const ProjectPlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(currentProjectProvider);

    return projectAsync.when(
      data: (data) {
        if (data == null) {
          return const Scaffold(body: Center(child: Text("Project not found")));
        }
        return _ProjectPlanView(project: data);
      },
      error: (err, st) => Scaffold(body: Center(child: Text("Error: $err"))),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class _ProjectPlanView extends HookConsumerWidget {
  final ProjectWithTasks project;
  const _ProjectPlanView({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sortedTasks = [...project.tasks]
      ..sort((a, b) => a.task.startDate.compareTo(b.task.startDate));

    // Closure Logic
    final isTasksDone = project.tasks.isNotEmpty &&
        project.tasks.every((t) => t.task.progress >= 100);
    final isFormallyClosed = project.project.status == 'archived' ||
        project.project.status == 'completed';
    final isPendingClosure =
        project.project.approvalStatus == 'pending_completion';
    final canClose = isTasksDone && !isFormallyClosed && !isPendingClosure;

    return Scaffold(
      floatingActionButton: canClose
          ? FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Request Project Closure'),
                    content: Text(
                      'All tasks are complete. Do you want to request closure for "${project.project.name}"?',
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
                              .requestProjectClosure(project.project.id);
                          ScaffoldMessenger.of(context).showSnackBar(
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
              icon: const Icon(Icons.check_circle_outline),
              label: const Text("Request Closure"),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            )
          : null,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.project.name,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey.shade900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Viewing details for ${project.project.name}",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPendingClosure)
                    _buildStatusBadge(
                        "Closure Pending", Colors.orange, Icons.hourglass_empty)
                  else if (isFormallyClosed)
                    _buildStatusBadge(
                        "Closed", Colors.green, Icons.check_circle),
                ],
              ),
              const SizedBox(height: 32),

              // Task List
              if (sortedTasks.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      "No tasks planned yet.",
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                )
              else
                ...sortedTasks.map((taskItem) {
                  return _buildTaskCard(context, ref, taskItem, isDark);
                }),
              const SizedBox(height: 80), // Fab space
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, WidgetRef ref,
      TaskWithAssignees taskItem, bool isDark) {
    final task = taskItem.task;
    List<Milestone> milestones = [];
    try {
      final List<dynamic> json =
          jsonDecode(task.milestonesJson) as List<dynamic>;
      milestones = json
          .map((j) => Milestone.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // ignore
    }

    // Plan: Green for progress (always), Blue for checks
    // We use a nice Green for the bar, and Blue for the checkboxes
    const progressBarColor = Color(0xFF22C55E);
    const checkboxColor = Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                    ),
                    Icon(Icons.calendar_today_outlined,
                        size: 16, color: Colors.grey.shade400),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(task.endDate),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "${task.progress}%",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Thick Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: task.progress / 100.0,
                    minHeight: 8,
                    backgroundColor:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    color: progressBarColor,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          if (milestones.isNotEmpty)
            Divider(
                height: 1,
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),

          // Milestones List
          if (milestones.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: milestones.map((m) {
                  return InkWell(
                    onTap: () {
                      _toggleMilestone(context, ref, task, milestones, m);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: m.completed,
                              activeColor: checkboxColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) {
                                _toggleMilestone(
                                    context, ref, task, milestones, m);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              m.name,
                              style: TextStyle(
                                fontSize: 14,
                                color: m.completed
                                    ? Colors.grey.shade400
                                    : (isDark
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade700),
                                decoration: m.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          Text(
                            "${m.weight}%",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
          else
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text("No milestones defined.",
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 13))
                ]))
        ],
      ),
    );
  }

  void _toggleMilestone(BuildContext context, WidgetRef ref, dynamic task,
      List<Milestone> milestones, Milestone m) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Updating milestone...'),
            ],
          ),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.blue,
        ),
      );

      // Extract subtask ID from milestone ID (format: "milestone_123")
      final subtaskId = int.tryParse(m.id.replaceFirst('milestone_', ''));

      if (subtaskId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid milestone ID'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Call API to toggle subtask completion
      final apiService = ref.read(taskApiServiceProvider);
      final response = await apiService.toggleSubtaskCompletion(subtaskId);

      // Extract updated subtask and progress from response
      final updatedSubtask = response['subtask'];
      final newProgress = response['parent_task_progress'] as int;

      print('✓ Subtask toggled. New task progress: $newProgress');
      print('✓ Updated subtask status: ${updatedSubtask['status']}');

      // Update local milestones for immediate UI feedback
      final updatedMilestones = milestones.map((item) {
        if (item.id == m.id) {
          return Milestone(
            id: item.id,
            name: item.name,
            completed: updatedSubtask['status'] == 'DONE',
            weight: item.weight,
          );
        }
        return item;
      }).toList();

      // Try to update local database (non-critical)
      try {
        await ref.read(projectRepositoryProvider).updateTaskMilestones(
            task.id, updatedMilestones,
            progressFromBackend: newProgress);
      } catch (dbError) {
        print('Local DB update failed (non-critical): $dbError');
      }

      // Force refresh API providers to get updated data from backend immediately
      // Use refresh to force immediate refetch with await
      print('⟳ Refreshing API providers...');
      await ref.refresh(apiTasksProvider.future);
      await ref.refresh(apiProjectsProvider.future);

      // Invalidate dependent providers to trigger rebuild
      ref.invalidate(projectsWithTasksProvider);
      ref.invalidate(currentProjectProvider);
      print('✓ Providers refreshed successfully');

      // Show success feedback
      if (context.mounted) {
        // Clear any existing snackbars
        ScaffoldMessenger.of(context).clearSnackBars();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Milestone updated successfully - Progress: $newProgress%'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }

      // Check if all milestones are now complete
      final allComplete = updatedMilestones.every((m) => m.completed);
      if (!m.completed && allComplete) {
        // We just checked the last one
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Mark Task as Complete?"),
              content: const Text(
                  "All milestones for this task are now complete. Do you want to mark the entire task as complete?"),
              actions: <Widget>[
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text("Complete Task"),
                  onPressed: () {
                    ref
                        .read(projectRepositoryProvider)
                        .requestTaskCompletion(task.id);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('❌ Error toggling milestone: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update milestone: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    // Simple formatter to avoid intl dependency if not strictly needed or missing
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
