import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project_pm/src/core/database/database.dart';
import 'package:project_pm/src/core/providers/user_providers.dart';
import 'package:project_pm/src/routes/app_router.dart';

@RoutePage()
class TeamOverviewPage extends ConsumerWidget {
  const TeamOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final borderColor = isDark ? const Color(0xFF374151) : Colors.grey.shade200;
    final mutedText = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final currentUserAsync = ref.watch(currentUserProvider);
    final visibleTeam = ref.watch(visibleTeamMembersProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Overview',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    currentUserAsync.when(
                      data: (user) => Text(
                        user != null
                            ? 'Showing ${_getTeamDescription(user.role)}'
                            : '',
                        style: TextStyle(color: mutedText, fontSize: 13),
                      ),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Add Member'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Team Stats
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  // Wide screen: 4 columns
                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Team Members',
                          value: '${visibleTeam.length}',
                          icon: FontAwesomeIcons.users,
                          color: Colors.blue,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Active Projects',
                          value: '5',
                          icon: FontAwesomeIcons.briefcase,
                          color: Colors.green,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Tasks This Week',
                          value: '45',
                          icon: FontAwesomeIcons.listCheck,
                          color: Colors.purple,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Completion Rate',
                          value: '78%',
                          icon: FontAwesomeIcons.chartLine,
                          color: Colors.orange,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  );
                } else {
                  // Narrow screen: 2 columns grid
                  return GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _StatCard(
                        title: 'Team Members',
                        value: '${visibleTeam.length}',
                        icon: FontAwesomeIcons.users,
                        color: Colors.blue,
                        isDark: isDark,
                      ),
                      _StatCard(
                        title: 'Active Projects',
                        value: '5',
                        icon: FontAwesomeIcons.briefcase,
                        color: Colors.green,
                        isDark: isDark,
                      ),
                      _StatCard(
                        title: 'Tasks This Week',
                        value: '45',
                        icon: FontAwesomeIcons.listCheck,
                        color: Colors.purple,
                        isDark: isDark,
                      ),
                      _StatCard(
                        title: 'Completion Rate',
                        value: '78%',
                        icon: FontAwesomeIcons.chartLine,
                        color: Colors.orange,
                        isDark: isDark,
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 32),

            // Team Members Grid (from database)
            Text(
              'Team Members',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            if (visibleTeam.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        FontAwesomeIcons.usersSlash,
                        size: 48,
                        color: mutedText,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No team members to display',
                        style: TextStyle(color: mutedText, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Only managers and team leads can view team members.',
                        style: TextStyle(color: mutedText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ref.watch(teamStatsProvider).when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, st) => Text('Error loading stats: $err'),
                    data: (teamStats) {
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 350,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.3,
                        ),
                        itemCount: visibleTeam.length,
                        itemBuilder: (context, index) {
                          final member = visibleTeam[index];
                          final stats = teamStats[member.id] ??
                              {'active': 0, 'completed': 0, 'workload': 0};

                          return _TeamMemberCard(
                            member: member,
                            isDark: isDark,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            mutedText: mutedText,
                            stats: stats,
                            onViewAs: () {
                              // Impersonate user
                              final currentId = ref.read(currentUserIdProvider);
                              ref
                                  .read(
                                      impersonatingFromUserIdProvider.notifier)
                                  .state = currentId;
                              ref.read(currentUserIdProvider.notifier).state =
                                  member.id;
                              context.router.navigate(const DashboardRoute());
                            },
                          );
                        },
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  String _getTeamDescription(String role) {
    switch (role) {
      case 'ADMIN':
        return 'all organization members';
      case 'MANAGER':
        return 'your direct and indirect reports';
      case 'TEAM_LEAD':
        return 'your team members';
      default:
        return 'your team';
    }
  }
}

// Provider to fetch stats for a specific user - DEPRECATED in favor of teamStatsProvider
final memberStatsProvider =
    FutureProvider.family<Map<String, int>, String>((ref, userId) async {
  return {'active': 0, 'completed': 0, 'workload': 0};
});

class _TeamMemberCard extends StatelessWidget {
  final User member;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color mutedText;
  final VoidCallback onViewAs;
  final Map<String, int> stats;

  const _TeamMemberCard({
    required this.member,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.mutedText,
    required this.onViewAs,
    this.stats = const {'active': 0, 'completed': 0, 'workload': 0},
  });

  @override
  Widget build(BuildContext context) {
    final active = stats['active'] ?? 0;
    final completed = stats['completed'] ?? 0;
    final workload = stats['workload'] ?? 0;

    return InkWell(
      onTap: onViewAs,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar, Name, Role
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: member.avatarUrl.isNotEmpty
                      ? NetworkImage(member.avatarUrl)
                      : null,
                  child: member.avatarUrl.isEmpty ? Text(member.name[0]) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor(member.role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          member.role.replaceAll('_', ' '),
                          style: TextStyle(
                            color: _getRoleColor(member.role),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member.department ?? 'Engineering',
                        style: TextStyle(color: mutedText, fontSize: 11),
                      )
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Tasks',
                      style: TextStyle(color: mutedText, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$active',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completed',
                      style: TextStyle(color: mutedText, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completed',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Spacer(),

            // Workload Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Workload Intensity',
                  style: TextStyle(color: mutedText, fontSize: 11),
                ),
                Text(
                  'CURRENT FOCUS',
                  style: TextStyle(
                      color: mutedText,
                      fontSize: 9,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Progress Bar for Workload
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: workload / 100,
                      backgroundColor:
                          isDark ? Colors.grey.shade800 : Colors.blue.shade50,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.blue.shade300),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Circular Indicator for Focus
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        value: workload /
                            100, // Using workload as proxy for focus for now
                        strokeWidth: 3,
                        backgroundColor: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    Text(
                      '${workload.toInt()}%',
                      style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return Colors.purple;
      case 'MANAGER':
        return Colors.blue;
      case 'TEAM_LEAD':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
