import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project_pm/src/features/dashboard/dashboard_providers.dart';
import 'package:project_pm/src/features/dashboard/widgets/project_overview_stats.dart';
import 'package:project_pm/src/features/dashboard/widgets/work_statistics_chart.dart';
import 'package:project_pm/src/features/dashboard/widgets/sticky_note_board.dart';
import 'package:project_pm/src/features/dashboard/widgets/day_activity_status.dart';
import 'package:project_pm/src/features/dashboard/widgets/risk_alert_banner.dart';
import 'package:project_pm/src/features/dashboard/modals/create_new_workspace_modal.dart';
import 'package:project_pm/src/core/models/project_with_tasks.dart';
import 'package:project_pm/src/core/providers/user_providers.dart';
import 'package:project_pm/src/features/dashboard/widgets/todays_focus_card.dart';
import 'package:project_pm/src/features/dashboard/widgets/ai_insights_card.dart';
import 'package:project_pm/src/features/dashboard/widgets/dashboard_project_card.dart';

//
import 'package:project_pm/src/features/projects/project_providers.dart';
import 'package:project_pm/src/routes/app_router.dart';

import 'package:project_pm/src/shared/providers/sidebar_providers.dart';

@RoutePage()
class DashboardPage extends HookConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(dashboardProjectsProvider);
    final searchQuery = useState('');
    final selectedProjectType = useState<String>('my'); // 'my' or 'team'
    final selectedStatusFilter = useState<String?>(null);

    return Scaffold(
      body: projectsAsync.when(
        data: (projects) {
          // Filter by project type first

          final projectsByTypeList = useMemoized(
              () => projects.where((p) {
                    if (selectedProjectType.value == 'my') {
                      final currentUserId = ref.watch(currentUserIdProvider);
                      return p.tasks.any(
                          (t) => t.assignees.any((u) => u.id == currentUserId));
                    } else {
                      return true;
                    }
                  }).toList(),
              [projects, selectedProjectType.value]);

          final projectsAfterSearchList = useMemoized(
              () => projectsByTypeList.where((p) {
                    if (searchQuery.value.isEmpty) return true;
                    return p.project.name
                        .toLowerCase()
                        .contains(searchQuery.value.toLowerCase());
                  }).toList(),
              [projectsByTypeList, searchQuery.value]);

          final filteredProjects = useMemoized(
              () => projectsAfterSearchList.where((p) {
                    if (selectedStatusFilter.value != null) {
                      final now = DateTime.now();
                      switch (selectedStatusFilter.value) {
                        case 'Completed':
                          if (p.tasks.isEmpty) return false;
                          return p.tasks.every((t) => t.progress == 100);
                        case 'Overdue':
                          return p.tasks.any((t) =>
                              t.endDate.isBefore(now) && t.progress < 100);
                        case 'In Progress':
                          return p.tasks
                              .any((t) => t.progress > 0 && t.progress < 100);
                        case 'To Do':
                          if (p.tasks.isEmpty) return true;
                          return p.tasks.every((t) => t.progress == 0);
                      }
                    }
                    return true;
                  }).toList(),
              [projectsAfterSearchList, selectedStatusFilter.value]);

          // Calculate metrics for filtered projects
          final dashboardService = ref.read(dashboardServiceProvider);
          final filteredMetrics = useMemoized(() {
            return DashboardMetrics(
              risks: dashboardService.analyzeRisks(filteredProjects),
              focusItems: dashboardService.identifyFocusItems(filteredProjects),
              insights: dashboardService.generateAiInsights(filteredProjects),
              totalProjects: filteredProjects.length,
              teamStats: null,
              recentActivities: [],
            );
          }, [filteredProjects, selectedProjectType.value]);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Risk Banner
                RiskAlertBanner(risks: filteredMetrics.risks),

                // 2. Header Actions - Responsive
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;

                    if (isNarrow) {
                      // Narrow layout: Stack vertically
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Dashboard",
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              // Toggle buttons
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFF374151)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _ProjectTypeButton(
                                      label: 'My',
                                      icon: Icons.person_outline,
                                      isSelected:
                                          selectedProjectType.value == 'my',
                                      onTap: () =>
                                          selectedProjectType.value = 'my',
                                    ),
                                    _ProjectTypeButton(
                                      label: 'Team',
                                      icon: Icons.group_outlined,
                                      isSelected:
                                          selectedProjectType.value == 'team',
                                      onTap: () =>
                                          selectedProjectType.value = 'team',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Search field full width
                          TextField(
                            onChanged: (val) => searchQuery.value = val,
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: "Search projects...",
                              hintStyle: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade500,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF374151)
                                  : Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 0,
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    // Wide layout: Original Row
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Dashboard",
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF374151)
                                    : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ProjectTypeButton(
                                label: 'My Projects',
                                icon: Icons.person_outline,
                                isSelected: selectedProjectType.value == 'my',
                                onTap: () => selectedProjectType.value = 'my',
                              ),
                              _ProjectTypeButton(
                                label: 'Team Projects',
                                icon: Icons.group_outlined,
                                isSelected: selectedProjectType.value == 'team',
                                onTap: () => selectedProjectType.value = 'team',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Flexible(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: TextField(
                              onChanged: (val) => searchQuery.value = val,
                              style: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: "Search projects...",
                                hintStyle: TextStyle(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade500,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                                filled: true,
                                fillColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF374151)
                                    : Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Active Filter Chip
                if (selectedStatusFilter.value != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        InputChip(
                          label: Text('Filter: ${selectedStatusFilter.value}'),
                          onDeleted: () => selectedStatusFilter.value = null,
                          deleteIcon: const Icon(Icons.close, size: 18),
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          labelStyle: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                // 3. Overview Stats
                ProjectOverviewStats(projects: filteredProjects),

                const SizedBox(height: 12),

                // 4. AI & Focus Section - Responsive
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 700;

                    if (isNarrow) {
                      // Stack vertically on narrow screens
                      return Column(
                        children: [
                          SizedBox(
                            height: 280,
                            child: AiInsightsCard(
                              insights: filteredMetrics.insights,
                              onRunAnalysis: () {
                                ref.invalidate(dashboardMetricsProvider);
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 220,
                            child: TodaysFocusCard(
                              items: filteredMetrics.focusItems,
                            ),
                          ),
                        ],
                      );
                    }

                    return SizedBox(
                      height: 300,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 3,
                            child: AiInsightsCard(
                              insights: filteredMetrics.insights,
                              onRunAnalysis: () {
                                ref.invalidate(dashboardMetricsProvider);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TodaysFocusCard(
                              items: filteredMetrics.focusItems,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // 5. Sticky Notes (Quick Notes) - Moved above Analytics
                const StickyNoteBoard(),

                const SizedBox(height: 24),

                // 6. Analytics Row - Responsive (Donut Charts)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 700;

                    if (isNarrow) {
                      // Stack vertically on narrow screens
                      return Column(
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SizedBox(
                                height: 250,
                                child: WorkStatisticsChart(
                                  projects: projectsAfterSearchList,
                                  selectedStatus: selectedStatusFilter.value,
                                  onStatusSelected: (status) {
                                    selectedStatusFilter.value = status;
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Card(
                            child: SizedBox(
                              height: 280,
                              child: DayActivityStatus(),
                            ),
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SizedBox(
                                height: 300,
                                child: WorkStatisticsChart(
                                  projects: projectsAfterSearchList,
                                  selectedStatus: selectedStatusFilter.value,
                                  onStatusSelected: (status) {
                                    selectedStatusFilter.value = status;
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          flex: 1,
                          child: Card(
                            child: SizedBox(
                              height: 332,
                              child: DayActivityStatus(),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // 7. My Projects Section - Moved to bottom
                _MyProjectsSection(
                  projects: filteredProjects,
                  selectedProjectType: selectedProjectType.value,
                  onProjectTap: (project) {
                    ref.read(selectedProjectIdProvider.notifier).state =
                        project.project.id;
                    // Expand sidebar when navigating to a project
                    ref.read(sidebarCollapsedProvider.notifier).state = false;
                    context.router.navigate(const ProjectPlanRoute());
                  },
                  onNewProject: () async {
                    await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const CreateNewWorkspaceModal(),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

/// Filter options for projects
enum _ProjectFilter { all, active, critical, completed }

/// My Projects Section with filters, view toggle, and enhanced cards
class _MyProjectsSection extends HookWidget {
  final List<ProjectWithTasks> projects;
  final String selectedProjectType;
  final void Function(ProjectWithTasks) onProjectTap;
  final VoidCallback? onNewProject;

  const _MyProjectsSection({
    required this.projects,
    required this.selectedProjectType,
    required this.onProjectTap,
    this.onNewProject,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedFilter = useState(_ProjectFilter.all);
    final isGridView = useState(true);

    // Filter by internal status only (Active, Critical, Completed)
    final filteredProjects = projects.where((p) {
      if (selectedFilter.value == _ProjectFilter.all) return true;
      if (selectedFilter.value == _ProjectFilter.active) return p.isActive;
      if (selectedFilter.value == _ProjectFilter.completed) {
        return p.isCompleted;
      }
      if (selectedFilter.value == _ProjectFilter.critical) {
        // Show critical if any task is high priority
        return p.tasks.any((t) => t.task.priority == 'Critical');
      }
      return true;
    }).toList();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title, filters, and view toggle - RESPONSIVE
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              selectedProjectType == 'my'
                                  ? "My Projects"
                                  : "Team Projects",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            "${filteredProjects.length} found",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Filter tabs + toggle row
                      Row(
                        children: [
                          Expanded(
                            child: _FilterTabs(
                              selectedFilter: selectedFilter.value,
                              onFilterChanged: (f) => selectedFilter.value = f,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ViewToggle(
                            isGridView: isGridView.value,
                            onToggle: (v) => isGridView.value = v,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  );
                }

                // Wide layout
                return Row(
                  children: [
                    Text(
                      selectedProjectType == 'my'
                          ? "My Projects"
                          : "Team Projects",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${filteredProjects.length} projects found.",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    _FilterTabs(
                      selectedFilter: selectedFilter.value,
                      onFilterChanged: (f) => selectedFilter.value = f,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 16),
                    _ViewToggle(
                      isGridView: isGridView.value,
                      onToggle: (v) => isGridView.value = v,
                      isDark: isDark,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Projects Row: Grid/List (Removed fixed height)
            filteredProjects.isEmpty
                ? Container(
                    constraints: const BoxConstraints(minHeight: 200),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              FontAwesomeIcons.folderOpen,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              selectedProjectType == 'team'
                                  ? "No team projects found."
                                  : "No projects match this filter.",
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                            if (selectedProjectType == 'team')
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  "Team projects are those with multiple assignees.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isGridView.value
                        ? GridView.builder(
                            key: const ValueKey('grid'),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 380,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.1,
                            ),
                            itemCount: filteredProjects.length,
                            itemBuilder: (context, index) {
                              return DashboardProjectCard(
                                project: filteredProjects[index],
                                isDark: isDark,
                                onTap: () =>
                                    onProjectTap(filteredProjects[index]),
                              );
                            },
                          )
                        : ListView.separated(
                            key: const ValueKey('list'),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredProjects.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return DashboardProjectCard(
                                project: filteredProjects[index],
                                isDark: isDark,
                                onTap: () =>
                                    onProjectTap(filteredProjects[index]),
                                isListView: true,
                              );
                            },
                          ),
                  ),
          ],
        ),

        // NEW Button - only visible for 'my' projects
        if (onNewProject != null)
          Positioned(
            bottom: 16,
            right: 16,
            child: Material(
              color: isDark ? const Color(0xFF374151) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              elevation: 4,
              shadowColor: Colors.black26,
              child: InkWell(
                onTap: onNewProject,
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.create_new_folder_outlined,
                        size: 18,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'NEW',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Filter tabs widget
class _FilterTabs extends StatelessWidget {
  final _ProjectFilter selectedFilter;
  final void Function(_ProjectFilter) onFilterChanged;
  final bool isDark;

  const _FilterTabs({
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildTab(_ProjectFilter filter, String label) {
      final isSelected = selectedFilter == filter;
      return InkWell(
        onTap: () => onFilterChanged(filter),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.blue.shade900 : Colors.blue.shade50)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Colors.blue
                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? Colors.blue
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildTab(_ProjectFilter.all, "All"),
          const SizedBox(width: 8),
          buildTab(_ProjectFilter.active, "Active"),
          const SizedBox(width: 8),
          buildTab(_ProjectFilter.critical, "Critical"),
          const SizedBox(width: 8),
          buildTab(_ProjectFilter.completed, "Completed"),
        ],
      ),
    );
  }
}

/// View toggle (grid/list)
class _ViewToggle extends StatelessWidget {
  final bool isGridView;
  final void Function(bool) onToggle;
  final bool isDark;

  const _ViewToggle({
    required this.isGridView,
    required this.onToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _toggleButton(
            FontAwesomeIcons.tableCells,
            isGridView,
            () => onToggle(true),
          ),
          _toggleButton(
            FontAwesomeIcons.list,
            !isGridView,
            () => onToggle(false),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? Colors.blue.shade900 : Colors.blue.shade50)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isActive
              ? Colors.blue
              : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
      ),
    );
  }
}

//

//

// End of file

/// Project Type Toggle Button Widget
class _ProjectTypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProjectTypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.blue.shade700 : Colors.blue)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// End of file
