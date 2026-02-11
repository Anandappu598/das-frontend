import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project_pm/src/core/theme/theme_provider.dart';

class AppHeader extends ConsumerWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onMenuTap; // For mobile hamburger menu

  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 16 : 24,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Row(
        children: [
          // Hamburger menu for mobile
          if (onMenuTap != null) ...[
            IconButton(
              onPressed: onMenuTap,
              icon: Icon(
                Icons.menu,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
              tooltip: 'Menu',
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 20 : null,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: isMobile ? 12 : null,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),

          // Actions - hide some on mobile
          if (!isMobile)
            Row(
              children: [
                // Notification Bell
                _NotificationButton(isDark: isDark),
                const SizedBox(width: 16),

                // Theme Switcher - 3 buttons like React
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _ThemeButton(
                        icon: FontAwesomeIcons.sun,
                        isActive: currentTheme == AppThemeMode.light,
                        onTap: () => ref
                            .read(themeNotifierProvider.notifier)
                            .setTheme(AppThemeMode.light),
                        tooltip: 'Light Mode',
                        isDark: isDark,
                      ),
                      _ThemeButton(
                        icon: FontAwesomeIcons.moon,
                        isActive: currentTheme == AppThemeMode.dark,
                        onTap: () => ref
                            .read(themeNotifierProvider.notifier)
                            .setTheme(AppThemeMode.dark),
                        tooltip: 'Dark Mode',
                        isDark: isDark,
                      ),
                      _ThemeButton(
                        icon: FontAwesomeIcons.laptop,
                        isActive: currentTheme == AppThemeMode.system,
                        onTap: () => ref
                            .read(themeNotifierProvider.notifier)
                            .setTheme(AppThemeMode.system),
                        tooltip: 'System Theme',
                        isDark: isDark,
                      ),
                    ],
                  ),
                )
              ],
            )
          else
            // Just notification bell on mobile
            _NotificationButton(isDark: isDark),
        ],
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final String tooltip;
  final bool isDark;

  const _ThemeButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.tooltip,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? Colors.grey.shade700 : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 14,
            color: isActive
                ? Colors.blue.shade600
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade500),
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatefulWidget {
  final bool isDark;

  const _NotificationButton({required this.isDark});

  @override
  State<_NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<_NotificationButton> {
  bool isOpen = false;
  final int unreadCount = 3; // Mock unread count

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () {
            setState(() => isOpen = !isOpen);
            if (isOpen) {
              _showNotificationPanel(context);
            }
          },
          icon: Icon(
            FontAwesomeIcons.bell,
            color: widget.isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          tooltip: 'Notifications',
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red.shade500,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showNotificationPanel(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          Positioned(
            top: 80,
            right: 120,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 360,
                constraints: const BoxConstraints(maxHeight: 400),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isDark
                        ? Colors.grey.shade700
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Notifications',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Mark all as read'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Mock notifications
                    _NotificationItem(
                      title: 'Task Assigned',
                      message:
                          'You have been assigned to "User Authentication"',
                      time: '2 min ago',
                      isUnread: true,
                      isDark: widget.isDark,
                    ),
                    _NotificationItem(
                      title: 'Approval Required',
                      message: 'New task pending your approval',
                      time: '1 hour ago',
                      isUnread: true,
                      isDark: widget.isDark,
                    ),
                    _NotificationItem(
                      title: 'Comment Added',
                      message: 'Diana commented on Feed Page task',
                      time: '3 hours ago',
                      isUnread: false,
                      isDark: widget.isDark,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('View all notifications'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final bool isUnread;
  final bool isDark;

  const _NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.isUnread,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnread
            ? (isDark
                ? Colors.blue.shade900.withValues(alpha: 0.2)
                : Colors.blue.shade50)
            : null,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isUnread)
            Container(
              margin: const EdgeInsets.only(top: 6, right: 8),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.blue.shade500,
                shape: BoxShape.circle,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
