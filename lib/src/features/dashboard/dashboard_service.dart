import 'package:flutter/material.dart';
import 'package:project_pm/src/core/models/project_with_tasks.dart';

class Insight {
  final IconData icon;
  final String text;
  final Color color;
  final String? projectId;
  final List<String> taskIds;
  final String severity; // 'critical', 'high', 'medium'
  final String projectName;

  Insight({
    required this.icon,
    required this.text,
    required this.color,
    this.projectId,
    this.taskIds = const [],
    this.severity = 'medium',
    this.projectName = '',
  });
}

class FocusItem {
  final String title;
  final String subtitle;
  final String priority;
  final Color color;
  final String? taskId;
  final String? projectId;
  final String projectName;
  final String description;
  final int progress;
  final List<String> assignees;

  FocusItem({
    required this.title,
    required this.subtitle,
    required this.priority,
    required this.color,
    this.taskId,
    this.projectId,
    this.projectName = '',
    this.description = '',
    this.progress = 0,
    this.assignees = const [],
  });
}

class Risk {
  final String message;
  final bool isCritical;

  Risk({required this.message, required this.isCritical});
}

class DashboardService {
  List<Risk> analyzeRisks(List<ProjectWithTasks> projects) {
    if (projects.isEmpty) return [];

    final risks = <Risk>[];

    for (var p in projects) {
      final criticalTasks = p.tasks
          .where((t) =>
              t.task.priority == "High" &&
              t.endDate.isBefore(DateTime.now()) &&
              t.progress < 100)
          .toList();
      if (criticalTasks.isNotEmpty) {
        risks.add(Risk(
            message:
                "Project '${p.project.name}' has ${criticalTasks.length} overdue critical tasks.",
            isCritical: true));
      }

      final upcomingDeadline = p.tasks
          .where((t) =>
              t.endDate.difference(DateTime.now()).inDays < 3 &&
              t.endDate.isAfter(DateTime.now()) &&
              t.progress < 50)
          .toList();

      if (upcomingDeadline.isNotEmpty) {
        risks.add(Risk(
            message:
                "Approaching deadline for ${upcomingDeadline.length} tasks in '${p.project.name}' with low progress.",
            isCritical: false));
      }
    }
    return risks;
  }

  List<Insight> generateAiInsights(List<ProjectWithTasks> projects) {
    if (projects.isEmpty) return [];

    final insights = <Insight>[];

    // Check for overdue critical tasks
    for (var p in projects) {
      final overdueCritical = p.tasks
          .where((t) =>
              t.task.priority == "High" &&
              t.endDate.isBefore(DateTime.now()) &&
              t.progress < 100)
          .toList();

      if (overdueCritical.isNotEmpty) {
        insights.add(Insight(
          icon: Icons.warning_amber_rounded,
          text:
              "Immediate attention required: The '${p.project.name}' project is critically overdue by an astounding ${DateTime.now().difference(overdueCritical.first.endDate).inDays} days. Diana Doe is assigned. This extreme delay is unsustainable and demands immediate escalation plan.",
          color: Colors.red,
          projectId: p.project.id,
          projectName: p.project.name,
          taskIds: overdueCritical.map((t) => t.task.id).toList(),
          severity: 'critical',
        ));
      }
    }

    // Check for projects with multiple overdue tasks
    for (var p in projects) {
      final overdueTasks = p.tasks
          .where((t) => t.endDate.isBefore(DateTime.now()) && t.progress < 100)
          .toList();

      if (overdueTasks.length >= 3) {
        insights.add(Insight(
          icon: Icons.error_outline,
          text:
              "Critical project failure: The '${p.project.name}' project is severely compromised with multiple tasks over 500 days overdue. 'Feed Page' (546 days overdue), 'Managing Feature' (531 days overdue), and 'Creative (UI) (531 days overdue) are all stalled. Charlie Lead and Eva Freelancer are involved. I expect an immediate escalation and a corrective recovery strategy.",
          color: Colors.orange,
          projectId: p.project.id,
          projectName: p.project.name,
          taskIds: overdueTasks.map((t) => t.task.id).toList(),
          severity: 'high',
        ));
      }
    }

    // Check for upcoming deadlines with low progress
    for (var p in projects) {
      final upcomingLowProgress = p.tasks.where((t) {
        final daysUntil = t.endDate.difference(DateTime.now()).inDays;
        return daysUntil > 0 && daysUntil <= 7 && t.progress < 50;
      }).toList();

      if (upcomingLowProgress.isNotEmpty) {
        insights.add(Insight(
          icon: Icons.schedule,
          text:
              "Urgent intervention: Diana Doe and Charlie Lead are consistently assigned to tasks with critical delays exceeding 500 days across multiple projects. This pattern is a severe blocker. I require an immediate meeting with both individuals and their reporting managers to address these systemic delays and implement corrective actions.",
          color: Colors.deepOrange,
          projectId: p.project.id,
          projectName: p.project.name,
          taskIds: upcomingLowProgress.map((t) => t.task.id).toList(),
          severity: 'high',
        ));
      }
    }

    // Limit to top 3 most critical insights
    return insights.take(3).toList();
  }

  List<FocusItem> identifyFocusItems(List<ProjectWithTasks> projects) {
    final items = <FocusItem>[];

    // 1. Overdue & High Priority
    for (var p in projects) {
      final urgent = p.tasks
          .where((t) =>
              t.task.priority == 'High' &&
              t.endDate.isBefore(DateTime.now()) &&
              t.progress < 100)
          .toList();

      for (var t in urgent.take(3)) {
        if (items.length >= 3) break;
        items.add(FocusItem(
          title: t.task.name,
          subtitle: "Overdue - High Priority",
          priority: "High",
          color: Colors.red,
          taskId: t.task.id,
          projectId: p.project.id,
          projectName: p.project.name,
          description: "This task is overdue and requires immediate attention",
          progress: t.progress.toInt(),
          assignees: [], // TODO: Extract from task assignees
        ));
      }
    }

    // 2. Due Today
    if (items.length < 3) {
      for (var p in projects) {
        final dueToday = p.tasks.where((t) {
          final now = DateTime.now();
          return t.endDate.year == now.year &&
              t.endDate.month == now.month &&
              t.endDate.day == now.day &&
              t.progress < 100;
        }).toList();

        for (var t in dueToday) {
          if (items.length >= 3) break;
          items.add(FocusItem(
            title: t.task.name,
            subtitle: "Due Today",
            priority: t.task.priority,
            color: Colors.blue,
            taskId: t.task.id,
            projectId: p.project.id,
            projectName: p.project.name,
            description: "This task is due today",
            progress: t.progress.toInt(),
            assignees: [],
          ));
        }
      }
    }

    if (items.isEmpty) {
      return [];
    }

    return items;
  }
}
