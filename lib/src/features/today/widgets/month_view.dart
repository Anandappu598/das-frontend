import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project_pm/src/features/today/widgets/plan_activity_modal.dart';
import 'package:intl/intl.dart';
import '../today_providers.dart';

class MonthView extends HookConsumerWidget {
  const MonthView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Local state for the currently displayed month
    final currentMonth = useState(DateTime.now());
    final selectedDate = useState<DateTime?>(null); // Selection state
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Helper to calculate start/end of the month grid
    final firstDayOfMonth =
        DateTime(currentMonth.value.year, currentMonth.value.month, 1);
    final lastDayOfMonth =
        DateTime(currentMonth.value.year, currentMonth.value.month + 1, 0);

    // Find the previous Sunday (or today if it's Sunday) to start the grid
    final firstDayOfGrid =
        firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday % 7));

    // Find next Saturday to end the grid
    final endDayOfGrid = lastDayOfMonth
        .add(Duration(days: 7 - (lastDayOfMonth.weekday % 7) - 1));

    final difference = endDayOfGrid.difference(firstDayOfGrid).inDays + 1;
    final numberOfWeeks = (difference / 7).ceil();

    final daysInGrid = List.generate(difference, (index) {
      return firstDayOfGrid.add(Duration(days: index));
    });

    // Navigation handlers
    void prevMonth() {
      currentMonth.value =
          DateTime(currentMonth.value.year, currentMonth.value.month - 1);
    }

    void nextMonth() {
      currentMonth.value =
          DateTime(currentMonth.value.year, currentMonth.value.month + 1);
    }

    void goToToday() {
      currentMonth.value = DateTime.now();
    }

    // Hover state for displaying the Add button
    final hoveredDate = useState<DateTime?>(null);

    // Watch planned items for the month
    final plannedItemsAsync =
        ref.watch(monthPlannedItemsProvider(currentMonth.value));

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      color: isDark ? const Color(0xFF1F2937) : Colors.white,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(currentMonth.value),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(
                      width: 16), // Replaced spacer with fixed spacing
                  IconButton(
                    onPressed: prevMonth,
                    icon: const Icon(Icons.chevron_left),
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: goToToday,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Today",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: nextMonth,
                    icon: const Icon(Icons.chevron_right),
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
          Divider(
              height: 1,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),

          // Days Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.transparent : const Color(0xFFF9FAFB),
            ),
            child: Row(
              children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Divider(
              height: 1,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),

          // Calendar Grid
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              // Calculate cell height based on available space divided by number of weeks (dynamic)
              // Ensure we don't divide by zero if something goes wrong
              final weeks = numberOfWeeks > 0 ? numberOfWeeks : 6;
              final cellHeight = constraints.maxHeight / weeks;

              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: daysInGrid.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisExtent: cellHeight,
                ),
                itemBuilder: (context, index) {
                  final date = daysInGrid[index];
                  // Normalize date for map lookup
                  final normalizedDate =
                      DateTime(date.year, date.month, date.day);

                  final isCurrentMonth = date.month == currentMonth.value.month;
                  final isToday = DateUtils.isSameDay(date, DateTime.now());
                  final isSelected = selectedDate.value != null &&
                      DateUtils.isSameDay(date, selectedDate.value);
                  final isHovered = hoveredDate.value != null &&
                      DateUtils.isSameDay(date, hoveredDate.value!);

                  // Get items for this day
                  // Accessing the provider value for the specific date
                  final itemsForDay =
                      plannedItemsAsync.value?[normalizedDate] ?? [];

                  return MouseRegion(
                    onEnter: (_) => hoveredDate.value = date,
                    onExit: (_) => hoveredDate.value = null,
                    child: InkWell(
                      onTap: () => selectedDate.value = date,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.transparent : Colors.white,
                          border: Border(
                            right: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade100),
                            bottom: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade100),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date Number - Only show if current month or today
                                  if (isCurrentMonth || isToday)
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: isToday
                                            ? Colors.blue
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(14),
                                        border: (isSelected && !isToday)
                                            ? Border.all(
                                                color: Colors.blue, width: 2)
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${date.day}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isToday
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isToday
                                              ? Colors.white
                                              : (isDark
                                                  ? Colors.grey.shade300
                                                  : Colors.grey.shade900),
                                        ),
                                      ),
                                    ),
                                  // Events List
                                  if (itemsForDay.isNotEmpty &&
                                      isCurrentMonth) ...[
                                    const SizedBox(height: 4),
                                    ...itemsForDay.take(3).map((item) =>
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 2),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.blue
                                                      .withValues(alpha: 0.2)
                                                  : Colors.blue.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.name,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isDark
                                                    ? Colors.blue.shade200
                                                    : Colors.blue.shade800,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              maxLines: 1,
                                            ),
                                          ),
                                        )),
                                    if (itemsForDay.length > 3)
                                      Text(
                                        '+${itemsForDay.length - 3} more',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey.shade500,
                                        ),
                                      )
                                  ]
                                ],
                              ),
                            ),
                            // Hover Add Button Overlay
                            if (isHovered && isCurrentMonth)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => PlanActivityModal(
                                        initialDate: date,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
