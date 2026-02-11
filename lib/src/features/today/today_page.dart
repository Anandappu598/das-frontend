import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project_pm/src/features/today/today_providers.dart';
import 'package:project_pm/src/features/today/today_repository.dart';
import 'package:project_pm/src/features/today/widgets/day_log.dart';
import 'package:project_pm/src/features/today/widgets/day_planner.dart';
import 'package:project_pm/src/features/today/widgets/activity_catalog.dart';
import 'package:project_pm/src/features/today/widgets/view_toggle_button.dart';
import 'package:project_pm/src/features/today/widgets/month_view.dart';
import 'package:project_pm/src/features/today/widgets/week_view.dart';
import 'package:project_pm/src/features/today/modals/send_instructions_modal.dart';

@RoutePage()
class TodayPage extends ConsumerStatefulWidget {
  const TodayPage({super.key});

  @override
  ConsumerState<TodayPage> createState() => _TodayPageState();
}

enum CalendarViewMode { today, week, month }

class _TodayPageState extends ConsumerState<TodayPage> {
  bool _isCatalogOpen = false;
  CalendarViewMode? _currentView = CalendarViewMode.today;

  @override
  void initState() {
    super.initState();
    _currentView = CalendarViewMode.today;
    // Skip database on web
    if (kIsWeb) return;

    // Refresh the log provider to ensure we use the current date/time
    // (Crucial if the app was backgrounded or provider kept alive from yesterday)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(todayLogProvider);

      // Ensure log exists
      ref
          .read(todayRepositoryProvider)
          .ensureDailyLogExists(DateTime.now(), 'user-1')
          .then((_) => debugPrint('Daily log verified/created.'))
          .catchError((e) => debugPrint('Error ensuring daily log: $e'));
    });
  }

  @override
  Widget build(BuildContext context) {
    final todayLogAsync = ref.watch(todayLogProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentView = _currentView ?? CalendarViewMode.today;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: todayLogAsync.when(
          data: (data) {
            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // View Switcher
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF374151)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ViewToggleButton(
                          label: 'Today',
                          icon: Icons.calendar_today,
                          isSelected: currentView == CalendarViewMode.today,
                          onTap: () => setState(
                              () => _currentView = CalendarViewMode.today),
                        ),
                        ViewToggleButton(
                          label: 'Week View',
                          icon: Icons.calendar_view_week,
                          isSelected: currentView == CalendarViewMode.week,
                          onTap: () => setState(() {
                            _currentView = CalendarViewMode.week;
                            if (_currentView == CalendarViewMode.week) {
                              _isCatalogOpen = true;
                            }
                          }),
                        ),
                        ViewToggleButton(
                          label: 'Month View',
                          icon: Icons.calendar_month,
                          isSelected: currentView == CalendarViewMode.month,
                          onTap: () => setState(() {
                            _currentView = CalendarViewMode.month;
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Top Toolbar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Catalog Toggle Button
                      // Catalog Toggle Button
                      if (currentView == CalendarViewMode.today ||
                          currentView == CalendarViewMode.week)
                        Material(
                          color: _isCatalogOpen
                              ? (isDark
                                  ? const Color(0xFF374151)
                                  : Colors.grey.shade200)
                              : (isDark
                                  ? const Color(0xFF1F2937)
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () => setState(
                                () => _isCatalogOpen = !_isCatalogOpen),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isCatalogOpen
                                      ? (isDark
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade300)
                                      : (isDark
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade200),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.menu,
                                    size: 18,
                                    color: isDark
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Catalog',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      if (currentView == CalendarViewMode.today ||
                          currentView == CalendarViewMode.week)
                        const SizedBox(width: 12),

                      // Send Instructions Button (Always Visible)
                      OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const SendInstructionsModal(),
                          );
                        },
                        icon: const Icon(Icons.people_outline, size: 18),
                        label: const Text("Send Instructions"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Main Content
                Expanded(
                  child: currentView == CalendarViewMode.month
                      ? const MonthView()
                      : LayoutBuilder(builder: (context, constraints) {
                          // Minimum width logic
                          final double minWidth = (_isCatalogOpen ? 280 : 0) +
                              800; // Increased from 700
                          final double availableWidth =
                              constraints.maxWidth.isFinite
                                  ? constraints.maxWidth
                                  : MediaQuery.of(context).size.width;
                          final bool needsScroll = availableWidth < minWidth;

                          // Use a consistent widget structure to preserve animation state
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: needsScroll
                                ? const AlwaysScrollableScrollPhysics()
                                : const NeverScrollableScrollPhysics(),
                            child: SizedBox(
                              width: needsScroll ? minWidth : availableWidth,
                              height: constraints.maxHeight,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 1. Catalog - Animated visibility
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    width: _isCatalogOpen ? 280 : 0,
                                    clipBehavior:
                                        Clip.hardEdge, // Prevents overlap
                                    decoration: const BoxDecoration(
                                      color: Colors
                                          .transparent, // Required when using clipBehavior
                                    ),
                                    child: OverflowBox(
                                      // Ensures content stays fixed width during slide
                                      minWidth: 280,
                                      maxWidth: 280,
                                      alignment: Alignment.topLeft,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 24),
                                        child: ActivityCatalog(
                                            dailyLogId: data.dailyLog.id),
                                      ),
                                    ),
                                  ),

                                  // 2. Week View OR Day View
                                  if (currentView == CalendarViewMode.week)
                                    Expanded(
                                      flex: 1,
                                      child: WeekView(
                                        onToggleCatalog: () => setState(() =>
                                            _isCatalogOpen = !_isCatalogOpen),
                                      ),
                                    )
                                  else ...[
                                    Expanded(
                                      flex: 1,
                                      child:
                                          DayPlanner(dailyLogWithDetails: data),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      flex: 1,
                                      child: DayLog(dailyLogWithDetails: data),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                ),
              ],
            );
          },
          error: (err, st) => Center(child: Text("Error: $err")),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
