import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../today_repository.dart';
import '../../../core/database/database.dart';
import 'package:drift/drift.dart' as drift;

class PlanActivityModal extends HookConsumerWidget {
  final DateTime? initialDate;

  const PlanActivityModal({super.key, this.initialDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theme & Styles
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final labelStyle = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 13,
      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
    );

    // State
    final selectedDate = useState(initialDate ?? DateTime.now());
    final selectedTime = useState(TimeOfDay.now()); // Added Time State
    final selectedQuadrant = useState('q2');
    final activityNameController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final duration = useState(60.0);

    // AI State
    final isGeneratingSuggestions = useState(false);
    final suggestions = useState<List<Map<String, dynamic>>>([]);

    Future<void> pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate.value,
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (picked != null) {
        selectedDate.value = picked;
      }
    }

    Future<void> pickTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: selectedTime.value,
      );
      if (picked != null) {
        selectedTime.value = picked;
      }
    }

    Future<void> generateSuggestions() async {
      isGeneratingSuggestions.value = true;
      // Simulate AI delay
      await Future.delayed(const Duration(seconds: 2));
      suggestions.value = [
        {
          'name': 'Review Pull Requests',
          'desc': 'Check outstanding PRs for the frontend team.',
          'duration': 45,
          'quadrant': 'q2'
        },
        {
          'name': 'Team Sync',
          'desc': 'Daily standup meeting.',
          'duration': 30,
          'quadrant': 'q1'
        },
        {
          'name': 'Update Documentation',
          'desc': 'Document the new Week View features.',
          'duration': 60,
          'quadrant': 'q2'
        },
      ];
      isGeneratingSuggestions.value = false;
    }

    void applySuggestion(Map<String, dynamic> suggestion) {
      activityNameController.text = suggestion['name'];
      descriptionController.text = suggestion['desc'];
      duration.value = (suggestion['duration'] as int).toDouble();
      selectedQuadrant.value = suggestion['quadrant'];
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 600),
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Left Column: AI Suggestions
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF111827)
                      : const Color(0xFFF9FAFB),
                  border: Border(right: BorderSide(color: borderColor)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            size: 18, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          "AI Suggestions",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.grey.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    if (isGeneratingSuggestions.value)
                      const Center(child: CircularProgressIndicator())
                    else if (suggestions.value.isEmpty)
                      Column(
                        children: [
                          Text(
                            "Need help planning?",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: generateSuggestions,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text("Generate Suggestions"),
                          )
                        ],
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: suggestions.value.length,
                          separatorBuilder: (c, i) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final s = suggestions.value[index];
                            return InkWell(
                              onTap: () => applySuggestion(s),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: borderColor),
                                  borderRadius: BorderRadius.circular(8),
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : Colors.white,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s['name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      s['desc'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Right Column: Form
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Text(
                            "Plan Activity",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark ? Colors.white : Colors.grey.shade900,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Date & Time Row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Scheduled Date", style: labelStyle),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: pickDate,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 12),
                                        decoration: BoxDecoration(
                                          border:
                                              Border.all(color: borderColor),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              DateFormat('MM/dd/yyyy')
                                                  .format(selectedDate.value),
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                            const Icon(Icons.calendar_today,
                                                size: 16,
                                                color: Colors.black54),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Start Time", style: labelStyle),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: pickTime,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 12),
                                        decoration: BoxDecoration(
                                          border:
                                              Border.all(color: borderColor),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              selectedTime.value
                                                  .format(context),
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                            const Icon(Icons.access_time,
                                                size: 16,
                                                color: Colors.black54),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Link to Task
                          Text("Link to Existing Task (Optional)",
                              style: labelStyle),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            hint: const Text("-- Select a task --",
                                style: TextStyle(fontSize: 14)),
                            items: const [
                              DropdownMenuItem(
                                  value: '1',
                                  child: Text('Implement Week View')),
                              DropdownMenuItem(
                                  value: '2', child: Text('Fix Flutter Error')),
                            ], // Mock items for now
                            onChanged: (val) {},
                          ),
                          const SizedBox(height: 20),

                          // Priority Quadrant
                          Text("Priority Quadrant", style: labelStyle),
                          const SizedBox(height: 8),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 2.5,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            children: [
                              _QuadrantCard(
                                id: 'q1',
                                title: 'Q1: Do First',
                                subtitle: 'Urgent & Important',
                                isSelected: selectedQuadrant.value == 'q1',
                                onTap: () => selectedQuadrant.value = 'q1',
                                selectedColor: Colors.red.shade50,
                                selectedBorderColor: Colors.red.shade200,
                              ),
                              _QuadrantCard(
                                id: 'q2',
                                title: 'Q2: Schedule',
                                subtitle: 'Important, Not Urgent',
                                isSelected: selectedQuadrant.value == 'q2',
                                onTap: () => selectedQuadrant.value = 'q2',
                                selectedColor: Colors.blue.shade50,
                                selectedBorderColor: Colors.blue.shade200,
                                textColor: Colors.blue.shade700,
                              ),
                              _QuadrantCard(
                                id: 'q3',
                                title: 'Q3: Delegate',
                                subtitle: 'Urgent, Not Important',
                                isSelected: selectedQuadrant.value == 'q3',
                                onTap: () => selectedQuadrant.value = 'q3',
                                selectedColor: Colors.orange.shade50,
                                selectedBorderColor: Colors.orange.shade200,
                              ),
                              _QuadrantCard(
                                id: 'q4',
                                title: 'Q4: Eliminate',
                                subtitle: 'Neither',
                                isSelected: selectedQuadrant.value == 'q4',
                                onTap: () => selectedQuadrant.value = 'q4',
                                selectedColor: Colors.green.shade50,
                                selectedBorderColor: Colors.green.shade200,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Activity Name
                          Text("Activity Name", style: labelStyle),
                          const SizedBox(height: 8),
                          TextField(
                            controller: activityNameController,
                            decoration: InputDecoration(
                              hintText: "",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Description
                          Text("Description / Strategy", style: labelStyle),
                          const SizedBox(height: 8),
                          TextField(
                            controller: descriptionController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: "What specifically will you do?",
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              suffixIcon:
                                  const Icon(Icons.mic, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Duration
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Duration:", style: labelStyle),
                              Text(
                                '${(duration.value / 60).floor()}h ${duration.value % 60 == 0 ? "0m" : "${(duration.value % 60).toInt()}m"}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue),
                              ),
                            ],
                          ),
                          Slider(
                            value: duration.value.clamp(15, 480),
                            min: 15,
                            max: 480,
                            divisions: 31,
                            onChanged: (val) => duration.value = val,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Footer Buttons
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: borderColor)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text("Cancel",
                                style: TextStyle(color: Colors.grey.shade600)),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () async {
                              if (activityNameController.text.isEmpty) return;

                              final repo = ref.read(todayRepositoryProvider);
                              final date = selectedDate.value;
                              final time = selectedTime.value;

                              // Combine Date + Time
                              final startDateTime = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );

                              // 1. Ensure log exists
                              // TODO: specific user ID
                              final logId = await repo.ensureDailyLogExists(
                                  date, 'user-1');

                              // 2. Add Item
                              await repo.addPlannedItem(
                                logId,
                                PlannedItemsCompanion(
                                  id: drift.Value(const Uuid().v4()),
                                  dailyLogId: drift.Value(logId),
                                  name:
                                      drift.Value(activityNameController.text),
                                  description:
                                      drift.Value(descriptionController.text),
                                  durationMinutes:
                                      drift.Value(duration.value.toInt()),
                                  quadrant: drift.Value(selectedQuadrant.value),
                                  startTime:
                                      drift.Value(startDateTime), // Saved!
                                ),
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Add Item",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuadrantCard extends StatelessWidget {
  final String id;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color selectedBorderColor;
  final Color? textColor;

  const _QuadrantCard({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.selectedColor,
    required this.selectedBorderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBorder = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.transparent,
          border: Border.all(
            color: isSelected ? selectedBorderColor : defaultBorder,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected
                    ? (textColor ?? Colors.black87)
                    : (isDark ? Colors.grey.shade300 : Colors.black87),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? (textColor?.withValues(alpha: 0.8) ??
                        Colors.grey.shade700)
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
