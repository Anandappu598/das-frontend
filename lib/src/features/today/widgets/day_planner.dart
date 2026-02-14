import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project_pm/src/core/database/database.dart';
import 'package:project_pm/src/core/models/daily_log_with_details.dart';
import 'package:project_pm/src/features/today/today_repository.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import 'package:project_pm/src/features/today/widgets/task_config_modal.dart';
import 'package:project_pm/src/features/projects/providers/api_providers.dart';
import 'package:project_pm/src/features/today/today_providers.dart';

class DayPlanner extends HookConsumerWidget {
  final DailyLogWithDetails? dailyLogWithDetails;

  const DayPlanner({super.key, required this.dailyLogWithDetails});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (dailyLogWithDetails == null) {
      return const Center(child: Text("Loading Plan..."));
    }

    final plannedItems = dailyLogWithDetails!.plannedItems;
    final log = dailyLogWithDetails!.dailyLog;
    final isFinalized = log.isFinalized;

    // Watch API today plan data
    final apiTodayPlanAsync = ref.watch(apiTodayPlanProvider);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(isFinalized ? "Execution Mode" : "Daily Planner",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
              if (!isFinalized)
                apiTodayPlanAsync.when(
                  data: (apiItems) => ElevatedButton.icon(
                    onPressed: () {
                      if (plannedItems.isEmpty && apiItems.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "Please add items to your plan before starting the day."),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      ref.read(todayRepositoryProvider).finalizePlan(log.id);
                    },
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text("Start Day"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                  ),
                  loading: () => ElevatedButton.icon(
                    onPressed: () {
                      if (plannedItems.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "Please add items to your plan before starting the day."),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      ref.read(todayRepositoryProvider).finalizePlan(log.id);
                    },
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text("Start Day"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                  ),
                  error: (_, __) => ElevatedButton.icon(
                    onPressed: () {
                      if (plannedItems.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "Please add items to your plan before starting the day."),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      ref.read(todayRepositoryProvider).finalizePlan(log.id);
                    },
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text("Start Day"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                  ),
                )
            ],
          ),
        ),

        // Matrix - RESPONSIVE
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF4B5563)
                    : Colors.grey.shade300,
              ),
            ),
            child: apiTodayPlanAsync.when(
              data: (apiPlanItems) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _QuadrantBox(
                            quadrant: 'Q1',
                            title: 'Start First',
                            subtitle: 'Urgent & Important',
                            color: Colors.red,
                            items: plannedItems
                                .where((i) => i.quadrant == 'Q1')
                                .toList(),
                            apiItems: apiPlanItems
                                .where((i) => i['quadrant'] == 'Q1')
                                .toList(),
                            isFinalized: isFinalized,
                            logId: log.id,
                            isGrouped: true),
                      ),
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF4B5563)
                            : Colors.grey.shade300,
                      ),
                      Expanded(
                        child: _QuadrantBox(
                            quadrant: 'Q2',
                            title: 'Schedule',
                            subtitle: 'Important, Not Urgent',
                            color: Colors.blue,
                            items: plannedItems
                                .where((i) => i.quadrant == 'Q2')
                                .toList(),
                            apiItems: apiPlanItems
                                .where((i) => i['quadrant'] == 'Q2')
                                .toList(),
                            isFinalized: isFinalized,
                            logId: log.id,
                            isGrouped: true),
                      ),
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF4B5563)
                            : Colors.grey.shade300,
                      ),
                      Expanded(
                        child: _QuadrantBox(
                            quadrant: 'Q3',
                            title: 'Delegate',
                            subtitle: 'Urgent, Not Important',
                            color: Colors.orange,
                            items: plannedItems
                                .where((i) => i.quadrant == 'Q3')
                                .toList(),
                            apiItems: apiPlanItems
                                .where((i) => i['quadrant'] == 'Q3')
                                .toList(),
                            isFinalized: isFinalized,
                            logId: log.id,
                            isGrouped: true),
                      ),
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF4B5563)
                            : Colors.grey.shade300,
                      ),
                      Expanded(
                        child: _QuadrantBox(
                            quadrant: 'Q4',
                            title: 'Routine',
                            subtitle: 'Backlog & Breaks',
                            color: Colors.green,
                            items: plannedItems
                                .where((i) => i.quadrant == 'Q4')
                                .toList(),
                            apiItems: apiPlanItems
                                .where((i) => i['quadrant'] == 'Q4')
                                .toList(),
                            isFinalized: isFinalized,
                            logId: log.id,
                            isGrouped: true),
                      ),
                    ],
                  ),
                );
              },
              loading: () => IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _QuadrantBox(
                          quadrant: 'Q1',
                          title: 'Start First',
                          subtitle: 'Urgent & Important',
                          color: Colors.red,
                          items: plannedItems
                              .where((i) => i.quadrant == 'Q1')
                              .toList(),
                          apiItems: const [],
                          isFinalized: isFinalized,
                          logId: log.id,
                          isGrouped: true),
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF4B5563)
                          : Colors.grey.shade300,
                    ),
                    Expanded(
                      child: _QuadrantBox(
                          quadrant: 'Q2',
                          title: 'Schedule',
                          subtitle: 'Important, Not Urgent',
                          color: Colors.blue,
                          items: plannedItems
                              .where((i) => i.quadrant == 'Q2')
                              .toList(),
                          apiItems: const [],
                          isFinalized: isFinalized,
                          logId: log.id,
                          isGrouped: true),
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF4B5563)
                          : Colors.grey.shade300,
                    ),
                    Expanded(
                      child: _QuadrantBox(
                          quadrant: 'Q3',
                          title: 'Delegate',
                          subtitle: 'Urgent, Not Important',
                          color: Colors.orange,
                          items: plannedItems
                              .where((i) => i.quadrant == 'Q3')
                              .toList(),
                          apiItems: const [],
                          isFinalized: isFinalized,
                          logId: log.id,
                          isGrouped: true),
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF4B5563)
                          : Colors.grey.shade300,
                    ),
                    Expanded(
                      child: _QuadrantBox(
                          quadrant: 'Q4',
                          title: 'Routine',
                          subtitle: 'Backlog & Breaks',
                          color: Colors.green,
                          items: plannedItems
                              .where((i) => i.quadrant == 'Q4')
                              .toList(),
                          apiItems: const [],
                          isFinalized: isFinalized,
                          logId: log.id,
                          isGrouped: true),
                    ),
                  ],
                ),
              ),
              error: (error, stack) => IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _QuadrantBox(
                          quadrant: 'Q1',
                          title: 'Start First',
                          subtitle: 'Urgent & Important',
                          color: Colors.red,
                          items: plannedItems
                              .where((i) => i.quadrant == 'Q1')
                              .toList(),
                          apiItems: const [],
                          isFinalized: isFinalized,
                          logId: log.id,
                          isGrouped: true),
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF4B5563)
                          : Colors.grey.shade300,
                    ),
                    Expanded(
                      child: _QuadrantBox(
                          quadrant: 'Q2',
                          title: 'Schedule',
                          subtitle: 'Important, Not Urgent',
                          color: Colors.blue,
                          items: plannedItems
                              .where((i) => i.quadrant == 'Q2')
                              .toList(),
                          apiItems: const [],
                          isFinalized: isFinalized,
                          logId: log.id,
                          isGrouped: true),
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF4B5563)
                          : Colors.grey.shade300,
                    ),
                    Expanded(
                      child: _QuadrantBox(
                          quadrant: 'Q3',
                          title: 'Delegate',
                          subtitle: 'Urgent, Not Important',
                          color: Colors.orange,
                          items: plannedItems
                              .where((i) => i.quadrant == 'Q3')
                              .toList(),
                          apiItems: const [],
                          isFinalized: isFinalized,
                          logId: log.id,
                          isGrouped: true),
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF4B5563)
                          : Colors.grey.shade300,
                    ),
                    Expanded(
                      child: _QuadrantBox(
                          quadrant: 'Q4',
                          title: 'Routine',
                          subtitle: 'Backlog & Breaks',
                          color: Colors.green,
                          items: plannedItems
                              .where((i) => i.quadrant == 'Q4')
                              .toList(),
                          apiItems: const [],
                          isFinalized: isFinalized,
                          logId: log.id,
                          isGrouped: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Inbox / Unsorted
        if (!isFinalized) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: _InboxBox(
                items:
                    plannedItems.where((i) => i.quadrant == 'inbox').toList(),
                logId: log.id),
          )
        ],

        // Total Time Display
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: _TotalTimeDisplay(plannedItems: plannedItems),
        ),
      ],
    );
  }
}

/// Widget to display total planned time
class _TotalTimeDisplay extends HookConsumerWidget {
  final List<PlannedItem> plannedItems;

  const _TotalTimeDisplay({required this.plannedItems});

  String _formatDuration(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get API today plan data
    final apiTodayPlanAsync = ref.watch(apiTodayPlanProvider);

    // Calculate total from local planned items
    final localTotalMinutes = plannedItems.fold<int>(
      0,
      (sum, item) => sum + (item.durationMinutes ?? 0),
    );

    return apiTodayPlanAsync.when(
      data: (apiPlanItems) {
        // Calculate total from API plan items
        final apiTotalMinutes = apiPlanItems.fold<int>(
          0,
          (sum, item) => sum + (item['planned_duration_minutes'] as int? ?? 0),
        );

        // Use API total if available, otherwise use local
        final totalMinutes =
            apiTotalMinutes > 0 ? apiTotalMinutes : localTotalMinutes;

        return _buildTimeDisplay(context, totalMinutes);
      },
      loading: () => _buildTimeDisplay(context, localTotalMinutes),
      error: (e, _) => _buildTimeDisplay(context, localTotalMinutes),
    );
  }

  Widget _buildTimeDisplay(BuildContext context, int totalMinutes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF4B5563)
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 12),
              const Text(
                'Total Planned Time:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            _formatDuration(totalMinutes),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuadrantBox extends ConsumerWidget {
  final String quadrant;
  final String title;
  final String subtitle;
  final Color color;
  final List<PlannedItem> items;
  final List<Map<String, dynamic>> apiItems;
  final bool isFinalized;
  final String logId;

  final bool isGrouped;

  const _QuadrantBox(
      {required this.quadrant,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.items,
      required this.apiItems,
      required this.isFinalized,
      required this.logId,
      this.isGrouped = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<Object>(
      onAcceptWithDetails: (details) async {
        if (isFinalized) return;
        final repo = ref.read(todayRepositoryProvider);
        final data = details.data;
        if (data is String) {
          try {
            await repo.updatePlannedItem(
                data, PlannedItemsCompanion(quadrant: drift.Value(quadrant)));
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to move item: $e')),
              );
            }
          }
        } else if (data is Map<String, dynamic>) {
          // Check if it's a catalog item - call API directly
          if (data['type'] == 'catalog_item' && data['catalog_id'] != null) {
            try {
              final apiService = ref.read(taskApiServiceProvider);
              final now = DateTime.now();
              final planDate =
                  '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

              await apiService.addCatalogToDailyPlan(
                catalogId: data['catalog_id'] as int,
                planDate: planDate,
                plannedDurationMinutes: (data['duration'] as num).toInt(),
                notes: data['description'] as String?,
                quadrant: quadrant,
              );

              // Invalidate the today log provider to refresh data
              ref.invalidate(todayLogProvider);
              // Also invalidate API today plan provider
              ref.invalidate(apiTodayPlanProvider);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added "${data['name']}" to today\'s plan'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to add catalog item: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } else {
            // Show dialog before adding for non-catalog items
            showDialog(
              context: context,
              builder: (context) => TaskConfigModal(
                taskObject: data['taskObject'] as Task?,
                projectObject: data['projectObject'] as Project?,
                initialTitle: data['name'] as String?,
                initialDescription: data['description'] as String?,
                initialDuration: data['duration'] as int?,
                onConfirm: (
                    {required String name,
                    required int duration,
                    String? description,
                    List<String>? selectedMilestoneIds}) async {
                  try {
                    await repo.addPlannedItem(
                        logId,
                        PlannedItemsCompanion.insert(
                          id: const Uuid().v4(),
                          dailyLogId: logId,
                          name: name,
                          description: drift.Value(description ?? ''),
                          durationMinutes: drift.Value(duration),
                          quadrant: drift.Value(quadrant),
                          relatedTaskId:
                              drift.Value(data['relatedTaskId'] as String?),
                          isCompleted: const drift.Value(false),
                        ));
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add item: $e')),
                      );
                    }
                  }
                },
              ),
            );
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: isGrouped
              ? BoxDecoration(
                  color: isHovering
                      ? color.withValues(alpha: 0.15)
                      : color.withValues(alpha: 0.05),
                )
              : BoxDecoration(
                  color: isHovering
                      ? color.withValues(alpha: 0.15)
                      : color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isHovering ? color : color.withValues(alpha: 0.2),
                      width: isHovering ? 2.0 : 1),
                  boxShadow: isHovering
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      : [],
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0), // Reduced from 12
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                  fontSize: 13)), // Reduced from 14
                          Text(subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 10, // Reduced from 11
                                  color: color.withValues(alpha: 0.8))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text("${items.length}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                            fontSize: 13)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: items.length + apiItems.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index < items.length) {
                      final item = items[index];
                      return _DraggablePlannedItem(
                          item: item, isFinalized: isFinalized, logId: logId);
                    } else {
                      // Display API item
                      final apiItem = apiItems[index - items.length];
                      return _ApiPlannedItem(apiItem: apiItem);
                    }
                  },
                ),
              ),
              if (items.isEmpty && apiItems.isEmpty && !isFinalized)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_box_outlined,
                          size: isHovering ? 48 : 36,
                          color: isHovering
                              ? color.withValues(alpha: 0.8)
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isHovering ? "Drop here!" : "Drag items here",
                          style: TextStyle(
                            color: isHovering ? color : Colors.grey.shade500,
                            fontSize: isHovering ? 14 : 12,
                            fontWeight: isHovering
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!isFinalized)
                InkWell(
                  onTap: () {
                    // Show quick add dialog
                    showDialog(
                        context: context,
                        builder: (context) => TaskConfigModal(onConfirm: (
                                {required String name,
                                required int duration,
                                String? description,
                                List<String>? selectedMilestoneIds}) {
                              ref.read(todayRepositoryProvider).addPlannedItem(
                                  logId,
                                  PlannedItemsCompanion.insert(
                                    id: const Uuid().v4(),
                                    dailyLogId: logId,
                                    name: name,
                                    description: drift.Value(description ?? ''),
                                    durationMinutes: drift.Value(duration),
                                    quadrant: drift.Value(quadrant),
                                    isCompleted: const drift.Value(false),
                                  ));
                            }));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    alignment: Alignment.center,
                    child: Icon(Icons.add,
                        size: 20, color: color.withValues(alpha: 0.5)),
                  ),
                )
            ],
          ),
        );
      },
    );
  }
}

class _InboxBox extends ConsumerWidget {
  final List<PlannedItem> items;
  final String logId;
  const _InboxBox({required this.items, required this.logId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<Object>(
      onAcceptWithDetails: (details) async {
        final repo = ref.read(todayRepositoryProvider);
        final data = details.data;
        if (data is String) {
          try {
            await repo.updatePlannedItem(data,
                const PlannedItemsCompanion(quadrant: drift.Value('inbox')));
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to move item to inbox: $e')),
              );
            }
          }
        } else if (data is Map<String, dynamic>) {
          // Check if it's a catalog item - call API directly
          if (data['type'] == 'catalog_item' && data['catalog_id'] != null) {
            try {
              final apiService = ref.read(taskApiServiceProvider);
              final now = DateTime.now();
              final planDate =
                  '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

              await apiService.addCatalogToDailyPlan(
                catalogId: data['catalog_id'] as int,
                planDate: planDate,
                plannedDurationMinutes: (data['duration'] as num).toInt(),
                notes: data['description'] as String?,
                quadrant: 'INBOX',
              );

              // Invalidate the today log provider to refresh data
              ref.invalidate(
                  todayLogProvider); // Also invalidate API today plan provider
              ref.invalidate(apiTodayPlanProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added "${data['name']}" to inbox'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to add catalog item: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } else {
            // Show dialog for non-catalog items
            showDialog(
              context: context,
              builder: (context) => TaskConfigModal(
                taskObject: data['taskObject'] as Task?,
                projectObject: data['projectObject'] as Project?,
                initialTitle: data['name'] as String?,
                initialDescription: data['description'] as String?,
                initialDuration: data['duration'] as int?,
                onConfirm: (
                    {required String name,
                    required int duration,
                    String? description,
                    List<String>? selectedMilestoneIds}) async {
                  try {
                    await repo.addPlannedItem(
                        logId,
                        PlannedItemsCompanion.insert(
                          id: const Uuid().v4(),
                          dailyLogId: logId,
                          name: name,
                          description: drift.Value(description ?? ''),
                          durationMinutes: drift.Value(duration),
                          quadrant: const drift.Value('inbox'),
                          relatedTaskId: drift.Value(data['relatedTaskId']),
                          isCompleted: const drift.Value(false),
                        ));
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Failed to add item to inbox: $e')),
                      );
                    }
                  }
                },
              ),
            );
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isDark
                ? (isHovering
                    ? const Color(0xFF4B5563)
                    : const Color(0xFF374151))
                : (isHovering ? Colors.grey.shade200 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark
                    ? (isHovering
                        ? Colors.grey.shade400
                        : const Color(0xFF4B5563))
                    : (isHovering
                        ? Colors.grey.shade500
                        : Colors.grey.shade300),
                style: BorderStyle.solid,
                width: isHovering ? 2.0 : 1.0),
            boxShadow: isHovering
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inbox, color: Colors.grey),
                    const SizedBox(height: 4),
                    const Text("Inbox",
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                    Text("${items.length}",
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8),
                  itemCount: items.length,
                  separatorBuilder: (c, i) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return SizedBox(
                        width: 200,
                        child: _DraggablePlannedItem(
                            item: items[index],
                            isFinalized: false,
                            logId: logId));
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class _DraggablePlannedItem extends HookConsumerWidget {
  final PlannedItem item;
  final bool isFinalized;
  final String logId;

  const _DraggablePlannedItem(
      {required this.item, required this.isFinalized, required this.logId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHovered = useState(false);

    // If finalized, we have a "Start" button on hover instead of drag
    if (isFinalized) {
      return MouseRegion(
        onEnter: (_) => isHovered.value = true,
        onExit: (_) => isHovered.value = false,
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                    child: Text(item.name,
                        style: const TextStyle(fontWeight: FontWeight.w500))),
                AnimatedOpacity(
                  opacity: isHovered.value ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: IconButton(
                    onPressed: () {
                      ref.read(todayRepositoryProvider).startTask(
                          logId, item.name, item.description,
                          plannedItemId: item.id,
                          relatedTaskId: item.relatedTaskId);
                    },
                    icon:
                        const Icon(Icons.play_circle_fill, color: Colors.blue),
                    tooltip: "Start Task",
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    return LongPressDraggable<String>(
      data: item.id,
      delay: const Duration(milliseconds: 300),
      feedback: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(8),
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          width: 220,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade600, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            item.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _ItemContent(item: item, logId: logId),
      ),
      child: _ItemContent(item: item, logId: logId),
    );
  }
}

class _ItemContent extends ConsumerWidget {
  final PlannedItem item;
  final String logId;
  const _ItemContent({required this.item, required this.logId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
              color: isDark ? const Color(0xFF4B5563) : Colors.grey.shade200)),
      child: InkWell(
        onTap: () {
          showDialog(
              context: context,
              builder: (c) => TaskConfigModal(
                    plannedItem: item,
                  ));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 8), // Reduced from 12
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text(item.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                  InkWell(
                    onTap: () => ref
                        .read(todayRepositoryProvider)
                        .deletePlannedItem(item.id),
                    child:
                        const Icon(Icons.close, size: 14, color: Colors.grey),
                  )
                ],
              ),
              if (item.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(item.description,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
              const SizedBox(height: 6), // Reduced from 8
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      isDark ? const Color(0xFF374151) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text("${item.durationMinutes} min",
                    style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey.shade400 : Colors.grey)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Widget to display API-fetched planned items
class _ApiPlannedItem extends StatelessWidget {
  final Map<String, dynamic> apiItem;

  const _ApiPlannedItem({required this.apiItem});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catalogName = apiItem['catalog_name'] as String? ?? 'Unnamed';
    final durationMinutes = apiItem['planned_duration_minutes'] as int? ?? 0;
    final notes = apiItem['notes'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF4B5563) : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            catalogName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                notes,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF374151) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "$durationMinutes min",
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey.shade400 : Colors.grey,
              ),
            ),
          )
        ],
      ),
    );
  }
}
