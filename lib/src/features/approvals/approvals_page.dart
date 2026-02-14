import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:project_pm/src/core/database/database.dart';
import 'package:project_pm/src/core/database/database_provider.dart';
import 'package:project_pm/src/features/projects/project_providers.dart';

@RoutePage()
class ApprovalsPage extends HookConsumerWidget {
  const ApprovalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 5);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.grey.shade50,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              border: Border(
                bottom: BorderSide(
                    color:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Approvals Center',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review and authorize pending projects, tasks, templates, and completions.',
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              border: Border(
                bottom: BorderSide(
                    color:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade200),
              ),
            ),
            child: TabBar(
              controller: tabController,
              isScrollable: true,
              labelColor: Colors.blue.shade600,
              unselectedLabelColor:
                  isDark ? Colors.grey.shade400 : Colors.grey.shade500,
              indicatorColor: Colors.blue.shade600,
              tabs: [
                _buildTab(ref.watch(pendingProjectsProvider), 'New Projects'),
                _buildTab(ref.watch(pendingProjectClosuresProvider),
                    'Project Closures'),
                _buildTab(ref.watch(pendingNewTasksProvider), 'New Tasks'),
                _buildTab(ref.watch(pendingTaskCompletionsProvider),
                    'Task Completions'),
                _buildTemplateTab(
                    ref.watch(pendingTemplatesProvider), 'Templates'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                _PendingProjectsTab(isDark: isDark),
                _ProjectClosuresTab(isDark: isDark),
                _PendingTasksTab(isDark: isDark),
                _TaskCompletionsTab(isDark: isDark),
                _PendingTemplatesTab(isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(AsyncValue<List<dynamic>> asyncValue, String label) {
    final count = asyncValue.when(
      data: (list) => list.length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplateTab(
      AsyncValue<List<ActivityTemplate>> asyncValue, String label) {
    final count = asyncValue.when(
      data: (list) => list.length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ========== NEW PROJECTS TAB ==========
class _PendingProjectsTab extends ConsumerWidget {
  final bool isDark;

  const _PendingProjectsTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(pendingProjectsProvider);

    return projectsAsync.when(
      data: (projects) {
        if (projects.isEmpty) {
          return Center(
            child: Text(
              'No pending project requests.',
              style: TextStyle(
                  color: Colors.grey.shade400, fontStyle: FontStyle.italic),
            ),
          );
        }

        final repo = ref.read(projectRepositoryProvider);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return _ProjectCard(
              project: project,
              isDark: isDark,
              icon: Icons.create_new_folder,
              iconColor: Colors.blue,
              onApprove: () => repo.approveProject(project.id),
              onReject: () => repo.rejectProject(project.id),
              approveLabel: 'Approve',
              rejectLabel: 'Reject',
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }
}

// ========== PROJECT CLOSURES TAB ==========
class _ProjectClosuresTab extends ConsumerWidget {
  final bool isDark;

  const _ProjectClosuresTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(pendingProjectClosuresProvider);

    return projectsAsync.when(
      data: (projects) {
        if (projects.isEmpty) {
          return Center(
            child: Text(
              'No pending project closures.',
              style: TextStyle(
                  color: Colors.grey.shade400, fontStyle: FontStyle.italic),
            ),
          );
        }

        final repo = ref.read(projectRepositoryProvider);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return _ProjectCard(
              project: project,
              isDark: isDark,
              icon: Icons.work,
              iconColor: Colors.purple,
              borderColor: Colors.purple,
              onApprove: () => repo.approveProjectCompletion(project.id),
              onReject: () => repo.rejectProjectCompletion(project.id),
              approveLabel: 'Close Project',
              rejectLabel: 'Keep Open',
              approveColor: Colors.purple,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }
}

// ========== NEW TASKS TAB ==========
class _PendingTasksTab extends ConsumerWidget {
  final bool isDark;

  const _PendingTasksTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(pendingNewTasksProvider);

    return tasksAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              'No pending task creation requests.',
              style: TextStyle(
                  color: Colors.grey.shade400, fontStyle: FontStyle.italic),
            ),
          );
        }

        final repo = ref.read(projectRepositoryProvider);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _TaskCard(
              task: item.task,
              projectName: item.project.name,
              isDark: isDark,
              onApprove: () => repo.approveTask(item.task.id),
              onReject: () => repo.rejectTask(item.task.id),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }
}

// ========== TASK COMPLETIONS TAB ==========
class _TaskCompletionsTab extends ConsumerWidget {
  final bool isDark;

  const _TaskCompletionsTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(pendingTaskCompletionsProvider);

    return tasksAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              'No pending task completions.',
              style: TextStyle(
                  color: Colors.grey.shade400, fontStyle: FontStyle.italic),
            ),
          );
        }

        final repo = ref.read(projectRepositoryProvider);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _TaskCompletionCard(
              task: item.task,
              projectName: item.project.name,
              isDark: isDark,
              onApprove: () => repo.approveTaskCompletion(item.task.id),
              onReject: () => repo.rejectTaskCompletion(item.task.id),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }
}

// ========== REUSABLE CARDS ==========

class _ProjectCard extends StatelessWidget {
  final Project project;
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final Color? borderColor;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final String approveLabel;
  final String rejectLabel;
  final Color approveColor;

  const _ProjectCard({
    required this.project,
    required this.isDark,
    required this.icon,
    required this.iconColor,
    this.borderColor,
    required this.onApprove,
    required this.onReject,
    required this.approveLabel,
    required this.rejectLabel,
    this.approveColor = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF1F2937) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: borderColor ??
              (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
          width: borderColor != null ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 20, color: iconColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          project.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.grey.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    project.context.length > 200
                        ? '${project.context.substring(0, 200)}...'
                        : project.context,
                    style: TextStyle(
                      color:
                          isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close, size: 16),
                  label: Text(rejectLabel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(approveLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: approveColor,
                    foregroundColor: Colors.white,
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

class _TaskCard extends StatelessWidget {
  final Task task;
  final String projectName;
  final bool isDark;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _TaskCard({
    required this.task,
    required this.projectName,
    required this.isDark,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF1F2937) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          projectName.toUpperCase(),
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: task.priority == 'High'
                              ? Colors.red.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          task.priority,
                          style: TextStyle(
                            color: task.priority == 'High'
                                ? Colors.red.shade700
                                : Colors.grey.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade900,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onReject,
              icon: const Icon(Icons.cancel, color: Colors.red),
              tooltip: 'Reject',
            ),
            IconButton(
              onPressed: onApprove,
              icon: const Icon(Icons.check_circle, color: Colors.green),
              tooltip: 'Approve',
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCompletionCard extends StatelessWidget {
  final Task task;
  final String projectName;
  final bool isDark;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _TaskCompletionCard({
    required this.task,
    required this.projectName,
    required this.isDark,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF1F2937) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.green, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.checklist,
                          size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        projectName.toUpperCase(),
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade500,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Marked complete by team.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text('Revoke'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onApprove,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Done'),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== PENDING TEMPLATES TAB ==========
class _PendingTemplatesTab extends ConsumerWidget {
  final bool isDark;

  const _PendingTemplatesTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(pendingTemplatesProvider);

    return templatesAsync.when(
      data: (templates) {
        if (templates.isEmpty) {
          return Center(
            child: Text(
              'No pending template requests.',
              style: TextStyle(
                  color: Colors.grey.shade400, fontStyle: FontStyle.italic),
            ),
          );
        }

        final db = ref.read(databaseProvider);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            return _TemplateCard(
              template: template,
              isDark: isDark,
              onApprove: () async {
                await (db.update(db.activityTemplates)
                      ..where((t) => t.id.equals(template.id)))
                    .write(const ActivityTemplatesCompanion(
                  status: Value('approved'),
                ));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Template "${template.name}" approved'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              onReject: () async {
                await (db.update(db.activityTemplates)
                      ..where((t) => t.id.equals(template.id)))
                    .write(const ActivityTemplatesCompanion(
                  status: Value('rejected'),
                ));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Template "${template.name}" rejected'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final ActivityTemplate template;
  final bool isDark;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _TemplateCard({
    required this.template,
    required this.isDark,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF1F2937) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.orange.shade300,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.star, color: Colors.orange.shade500, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        template.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          template.category,
                          style: TextStyle(
                            color: Colors.teal.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (template.description != null &&
                      template.description!.isNotEmpty)
                    Text(
                      template.description!,
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Duration: ${template.defaultDuration} minutes',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
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
