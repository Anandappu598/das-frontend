import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project_pm/src/features/today/today_repository.dart';
import 'package:project_pm/src/features/today/widgets/task_config_modal.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:project_pm/src/core/database/database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:project_pm/src/features/today/widgets/add_activity_template_modal.dart';

import 'package:project_pm/src/features/projects/project_providers.dart';
import 'package:project_pm/src/core/models/project_with_tasks.dart';
import 'package:project_pm/src/shared/widgets/circular_progress.dart';
import 'package:project_pm/src/core/database/database_provider.dart';

class ActivityCatalog extends HookConsumerWidget {
  final String dailyLogId;
  const ActivityCatalog({super.key, required this.dailyLogId});

  static const Map<String, List<Map<String, dynamic>>> systemTemplates = {
    'Routine': [
      {
        'name': 'Coffee Break',
        'icon': FontAwesomeIcons.mugHot,
        'desc': 'Take a short break'
      },
      {
        'name': 'Lunch',
        'icon': FontAwesomeIcons.utensils,
        'desc': 'Lunch break'
      },
      {
        'name': 'Walk',
        'icon': FontAwesomeIcons.personWalking,
        'desc': 'Go for a walk'
      },
    ],
    'Education': [
      {
        'name': 'Learning',
        'icon': FontAwesomeIcons.graduationCap,
        'desc': 'Study new topic'
      },
      {'name': 'Reading', 'icon': FontAwesomeIcons.book, 'desc': 'Read a book'},
      {
        'name': 'Course',
        'icon': FontAwesomeIcons.chalkboardUser,
        'desc': 'Online course'
      },
    ],
    'Work': [
      {
        'name': 'Req. Gathering',
        'icon': FontAwesomeIcons.briefcase,
        'desc': 'Client requirements meeting'
      },
      {
        'name': 'Documentation',
        'icon': FontAwesomeIcons.fileLines,
        'desc': 'Update project docs'
      },
      {
        'name': 'Interview',
        'icon': FontAwesomeIcons.users,
        'desc': 'Candidate interview'
      },
    ],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectsAsync = ref.watch(projectsWithTasksProvider);
    final searchQuery = useState('');
    final selectedFilter = useState('All');
    final expandedCategory =
        useState<String?>('Project'); // Only one expanded at a time

    // Watch custom templates from database
    final db = ref.watch(databaseProvider);
    final customTemplatesStream = useMemoized(
      () => (db.select(db.activityTemplates)
            ..where((t) => t.status.equals('approved')))
          .watch(),
      [db],
    );
    final customTemplatesSnapshot = useStream(customTemplatesStream);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "ACTIVITY CATALOG",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Send Instruction Button removed

                        const SizedBox(width: 8),
                        // Add Template Button
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  const AddActivityTemplateModal(
                                existingCategories: [
                                  'Education',
                                  'Routine',
                                  'Work',
                                  'Health',
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, size: 20),
                          tooltip: "Add New Template",
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search
                TextField(
                  onChanged: (v) => searchQuery.value = v,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: Icon(Icons.search,
                        size: 18, color: Colors.grey.shade500),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF374151) : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF4B5563)
                            : Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF4B5563)
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),

          // Content - Scrollable with Expandable Categories
          Expanded(
            child: projectsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (projects) {
                final customTemplates = customTemplatesSnapshot.data ?? [];

                // Filter projects by search
                final filteredProjects = projects
                    .map((p) {
                      final filteredTasks = p.tasks.where((t) =>
                          t.progress < 100 &&
                          (searchQuery.value.isEmpty ||
                              t.task.name
                                  .toLowerCase()
                                  .contains(searchQuery.value.toLowerCase())));
                      return (
                        project: p,
                        filteredTasks: filteredTasks.toList()
                      );
                    })
                    .where((p) => p.filteredTasks.isNotEmpty)
                    .toList();

                // Group custom templates by category (case-insensitive)
                final templatesByCategory = <String, List<ActivityTemplate>>{};
                for (final t in customTemplates) {
                  final cat = t.category;
                  templatesByCategory.putIfAbsent(cat, () => []).add(t);
                }

                // Get all unique categories (system + custom)
                final allCategories = <String>{
                  'Education',
                  'Routine',
                  ...templatesByCategory.keys,
                };

                // Category icon/color mapping
                IconData getCategoryIcon(String category) {
                  switch (category.toLowerCase()) {
                    case 'education':
                      return FontAwesomeIcons.graduationCap;
                    case 'routine':
                      return FontAwesomeIcons.mugHot;
                    case 'work':
                      return FontAwesomeIcons.briefcase;
                    case 'health':
                      return FontAwesomeIcons.heartPulse;
                    case 'requirements':
                      return FontAwesomeIcons.clipboardList;
                    default:
                      return FontAwesomeIcons.folder;
                  }
                }

                Color getCategoryColor(String category) {
                  switch (category.toLowerCase()) {
                    case 'education':
                      return Colors.purple;
                    case 'routine':
                      return Colors.orange;
                    case 'work':
                      return Colors.blue;
                    case 'health':
                      return Colors.green;
                    case 'requirements':
                      return Colors.cyan;
                    default:
                      return Colors.teal;
                  }
                }

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      // Projects Category
                      if (selectedFilter.value == 'All' ||
                          selectedFilter.value == 'Project')
                        _ExpandableCategory(
                          title: 'Project',
                          icon: Icons.work,
                          iconColor: Colors.blue,
                          count: filteredProjects.fold(
                              0, (sum, p) => sum + p.filteredTasks.length),
                          isExpanded: expandedCategory.value == 'Project',
                          onTap: () {
                            expandedCategory.value =
                                expandedCategory.value == 'Project'
                                    ? null
                                    : 'Project';
                          },
                          isDark: isDark,
                          children: filteredProjects.expand((item) {
                            return item.filteredTasks
                                .map((task) => _ProjectTaskCard(
                                      project: item.project,
                                      task: task,
                                      dailyLogId: dailyLogId,
                                    ));
                          }).toList(),
                        ),

                      // Dynamic categories (Education, Routine, Requirements, etc.)
                      ...allCategories.map((category) {
                        // Filter logic
                        if (selectedFilter.value != 'All' &&
                            selectedFilter.value != category) {
                          return const SizedBox.shrink();
                        }
                        final systemItems = systemTemplates[category] ?? [];
                        final customItems = templatesByCategory[category] ?? [];
                        final totalCount =
                            systemItems.length + customItems.length;

                        // Skip empty categories
                        if (totalCount == 0) return const SizedBox.shrink();

                        return _ExpandableCategory(
                          title: category,
                          icon: getCategoryIcon(category),
                          iconColor: getCategoryColor(category),
                          count: totalCount,
                          isExpanded: expandedCategory.value == category,
                          onTap: () {
                            expandedCategory.value =
                                expandedCategory.value == category
                                    ? null
                                    : category;
                          },
                          isDark: isDark,
                          children: [
                            // System templates for this category
                            ...systemItems
                                .where((item) =>
                                    searchQuery.value.isEmpty ||
                                    (item['name'] as String)
                                        .toLowerCase()
                                        .contains(
                                            searchQuery.value.toLowerCase()))
                                .map((item) => _SystemTemplateCard(
                                      name: item['name'] as String,
                                      icon: item['icon'] as IconData,
                                      description:
                                          item['desc'] as String? ?? '',
                                      category: category,
                                      dailyLogId: dailyLogId,
                                    )),
                            // Custom templates for this category
                            ...customItems
                                .where((t) =>
                                    searchQuery.value.isEmpty ||
                                    t.name.toLowerCase().contains(
                                        searchQuery.value.toLowerCase()))
                                .map((template) => _CustomTemplateCard(
                                      template: template,
                                      dailyLogId: dailyLogId,
                                    )),
                          ],
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Expandable category section
class _ExpandableCategory extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final int count;
  final bool isExpanded;
  final VoidCallback onTap;
  final bool isDark;
  final List<Widget> children;

  const _ExpandableCategory({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.count,
    required this.isExpanded,
    required this.onTap,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF374151) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
        // Children
        if (isExpanded && children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4, bottom: 8),
            child: Column(children: children),
          ),
        const SizedBox(height: 4),
      ],
    );
  }
}

/// Card for project tasks with progress circle and dates
class _ProjectTaskCard extends ConsumerWidget {
  final ProjectWithTasks project;
  final TaskWithAssignees task;
  final String dailyLogId;

  const _ProjectTaskCard({
    required this.project,
    required this.task,
    required this.dailyLogId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskEnd =
        DateTime(task.endDate.year, task.endDate.month, task.endDate.day);

    // Date color logic
    Color taskDateColor;
    String taskDateText;
    if (taskEnd.isBefore(today)) {
      taskDateColor = Colors.red;
      taskDateText = _formatDate(task.endDate);
    } else if (taskEnd.isAtSameMomentAs(today)) {
      taskDateColor = Colors.orange;
      taskDateText = 'Today';
    } else {
      taskDateColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
      taskDateText = _formatDate(task.endDate);
    }

    final projectEnd = project.tasks
        .map((t) => t.endDate)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final dragData = {
      'source': 'catalog',
      'type': 'project_task',
      'name': task.task.name,
      'duration': 30, // Default duration since task duration is not available
      'relatedTaskId': task.task.id,
      'taskObject': task.task,
      'projectObject': project.project,
    };

    return Draggable<Map<String, dynamic>>(
      data: dragData,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        elevation: 6,
        shadowColor: Colors.black45,
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1F2937).withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Colors.blue.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.drag_indicator,
                      size: 14,
                      color: isDark ? Colors.grey : Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.task.name,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        decoration: TextDecoration.none, // Ensure no underline
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  project.project.name,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildCardContent(
              context, isDark, projectEnd, taskDateColor, taskDateText),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: () => _showConfigModal(context, ref),
          borderRadius: BorderRadius.circular(12),
          child: _buildCardContent(
              context, isDark, projectEnd, taskDateColor, taskDateText),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, bool isDark,
      DateTime projectEnd, Color taskDateColor, String taskDateText) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : Colors.grey.shade200,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: ColoredBox(color: Colors.blue.shade500),
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 18, top: 14, right: 14, bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        project.project.name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.drag_handle,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Task name
                Text(
                  task.task.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Dates and progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dates
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Task: ',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            Text(
                              taskDateText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: taskDateColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Prj: ',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            Text(
                              _formatDate(projectEnd),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Progress circle
                    CircularProgressWidget(
                      progress: task.progress,
                      size: 40,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showConfigModal(BuildContext context, WidgetRef ref) {
    debugPrint(
        'Opening TaskConfigModal for task: ${task.task.name}, project: ${project.project.name}');
    try {
      showDialog(
        context: context,
        builder: (ctx) => TaskConfigModal(
          projectWithTasks: project,
          taskWithAssignees: task,
          onConfirm: ({
            required String name,
            required int duration,
            String? description,
            List<String>? selectedMilestoneIds,
          }) async {
            try {
              final repo = ref.read(todayRepositoryProvider);
              await repo.addPlannedItem(
                dailyLogId,
                PlannedItemsCompanion.insert(
                  id: const Uuid().v4(),
                  dailyLogId: dailyLogId,
                  name: task.task.name,
                  description: drift.Value(description ?? ''),
                  durationMinutes: drift.Value(duration),
                  quadrant: const drift.Value('inbox'),
                  relatedTaskId: drift.Value(task.task.id),
                ),
              );
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to add task: $e')),
                );
              }
            }
          },
        ),
      );
    } catch (e, st) {
      debugPrint('Error showing generic modal: $e\n$st');
    }
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
    return '${months[date.month - 1]} ${date.day}';
  }
}

/// Card for system templates (Routine, Education)
class _SystemTemplateCard extends ConsumerWidget {
  final String name;
  final IconData icon;
  final String description;
  final String category;
  final String dailyLogId;

  const _SystemTemplateCard({
    required this.name,
    required this.icon,
    this.description = '',
    required this.category,
    required this.dailyLogId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dragData = {
      'source': 'catalog',
      'type': 'template',
      'name': name,
      'description': description,
      'duration': 30,
    };

    return Draggable<Map<String, dynamic>>(
      data: dragData,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        elevation: 6,
        shadowColor: Colors.black45,
        borderRadius: BorderRadius.circular(10),
        color: Colors.transparent,
        child: Container(
          width: 220,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF374151).withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: category == 'Routine'
                    ? Colors.orange.withValues(alpha: 0.5)
                    : Colors.purple.withValues(alpha: 0.5),
                width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: category == 'Routine'
                    ? const Color.fromARGB(255, 255, 153, 0)
                    : Colors.purple,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                    decoration: TextDecoration.none,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildContent(isDark),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () async {
            try {
              final repo = ref.read(todayRepositoryProvider);
              await repo.addPlannedItem(
                dailyLogId,
                PlannedItemsCompanion.insert(
                  id: const Uuid().v4(),
                  dailyLogId: dailyLogId,
                  name: name,
                  description: drift.Value(description),
                  durationMinutes: const drift.Value(30),
                  quadrant: const drift.Value('inbox'),
                ),
              );
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to add template: $e')),
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: _buildContent(isDark),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF4B5563) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: category == 'Routine' ? Colors.orange : Colors.purple,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.add_circle_outline,
            size: 18,
            color: Colors.blue.shade500,
          ),
        ],
      ),
    );
  }
}

/// Card for custom templates from database - matches system template style
class _CustomTemplateCard extends HookConsumerWidget {
  final ActivityTemplate template;
  final String dailyLogId;

  const _CustomTemplateCard({
    required this.template,
    required this.dailyLogId,
  });

  // Get icon based on category
  IconData _getCategoryIcon() {
    switch (template.category.toLowerCase()) {
      case 'education':
        return FontAwesomeIcons.graduationCap;
      case 'routine':
        return FontAwesomeIcons.mugHot;
      case 'work':
        return FontAwesomeIcons.briefcase;
      case 'health':
        return FontAwesomeIcons.heartPulse;
      default:
        return FontAwesomeIcons.star;
    }
  }

  // Get color based on category
  Color _getCategoryColor() {
    switch (template.category.toLowerCase()) {
      case 'education':
        return Colors.purple;
      case 'routine':
        return Colors.orange;
      case 'work':
        return Colors.blue;
      case 'health':
        return Colors.green;
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryIcon = _getCategoryIcon();
    final categoryColor = _getCategoryColor();

    return Draggable<Map<String, dynamic>>(
      data: {
        'source': 'catalog',
        'type': 'custom_template',
        'name': template.name,
        'description': template.description,
        'duration': template.defaultDuration,
        'category': template.category,
      },
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(10),
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.9,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF374151) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _getCategoryColor().withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  categoryIcon,
                  size: 16,
                  color: categoryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  template.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildContent(isDark, categoryIcon, categoryColor),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () async {
            try {
              final repo = ref.read(todayRepositoryProvider);
              await repo.addPlannedItem(
                dailyLogId,
                PlannedItemsCompanion.insert(
                  id: const Uuid().v4(),
                  dailyLogId: dailyLogId,
                  name: template.name,
                  description: drift.Value(template.description ?? ''),
                  durationMinutes: drift.Value(template.defaultDuration),
                  quadrant: const drift.Value('inbox'),
                ),
              );
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to add template: $e')),
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: _buildContent(isDark, categoryIcon, categoryColor),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF4B5563) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              template.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.add_circle_outline,
            size: 18,
            color: Colors.blue.shade500,
          ),
        ],
      ),
    );
  }
}
