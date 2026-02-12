import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:project_pm/src/core/database/database.dart';
import 'package:project_pm/src/core/models/daily_log_with_details.dart';
import 'package:project_pm/src/features/today/modals/review_task_modal.dart';
import 'package:project_pm/src/features/today/today_repository.dart';

class DayLog extends ConsumerWidget {
  final DailyLogWithDetails? dailyLogWithDetails;

  const DayLog({super.key, required this.dailyLogWithDetails});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (dailyLogWithDetails == null) {
      return const Center(child: Text("Loading Log..."));
    }

    final loggedItems = dailyLogWithDetails!.loggedItems;
    // Reverse needed? Drift probably returns insertion order, we might want latest first.
    final items = loggedItems.reversed.toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
              ],
        border: isDark ? Border.all(color: const Color(0xFF374151)) : null,
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Activity Log",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                _TotalWorkedTimer(items: items),
              ],
            ),
          ),
          const Divider(height: 1),

          // List
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text("No activities logged yet.",
                        style: TextStyle(
                            color:
                                isDark ? Colors.grey.shade400 : Colors.grey)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _LoggedItemCard(item: items[index]);
                    },
                  ),
          )
        ],
      ),
    );
  }
}

class _TotalWorkedTimer extends StatefulWidget {
  final List<LoggedItem> items;
  const _TotalWorkedTimer({required this.items});

  @override
  State<_TotalWorkedTimer> createState() => _TotalWorkedTimerState();
}

class _TotalWorkedTimerState extends State<_TotalWorkedTimer> {
  late Timer _timer;
  int _totalSeconds = 0;
  int _finishedMillis = 0;

  @override
  void initState() {
    super.initState();
    _precalculateFinished();
    _calculateTotal();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (_) => _calculateTotal());
  }

  @override
  void didUpdateWidget(_TotalWorkedTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _precalculateFinished();
      _calculateTotal();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _precalculateFinished() {
    _finishedMillis = 0;
    for (var item in widget.items) {
      if (item.endTime != null) {
        _finishedMillis += item.endTime!.millisecondsSinceEpoch -
            item.startTime.millisecondsSinceEpoch;
      }
    }
  }

  void _calculateTotal() {
    int activeMillis = 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var item in widget.items) {
      if (item.endTime == null) {
        activeMillis += now - item.startTime.millisecondsSinceEpoch;
      }
    }

    final total = _finishedMillis + activeMillis;
    if (mounted) {
      setState(() => _totalSeconds = (total / 1000).floor());
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = _totalSeconds ~/ 3600;
    final minutes = (_totalSeconds % 3600) ~/ 60;
    return Text("${hours}h ${minutes}m",
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green));
  }
}

class _LoggedItemCard extends HookConsumerWidget {
  final LoggedItem item;
  const _LoggedItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = item.endTime == null;
    final dateFormat = DateFormat('HH:mm');
    final remarkController = useTextEditingController();
    final showRemarkInput = useState(false);
    
    // Parse existing remarks from JSON
    List<String> existingRemarks = [];
    try {
      final decoded = jsonDecode(item.remarksJson);
      if (decoded is List) {
        existingRemarks = decoded.cast<String>();
      }
    } catch (e) {
      debugPrint('Error parsing remarks: $e');
    }

    void addRemark() {
      if (remarkController.text.trim().isEmpty) return;
      
      final newRemarks = [...existingRemarks, remarkController.text.trim()];
      ref.read(todayRepositoryProvider).updateLoggedItemRemarks(
        item.id,
        newRemarks,
      );
      remarkController.clear();
      showRemarkInput.value = false;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRunning
            ? Colors.blue.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isRunning
                ? Colors.blue.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title and action button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(item.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        const SizedBox(width: 8),
                        if (item.isUnplanned)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4)),
                            child: const Text("Unplanned",
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold)),
                          )
                      ],
                    ),
                    if (item.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(item.description,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isRunning)
                IconButton(
                  onPressed: () async {
                    final repo = ref.read(todayRepositoryProvider);
                    if (item.plannedItemId != null) {
                      // Show review dialog for planned items
                      final progress =
                          await repo.getTaskProgress(item.plannedItemId!);
                      final remaining =
                          progress.plannedMinutes - progress.spentMinutes;
                      final currentDuration =
                          DateTime.now().difference(item.startTime);

                      if (context.mounted) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => ReviewTaskModal(
                            taskName: item.name,
                            durationWorked: currentDuration,
                            originalTimeRemaining:
                                remaining > 0 ? remaining : 0,
                            onConfirm: (isCompleted, remainingMinutes) {
                              repo.stopTaskWithReview(
                                  item.dailyLogId,
                                  item.id,
                                  isCompleted,
                                  remainingMinutes > 0
                                      ? remainingMinutes
                                      : null);
                            },
                          ),
                        );
                      }
                    } else {
                      // Just stop unplanned items
                      repo.stopTask(item.id);
                    }
                  },
                  icon: const Icon(FontAwesomeIcons.stop,
                      size: 16, color: Colors.red),
                  style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.1)),
                )
              else
                Text(
                    "${dateFormat.format(item.startTime)} - ${dateFormat.format(item.endTime!)}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey))
            ],
          ),
          
          // Existing remarks
          if (existingRemarks.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text("Remarks:",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ...existingRemarks.map((remark) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("• ", style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: Text(remark,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade700)),
                      ),
                    ],
                  ),
                )),
          ],
          
          // Add remark button/input
          const SizedBox(height: 8),
          if (!showRemarkInput.value)
            TextButton.icon(
              onPressed: () => showRemarkInput.value = true,
              icon: const Icon(Icons.add_comment, size: 16),
              label: const Text("Add Remark", style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: remarkController,
                    decoration: InputDecoration(
                      hintText: "Enter remark...",
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 12),
                    onSubmitted: (_) => addRemark(),
                    autofocus: true,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: addRemark,
                  icon: const Icon(Icons.send, size: 18),
                  tooltip: "Add Remark",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  onPressed: () {
                    remarkController.clear();
                    showRemarkInput.value = false;
                  },
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: "Cancel",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
