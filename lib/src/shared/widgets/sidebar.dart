import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project_pm/src/core/constants/enums.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_pm/src/shared/providers/sidebar_providers.dart';
import 'package:project_pm/src/features/projects/project_providers.dart';

// Stub for User model, replace with actual import when available
class UserStub {
  final String name;
  final String avatarUrl;
  final UserRole role;

  UserStub({required this.name, required this.avatarUrl, required this.role});
}

class Sidebar extends HookConsumerWidget {
  final UserStub currentUser;
  final ViewMode viewMode;
  final Function(ViewMode) onViewModeChange;
  final bool isProjectSelected;
  final int pendingApprovalsCount;

  const Sidebar({
    super.key,
    required this.currentUser,
    required this.viewMode,
    required this.onViewModeChange,
    required this.isProjectSelected,
    this.pendingApprovalsCount = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCollapsed = ref.watch(sidebarCollapsedProvider);
    // Use the provider state directly instead of LayoutBuilder constraints
    // This avoids rebuilding the entire tree every frame during animation
    final isEffectivelyExpanded = !isCollapsed;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dark theme colors matching React
    final sidebarBg = isDark ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = isDark ? const Color(0xFF374151) : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.grey.shade800;
    final mutedColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final sectionColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200), // Faster animation
      curve: Curves.easeOut,
      width: isCollapsed ? 80 : 256,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          // Logo Area
          Container(
            height: 88,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: !isEffectivelyExpanded
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'P',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (isEffectivelyExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Merida Brain',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      softWrap: false,
                    ),
                  ),
                ],
                if (isEffectivelyExpanded)
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: () => ref
                        .read(sidebarCollapsedProvider.notifier)
                        .state = true,
                    color: mutedColor,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
              ],
            ),
          ),

          // Toggle button if collapsed
          if (!isEffectivelyExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: () =>
                    ref.read(sidebarCollapsedProvider.notifier).state = false,
                color: mutedColor,
              ),
            ),

          // Nav Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              children: [
// Show all items if no project is selected
                if (!isProjectSelected) ...[
                  buildNavItem(
                      context,
                      isEffectivelyExpanded,
                      ViewMode.dashboard,
                      FontAwesomeIcons.chartPie,
                      ViewMode.dashboard.label),
                  buildNavItem(context, isEffectivelyExpanded, ViewMode.today,
                      FontAwesomeIcons.calendarDay, ViewMode.today.label),
                ],

                if (isProjectSelected) ...[
                  // Back to Dashboard Button
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Tooltip(
                      message:
                          !isEffectivelyExpanded ? 'Back to Dashboard' : '',
                      child: InkWell(
                        onTap: () {
                          ref.read(selectedProjectIdProvider.notifier).state =
                              null;
                          onViewModeChange(ViewMode.dashboard);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: !isEffectivelyExpanded ? 0 : 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            mainAxisAlignment: !isEffectivelyExpanded
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.start,
                            children: [
                              Icon(Icons.arrow_back,
                                  size: 20, color: mutedColor),
                              if (isEffectivelyExpanded) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Back to Dashboard",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: mutedColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!isEffectivelyExpanded) ...[
                    Divider(height: 24, thickness: 1, color: borderColor),
                    buildNavItem(context, isEffectivelyExpanded, ViewMode.plan,
                        FontAwesomeIcons.listCheck, "Plan"),
                    buildNavItem(context, isEffectivelyExpanded, ViewMode.gantt,
                        FontAwesomeIcons.timeline, "Gantt"),
                    buildNavItem(context, isEffectivelyExpanded, ViewMode.grid,
                        FontAwesomeIcons.tableCells, "Grid"),
                  ] else ...[
                    Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        title: Text(
                          "CURRENT PROJECT",
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: sectionColor,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                        ),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        childrenPadding: EdgeInsets.zero,
                        iconColor: sectionColor,
                        collapsedIconColor: sectionColor,
                        children: [
                          buildNavItem(
                              context,
                              isEffectivelyExpanded,
                              ViewMode.plan,
                              FontAwesomeIcons.listCheck,
                              ViewMode.plan.label),
                          buildNavItem(
                              context,
                              isEffectivelyExpanded,
                              ViewMode.gantt,
                              FontAwesomeIcons.timeline,
                              ViewMode.gantt.label),
                          buildNavItem(
                              context,
                              isEffectivelyExpanded,
                              ViewMode.grid,
                              FontAwesomeIcons.tableCells,
                              ViewMode.grid.label),
                        ],
                      ),
                    ),
                  ],
                ],

                // Only show Management and General if NO project is selected
                if (!isProjectSelected) ...[
                  if (currentUser.role.isAdmin ||
                      currentUser.role.isManager ||
                      currentUser.role.isTeamLead) ...[
                    buildSectionTitle(isEffectivelyExpanded, borderColor,
                        sectionColor, "Management"),
                    buildNavItem(
                        context,
                        isEffectivelyExpanded,
                        ViewMode.teamOverview,
                        FontAwesomeIcons.users,
                        ViewMode.teamOverview.label),
                    buildNavItem(
                        context,
                        isEffectivelyExpanded,
                        ViewMode.approvals,
                        FontAwesomeIcons.circleCheck,
                        ViewMode.approvals.label,
                        badge: pendingApprovalsCount),
                    if (currentUser.role.isAdmin)
                      buildNavItem(
                          context,
                          isEffectivelyExpanded,
                          ViewMode.adminPanel,
                          FontAwesomeIcons.shieldHalved,
                          ViewMode.adminPanel.label),
                  ],
                  buildSectionTitle(isEffectivelyExpanded, borderColor,
                      sectionColor, "General"),
                  buildNavItem(context, isEffectivelyExpanded, ViewMode.reports,
                      FontAwesomeIcons.chartSimple, ViewMode.reports.label),
                  buildNavItem(
                      context,
                      isEffectivelyExpanded,
                      ViewMode.settings,
                      FontAwesomeIcons.sliders,
                      ViewMode.settings.label),
                ],
              ],
            ),
          ),

          // User Profile
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: !isEffectivelyExpanded
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(currentUser.avatarUrl),
                  backgroundColor:
                      isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                ),
                if (isEffectivelyExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: textColor,
                          ),
                          overflow: TextOverflow.clip,
                          maxLines: 1,
                          softWrap: false,
                        ),
                        Text(
                          currentUser.role.label,
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.clip,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildNavItem(BuildContext context, bool isEffectivelyExpanded,
      ViewMode mode, IconData icon, String label,
      {int badge = 0}) {
    final isSelected = viewMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sidebarBg = isDark ? const Color(0xFF1F2937) : Colors.white;
    // final borderColor = isDark ? const Color(0xFF374151) : Colors.grey.shade200; // Unused
    // final textColor = isDark ? Colors.white : Colors.grey.shade800; // Unused
    // final mutedColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600; // Unused

    final selectedBg =
        isDark ? Colors.blue.shade900.withAlpha(80) : Colors.blue.shade50;
    final selectedBorder = isDark ? Colors.blue.shade700 : Colors.blue.shade200;
    final iconColor = isSelected
        ? Colors.blue
        : (isDark ? Colors.grey.shade400 : Colors.grey.shade600);
    final labelColor = isSelected
        ? (isDark ? Colors.blue.shade300 : Colors.blue.shade700)
        : (isDark ? Colors.grey.shade300 : Colors.grey.shade700);

    return Tooltip(
      message:
          !isEffectivelyExpanded ? '$label ${badge > 0 ? "($badge)" : ""}' : '',
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: () => onViewModeChange(mode),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: !isEffectivelyExpanded ? 0 : 16,
          ),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: selectedBorder) : null,
          ),
          child: Row(
            mainAxisAlignment: !isEffectivelyExpanded
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 20, color: iconColor),
                  if (badge > 0 && !isEffectivelyExpanded)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: sidebarBg, width: 1.5),
                        ),
                        child: Text(
                          badge > 9 ? '9+' : badge.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                ],
              ),
              if (isEffectivelyExpanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: labelColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                  ),
                ),
                if (badge > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSectionTitle(bool isEffectivelyExpanded, Color borderColor,
      Color sectionColor, String title) {
    if (!isEffectivelyExpanded) {
      return Divider(height: 24, thickness: 1, color: borderColor);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: sectionColor,
          letterSpacing: 0.5,
        ),
        maxLines: 1,
        overflow: TextOverflow.clip,
      ),
    );
  }
}
