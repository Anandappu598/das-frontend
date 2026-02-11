import 'package:auto_route/auto_route.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_pm/src/core/database/database.dart';
import 'package:project_pm/src/features/auth/auth_providers.dart';
import 'package:project_pm/src/features/auth/user_repository.dart';

@RoutePage()
class AdminUserManagementPage extends HookConsumerWidget {
  const AdminUserManagementPage({super.key});

  static const List<String> roles = [
    'ADMIN',
    'MANAGER',
    'TEAM_LEAD',
    'EMPLOYEE'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersSnapshot = ref.watch(allUsersStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabController = useTabController(initialLength: 3);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.grey.shade50,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              border: Border(
                bottom: BorderSide(
                    color:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Control Center',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark ? Colors.white : Colors.grey.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage users, system configurations, and security.',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateUserDialog(context, ref),
                      icon: const Icon(Icons.person_add_outlined, size: 20),
                      label: const Text('Create User'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TabBar(
                  controller: tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: const Color(0xFF4F46E5),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF4F46E5),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(
                        child: Text('Users & Hierarchy',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600))),
                    Tab(
                        child: Text('System Settings',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600))),
                    Tab(
                        child: Text('Security & Logs',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600))),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                // Users Tab
                usersSnapshot.when(
                  data: (users) => SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _StatsSummary(users: users, isDark: isDark),
                        const SizedBox(height: 24),
                        _UserManagementCard(
                          users: users,
                          userRepo: ref.read(userRepositoryProvider),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text("Error: $e")),
                ),
                // Settings Tab
                const _SystemSettingsTab(),
                // Logs Tab (Placeholder)
                const _SecurityLogsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateUserDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _CreateUserDialog(
        onCreated: (newUser) {
          ref.read(userRepositoryProvider).addUser(newUser);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User created successfully')),
          );
        },
      ),
    );
  }
}

class _UserManagementCard extends StatelessWidget {
  final List<User> users;
  final UserRepository userRepo;
  final bool isDark;

  const _UserManagementCard({
    required this.users,
    required this.userRepo,
    required this.isDark,
  });

  Color _getRoleBadgeColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return Colors.purple;
      case 'MANAGER':
        return Colors.blue;
      case 'TEAM_LEAD':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Management & Hierarchy',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage user roles, departments, and reporting lines.',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          Divider(
              height: 1,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),

          // Table Header
          Container(
            color: isDark
                ? Colors.grey.shade900.withValues(alpha: 0.5)
                : Colors.grey.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: const Row(
              children: [
                _TableHeader('User', flex: 2),
                _TableHeader('Role', flex: 1),
                _TableHeader('Department', flex: 1),
                _TableHeader('Reporting Manager', flex: 2),
                _TableHeader('Email', flex: 2),
              ],
            ),
          ),

          Divider(
              height: 1,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),

          // Table Body
          ...users.map((user) => _UserRow(
                user: user,
                allUsers: users,
                userRepo: userRepo,
                isDark: isDark,
                getRoleBadgeColor: _getRoleBadgeColor,
              )),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  final int flex;

  const _TableHeader(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final User user;
  final List<User> allUsers;
  final UserRepository userRepo;
  final bool isDark;
  final Color Function(String) getRoleBadgeColor;

  const _UserRow({
    required this.user,
    required this.allUsers,
    required this.userRepo,
    required this.isDark,
    required this.getRoleBadgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.grey.shade800.withValues(alpha: 0.5)
                : Colors.grey.shade100,
          ),
        ),
      ),
      child: Row(
        children: [
          // User Column
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: user.avatarUrl.isNotEmpty
                      ? NetworkImage(user.avatarUrl)
                      : null,
                  onBackgroundImageError: (_, __) {},
                  child: user.avatarUrl.isEmpty ? Text(user.name[0]) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.grey.shade900,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        user.id,
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Role Column
          Expanded(
            flex: 1,
            child: _RoleDropdown(
              currentRole: user.role,
              badgeColor: getRoleBadgeColor(user.role),
              onChanged: (newRole) {
                if (newRole != null) {
                  userRepo.updateUser(UsersCompanion(
                    id: drift.Value(user.id),
                    role: drift.Value(newRole),
                  ));
                }
              },
            ),
          ),

          // Department Column
          Expanded(
            flex: 1,
            child: Text(
              user.department ?? '-',
              style: TextStyle(
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),

          // Reporting Manager Column
          Expanded(
            flex: 2,
            child: _ManagerDropdown(
              currentManagerId: user.reportingManagerId,
              allUsers: allUsers.where((u) => u.id != user.id).toList(),
              onChanged: (newManagerId) {
                userRepo.updateUser(UsersCompanion(
                  id: drift.Value(user.id),
                  reportingManagerId: drift.Value(newManagerId),
                ));
              },
            ),
          ),

          // Email Column
          Expanded(
            flex: 2,
            child: Text(
              user.email,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  final String currentRole;
  final Color badgeColor;
  final ValueChanged<String?> onChanged;

  const _RoleDropdown({
    required this.currentRole,
    required this.badgeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: isDark ? 0.3 : 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        value: currentRole.toUpperCase(),
        isDense: true,
        underline: const SizedBox(),
        icon: Icon(Icons.arrow_drop_down, size: 16, color: badgeColor),
        style: TextStyle(
          color: badgeColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
        items: AdminUserManagementPage.roles.map((role) {
          return DropdownMenuItem(value: role, child: Text(role));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _StatsSummary extends StatelessWidget {
  final List<User> users;
  final bool isDark;

  const _StatsSummary({required this.users, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total = users.length;
    final admins = users.where((u) => u.role == 'ADMIN').length;
    final managers = users.where((u) => u.role == 'MANAGER').length;
    final leads = users.where((u) => u.role == 'TEAM_LEAD').length;

    return Row(
      children: [
        _StatCard(
            'Total Users', total.toString(), Icons.people, Colors.blue, isDark),
        const SizedBox(width: 16),
        _StatCard(
            'Admins', admins.toString(), Icons.shield, Colors.purple, isDark),
        const SizedBox(width: 16),
        _StatCard('Managers', managers.toString(), Icons.business_center,
            Colors.indigo, isDark),
        const SizedBox(width: 16),
        _StatCard(
            'Team Leads', leads.toString(), Icons.groups, Colors.green, isDark),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard(this.title, this.value, this.icon, this.color, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade500,
                        fontSize: 12)),
                Text(value,
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateUserDialog extends HookConsumerWidget {
  final ValueChanged<UsersCompanion> onCreated;

  const _CreateUserDialog({required this.onCreated});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final emailController = useTextEditingController();
    final deptController = useTextEditingController();
    final selectedRole = useState('EMPLOYEE');

    return AlertDialog(
      title: const Text('Create New User'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email Address'),
            ),
            TextField(
              controller: deptController,
              decoration: const InputDecoration(labelText: 'Department'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedRole.value,
              decoration: const InputDecoration(labelText: 'Initial Role'),
              items: AdminUserManagementPage.roles
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (val) => selectedRole.value = val!,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final companion = UsersCompanion.insert(
              id: 'u${DateTime.now().millisecondsSinceEpoch}',
              name: nameController.text,
              email: emailController.text,
              avatarUrl: '',
              role: selectedRole.value,
              department: drift.Value(deptController.text),
            );
            onCreated(companion);
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _SystemSettingsTab extends StatelessWidget {
  const _SystemSettingsTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsSection(
            title: 'General Configurations',
            isDark: isDark,
            children: [
              _SettingToggle(
                title: 'Maintenance Mode',
                subtitle: 'Disable all user access except for Admins.',
                value: false,
                onChanged: (_) {},
              ),
              _SettingToggle(
                title: 'Allow Self-Registration',
                subtitle: 'Enable users to sign up without invitation.',
                value: true,
                onChanged: (_) {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'AI & Experimental',
            isDark: isDark,
            children: [
              _SettingToggle(
                title: 'Show AI Assistant',
                subtitle: 'Enable the side-chat AI in the dashboard.',
                value: true,
                onChanged: (_) {},
              ),
              _SettingToggle(
                title: 'Gantt Chart Beta',
                subtitle: 'Enable advanced timeline view for all projects.',
                value: true,
                onChanged: (_) {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isDark;

  const _SettingsSection({
    required this.title,
    required this.children,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black),
            ),
          ),
          Divider(
              height: 1,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          ...children,
        ],
      ),
    );
  }
}

class _SettingToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SwitchListTile(
      title: Text(title,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black)),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFF4F46E5),
    );
  }
}

class _SecurityLogsTab extends StatelessWidget {
  const _SecurityLogsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.security, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text("Security Logs & Audit Trail",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 18)),
          const SizedBox(height: 8),
          Text("This section will track all administrative actions.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ManagerDropdown extends StatelessWidget {
  final String? currentManagerId;
  final List<User> allUsers;
  final ValueChanged<String?> onChanged;

  const _ManagerDropdown({
    required this.currentManagerId,
    required this.allUsers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        value: currentManagerId ?? '',
        isDense: true,
        underline: const SizedBox(),
        isExpanded: true,
        icon:
            Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey.shade500),
        style: TextStyle(
          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          fontSize: 12,
        ),
        dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
        items: [
          const DropdownMenuItem(value: '', child: Text('None (Top Level)')),
          ...allUsers.map((u) {
            return DropdownMenuItem(
              value: u.id,
              child: Text('${u.name} (${u.role})',
                  overflow: TextOverflow.ellipsis),
            );
          }),
        ],
        onChanged: (val) => onChanged(val?.isEmpty == true ? null : val),
      ),
    );
  }
}
