import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:project_pm/src/core/models/project_with_tasks.dart';
import 'package:intl/intl.dart';

class GanttChartPainter extends CustomPainter {
  final List<TaskWithAssignees> tasks;
  final DateTime projectStart;
  final DateTime projectEnd;
  final double dayWidth;
  final double rowHeight;
  final double headerHeight;
  final double taskNameWidth;
  final bool isDark;

  GanttChartPainter({
    required this.tasks,
    required this.projectStart,
    required this.projectEnd,
    required this.dayWidth,
    required this.rowHeight,
    required this.headerHeight,
    required this.taskNameWidth,
    required this.isDark,
  });

  // Helper method to count working days (excluding Sundays)
  int _countWorkingDays(DateTime start, DateTime end) {
    int count = 0;
    for (var date = start;
        date.isBefore(end) || date.isAtSameMomentAs(end);
        date = date.add(const Duration(days: 1))) {
      if (date.weekday != DateTime.sunday) {
        count++;
      }
    }
    return count;
  }

  // Helper method to get working day offset (excluding Sundays)
  int _getWorkingDayOffset(DateTime start, DateTime target) {
    int count = 0;
    for (var date = start;
        date.isBefore(target);
        date = date.add(const Duration(days: 1))) {
      if (date.weekday != DateTime.sunday) {
        count++;
      }
    }
    return count;
  }

  // Helper method to get avatar color based on index
  Color _getAvatarColor(int index) {
    final colors = [
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Green
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFF59E0B), // Orange
      const Color(0xFFEC4899), // Pink
      const Color(0xFF6366F1), // Indigo
    ];
    return colors[index % colors.length];
  }

  // Helper method to get initials from name
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    final totalDays = projectEnd.difference(projectStart).inDays + 1;
    final totalWorkingDays = _countWorkingDays(projectStart, projectEnd);

    // 0. Draw "Item" Header Text (Top-Left)
    // Text "Item"
    textPainter.text = TextSpan(
      text: "Item",
      style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(16, (headerHeight - textPainter.height) / 2));

    // 1. Draw Grid Background (Vertical Lines for Working Days only)
    paint.color = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    paint.strokeWidth = 1.0;

    int workingDayIndex = 0;
    for (int i = 0; i < totalDays; i++) {
      final date = projectStart.add(Duration(days: i));
      if (date.weekday == DateTime.sunday) {
        continue; // Skip Sundays
      }
      final x = taskNameWidth + (workingDayIndex * dayWidth);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      workingDayIndex++;
    }
    // Draw final line
    final x = taskNameWidth + (workingDayIndex * dayWidth);
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);

    // 2. Draw Header (Days)
    // Background for header
    paint.color = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    canvas.drawRect(
        Rect.fromLTWH(
            taskNameWidth, 0, size.width - taskNameWidth, headerHeight),
        paint);

    // Bottom border for header
    paint.color = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    paint.strokeWidth = 1.0;
    canvas.drawLine(
        Offset(0, headerHeight), Offset(size.width, headerHeight), paint);

    // Header Text (excluding Sundays)
    workingDayIndex = 0;
    for (int i = 0; i < totalDays; i++) {
      final date = projectStart.add(Duration(days: i));

      // Skip Sundays completely
      if (date.weekday == DateTime.sunday) {
        continue;
      }

      final x = taskNameWidth + (workingDayIndex * dayWidth);

      // Draw weekend background for Saturdays only
      if (date.weekday == DateTime.saturday) {
        paint.color = isDark ? Colors.grey.shade900 : Colors.grey.shade50;
        canvas.drawRect(
            Rect.fromLTWH(
                x, headerHeight, dayWidth, size.height - headerHeight),
            paint);
      }

      // Day number and Month (MMM d)
      textPainter.text = TextSpan(
        text: DateFormat('MMM d').format(date),
        style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontSize: 10,
            fontWeight: FontWeight.w500),
      );
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(x + (dayWidth - textPainter.width) / 2,
              (headerHeight - textPainter.height) / 2));

      workingDayIndex++;
    }

    // 3. Draw Task Rows
    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i].task;
      final y = headerHeight + (i * rowHeight);

      // Row Separator (Horizontal)
      paint.color = isDark ? Colors.grey.shade800 : Colors.grey.shade100;
      canvas.drawLine(
          Offset(0, y + rowHeight), Offset(size.width, y + rowHeight), paint);

      // Task Name
      textPainter.text = TextSpan(
        text: task.name,
        style: TextStyle(
            color: isDark ? Colors.grey.shade300 : Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w500),
      );
      textPainter.layout(maxWidth: taskNameWidth - 32);
      textPainter.paint(
          canvas, Offset(16, y + (rowHeight - textPainter.height) / 2));

      // Task Bar (calculated using working days only)
      final startOffset = _getWorkingDayOffset(projectStart, task.startDate);
      final duration = _countWorkingDays(task.startDate, task.endDate);

      final barX = taskNameWidth + (startOffset * dayWidth);
      final barWidth = duration * dayWidth;

      // Vertical margins for bar
      final barHeight = rowHeight * 0.6;
      final barTop = y + (rowHeight - barHeight) / 2;

      final barRect = Rect.fromLTWH(barX, barTop, barWidth - 2, barHeight);

      final today = DateTime.now();
      final isLate = task.endDate.isBefore(today) && task.progress < 100;

      if (isLate) {
        paint.color = const Color(0xFFFFCDD2); // Light red
      } else {
        // Screenshot: Blue for in-progress/standard, maybe Green for done?
        // Using Blue 400 for standard as per code
        paint.color = task.progress >= 100
            ? Colors.green.shade400
            : const Color(0xFF60A5FA);
      }

      final rrect = RRect.fromRectAndRadius(barRect, const Radius.circular(4));
      canvas.drawRRect(rrect, paint);

      // Task Name inside bar? No, logic was progress text.
      // Screenshot shows "Product Detail Page" INSIDE the bar too?
      // The screenshot has "Product Detail Page" in the Item column AND inside the blue bar.
      // Let's add that if width permits.

      if (barWidth > 50) {
        // Draw Text inside bar
        textPainter.text = TextSpan(
          text: task.name,
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 10,
              fontWeight: FontWeight.w600),
        );
        textPainter.layout(maxWidth: barWidth - 8);
        // Check if text fits, if not maybe just progress?
        // For now let's prioritize the name as per screenshot style implies "Product Detail Page" inside.
        textPainter.paint(canvas,
            Offset(barX + 8, barTop + (barHeight - textPainter.height) / 2));
      }

      // Draw Assignee Avatars at the end of the bar (always show)
      final assignees = tasks[i].assignees;
      final avatarRadius = 12.0;
      final avatarSpacing = 4.0;
      final maxAvatars = 3; // Show max 3 avatars

      // Show avatars if bar is wide enough (at least 40px for one avatar)
      if (barWidth > 40) {
        // If no assignees, show empty profile
        if (assignees.isEmpty) {
          final avatarCenter = Offset(
              barX + barWidth - avatarRadius - 4, barTop + (barHeight / 2));

          // Draw empty profile circle
          paint.color = Colors.grey.shade600;
          canvas.drawCircle(avatarCenter, avatarRadius, paint);

          // Draw white border
          paint.color = Colors.white;
          paint.style = PaintingStyle.stroke;
          paint.strokeWidth = 2;
          canvas.drawCircle(avatarCenter, avatarRadius, paint);
          paint.style = PaintingStyle.fill;

          // Draw person icon/placeholder
          textPainter.text = const TextSpan(
            text: '?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(
              avatarCenter.dx - (textPainter.width / 2),
              avatarCenter.dy - (textPainter.height / 2),
            ),
          );
        } else {
          // Show assignee avatars
          final avatarsToShow =
              assignees.length > maxAvatars ? maxAvatars : assignees.length;
          final totalAvatarWidth = (avatarsToShow * (avatarRadius * 2)) -
              ((avatarsToShow - 1) * (avatarRadius - avatarSpacing));

          var avatarX = barX + barWidth - totalAvatarWidth - 8;

          for (int j = 0; j < avatarsToShow; j++) {
            final assignee = assignees[j];
            final avatarCenter =
                Offset(avatarX + avatarRadius, barTop + (barHeight / 2));

            // Draw avatar circle background
            paint.color = _getAvatarColor(j);
            canvas.drawCircle(avatarCenter, avatarRadius, paint);

            // Draw white border
            paint.color = Colors.white;
            paint.style = PaintingStyle.stroke;
            paint.strokeWidth = 2;
            canvas.drawCircle(avatarCenter, avatarRadius, paint);
            paint.style = PaintingStyle.fill;

            // Draw initials
            final initials = _getInitials(assignee.name);
            textPainter.text = TextSpan(
              text: initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            );
            textPainter.layout();
            textPainter.paint(
              canvas,
              Offset(
                avatarCenter.dx - (textPainter.width / 2),
                avatarCenter.dy - (textPainter.height / 2),
              ),
            );

            avatarX += (avatarRadius * 2) - avatarSpacing;
          }

          // Show "+N" if more assignees
          if (assignees.length > maxAvatars) {
            final moreCount = assignees.length - maxAvatars;
            final moreCenter =
                Offset(avatarX + avatarRadius, barTop + (barHeight / 2));

            paint.color = Colors.grey.shade600;
            canvas.drawCircle(moreCenter, avatarRadius, paint);

            paint.color = Colors.white;
            paint.style = PaintingStyle.stroke;
            paint.strokeWidth = 2;
            canvas.drawCircle(moreCenter, avatarRadius, paint);
            paint.style = PaintingStyle.fill;

            textPainter.text = TextSpan(
              text: '+$moreCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            );
            textPainter.layout();
            textPainter.paint(
              canvas,
              Offset(
                moreCenter.dx - (textPainter.width / 2),
                moreCenter.dy - (textPainter.height / 2),
              ),
            );
          }
        }
      }
    }

    // 4. Vertical Separator (Task Name | Timeline)
    paint.color = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    canvas.drawLine(
        Offset(taskNameWidth, 0), Offset(taskNameWidth, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant GanttChartPainter oldDelegate) {
    // Always repaint to ensure Sunday filtering is applied
    return true;
  }
}
