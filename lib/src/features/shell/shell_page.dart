import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project_pm/src/core/constants/enums.dart';
import 'package:project_pm/src/core/database/database.dart';
import 'package:project_pm/src/core/providers/user_providers.dart';
import 'package:project_pm/src/features/projects/project_providers.dart';
import 'package:project_pm/src/routes/app_router.dart';
import 'package:project_pm/src/shared/widgets/header.dart';
import 'package:project_pm/src/shared/widgets/sidebar.dart';

@RoutePage()
class ShellPage extends ConsumerWidget {
  const ShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Watch user providers
    final currentUserAsync = ref.watch(currentUserProvider);
    final allUsersAsync = ref.watch(allUsersProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final impersonatingFrom = ref.watch(impersonatingFromUserIdProvider);
    final isReadOnly = ref.watch(isReadOnlyProvider);

    // Watch the router to rebuild when route changes
    context.watchRouter;

    // Get current route path from URL to determine view mode
    final router = context.router;
    final urlState = router.urlState;
    final currentPath = urlState.path;

    // Map the URL path to the ViewMode
    final currentViewMode = _viewModeFromPath(currentPath);

    // Check if a project is selected
    final selectedProjectId = ref.watch(selectedProjectIdProvider);
    final isProjectSelected = selectedProjectId != null;

    // Dynamic Title Logic
    final titleInfo = _getTitleInfo(currentViewMode);

    return currentUserAsync.when(
      data: (currentUser) {
        if (currentUser == null) {
          return const Scaffold(
            body: Center(child: Text('No user found')),
          );
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 768;

        // Sidebar widget reused for both desktop sidebar and mobile drawer
        Widget sidebarWidget() => Sidebar(
              currentUser: currentUser,
              viewMode: currentViewMode,
              isProjectSelected: isProjectSelected,
              onViewModeChange: (mode) {
                _navigateToViewMode(context, mode);
                if (isMobile) Navigator.of(context).pop(); // Close drawer
              },
            );

        return Scaffold(
          // Drawer for mobile
          drawer: isMobile
              ? Drawer(
                  child: sidebarWidget(),
                )
              : null,
          body: Builder(
            builder: (scaffoldContext) => Stack(
              children: [
                // Main layout
                Column(
                  children: [
                    // Impersonation Banner
                    if (impersonatingFrom != null)
                      _ImpersonationBanner(
                        userName: currentUser.name,
                        onExit: () {
                          ref.read(currentUserIdProvider.notifier).state =
                              impersonatingFrom;
                          ref
                              .read(impersonatingFromUserIdProvider.notifier)
                              .state = null;
                          context.router.navigate(const TeamOverviewRoute());
                        },
                      ),
                    // Main content
                    Expanded(
                      child: Row(
                        children: [
                          // Desktop sidebar
                          if (!isMobile) sidebarWidget(),
                          // Content area
                          Expanded(
                            child: RepaintBoundary(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 1600),
                                  child: Column(
                                    children: [
                                      AppHeader(
                                        title: titleInfo.key,
                                        subtitle: isReadOnly
                                            ? 'Viewing ${currentUser.name}\'s account (Read-only)'
                                            : titleInfo.value,
                                        onMenuTap: isMobile
                                            ? () => Scaffold.of(scaffoldContext)
                                                .openDrawer()
                                            : null,
                                      ),
                                      const Expanded(child: AutoRouter()),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Debug User Switcher (top-right) - hide on mobile
                if (impersonatingFrom == null && !isMobile)
                  allUsersAsync.when(
                    data: (allUsers) => Positioned(
                      top: 12,
                      right: 12,
                      child: _UserSwitcher(
                        currentUserId: currentUserId,
                        allUsers: allUsers,
                        isDark: isDark,
                        onUserChanged: (userId) {
                          ref.read(currentUserIdProvider.notifier).state =
                              userId;
                          context.router.navigate(const DashboardRoute());
                        },
                      ),
                    ),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, __) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  // Navigate to the appropriate route based on ViewMode
  void _navigateToViewMode(BuildContext context, ViewMode mode) {
    final router = context.router;
    switch (mode) {
      case ViewMode.today:
        router.navigate(const TodayRoute());
        break;
      case ViewMode.dashboard:
        router.navigate(const DashboardRoute());
        break;
      case ViewMode.plan:
        router.navigate(const ProjectPlanRoute());
        break;
      case ViewMode.gantt:
        router.navigate(const ProjectGanttRoute());
        break;
      case ViewMode.grid:
        router.navigate(const ProjectGridRoute());
        break;
// case ViewMode.adminPanel:
//   router.navigate(const AdminUserManagementRoute());
//   break;
      case ViewMode.approvals:
        router.navigate(const ApprovalsRoute());
        break;
      case ViewMode.teamOverview:
        router.navigate(const TeamOverviewRoute());
        break;
    }
  }

  // Map URL path to ViewMode
  ViewMode _viewModeFromPath(String path) {
    // Paths in AutoRoute urlState are usually full paths, e.g. "/app/today"

    if (path.contains('/dashboard')) {
      return ViewMode.dashboard;
    } else if (path.contains('/today')) {
      return ViewMode.today;
    } else if (path.contains('/projects/plan')) {
      return ViewMode.plan;
    } else if (path.contains('/projects/gantt')) {
      return ViewMode.gantt;
    } else if (path.contains('/projects/grid')) {
      return ViewMode.grid;
    } else if (path.contains('/team')) {
      return ViewMode.teamOverview;
    } else if (path.contains('/approvals')) {
      return ViewMode.approvals;
// } else if (path.contains('/admin')) {
//   return ViewMode.dashboard; // Redirect to dashboard instead of admin
    } else if (path.contains('/projects')) {
      // Fallback for any other projects path
      return ViewMode.grid;
    }

    // Default fallback
    return ViewMode.dashboard;
  }

  MapEntry<String, String> _getTitleInfo(ViewMode mode) {
    // Subtitles mapping
    String subtitle;
    switch (mode) {
      case ViewMode.today:
        subtitle = "Plan, execute, and log your daily work.";
        break;
      case ViewMode.dashboard:
        subtitle = "Your intelligent command center for all projects.";
        break;
      case ViewMode.grid:
        subtitle = "Manage tasks in a grid view.";
        break;
      case ViewMode.plan:
        subtitle = "Task list and planning.";
        break;
      case ViewMode.gantt:
        subtitle = "Visual timeline of your project.";
        break;
// case ViewMode.adminPanel:
//   subtitle = "Manage users and permissions.";
//   break;
      case ViewMode.approvals:
        subtitle = "Review and approve requests.";
        break;
      case ViewMode.teamOverview:
        subtitle = "See what everyone is working on.";
        break;
    }

    return MapEntry(mode.label, subtitle);
  }
}

/// Impersonation banner shown when viewing another user's account
class _ImpersonationBanner extends StatelessWidget {
  final String userName;
  final VoidCallback onExit;

  const _ImpersonationBanner({
    required this.userName,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF312E81) : const Color(0xFF4F46E5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('👀', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Viewing $userName's account. Read-only mode.",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: onExit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF4F46E5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Exit & Return',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Debug user switcher dropdown (React: right corner dropdown)
class _UserSwitcher extends StatelessWidget {
  final String currentUserId;
  final List<User> allUsers;
  final bool isDark;
  final ValueChanged<String> onUserChanged;

  const _UserSwitcher({
    required this.currentUserId,
    required this.allUsers,
    required this.isDark,
    required this.onUserChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentUserId,
          isDense: true,
          dropdownColor: isDark ? Colors.grey[800] : Colors.grey[900],
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 11,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: Colors.white.withAlpha(150),
          ),
          items: allUsers.map((user) {
            return DropdownMenuItem<String>(
              value: user.id,
              child: Text(
                'As: ${user.name} (${user.role.replaceAll('_', ' ')})',
                style: TextStyle(
                  color: Colors.white.withAlpha(200),
                  fontSize: 11,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null && value != currentUserId) {
              onUserChanged(value);
            }
          },
        ),
      ),
    );
  }
}
