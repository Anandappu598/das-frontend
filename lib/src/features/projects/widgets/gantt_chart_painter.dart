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

  GanttChartPainter({
    required this.tasks,
    required this.projectStart,
    required this.projectEnd,
    required this.dayWidth,
    required this.rowHeight,
    required this.headerHeight,
    required this.taskNameWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    final totalDays = projectEnd.difference(projectStart).inDays + 1;

    // 0. Draw "Item" Header Text (Top-Left)
    // Text "Item"
    textPainter.text = const TextSpan(
      text: "Item",
      style: TextStyle(
          color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(16, (headerHeight - textPainter.height) / 2));

    // 1. Draw Grid Background (Vertical Lines for Days)
    paint.color = Colors.grey.shade200;
    paint.strokeWidth = 1.0;

    for (int i = 0; i <= totalDays; i++) {
      final x = taskNameWidth + (i * dayWidth);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 2. Draw Header (Days)
    // Background for header
    paint.color = Colors.white;
    canvas.drawRect(
        Rect.fromLTWH(
            taskNameWidth, 0, size.width - taskNameWidth, headerHeight),
        paint);

    // Bottom border for header
    paint.color = Colors.grey.shade300;
    paint.strokeWidth = 1.0;
    canvas.drawLine(
        Offset(0, headerHeight), Offset(size.width, headerHeight), paint);

    // Vertical Separator (Task Name | Timeline) - Draw this earlier or over header?
    // Let's draw it over the header background but under text?
    // Actually, drawing it at the end is fine, but we need it to cover the header area too if we want a full split.

    // Header Text
    for (int i = 0; i < totalDays; i++) {
      final date = projectStart.add(Duration(days: i));
      final x = taskNameWidth + (i * dayWidth);

      // Draw weekend background
      if (date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday) {
        paint.color = Colors.grey.shade50;
        canvas.drawRect(
            Rect.fromLTWH(
                x, headerHeight, dayWidth, size.height - headerHeight),
            paint);
      }

      // Day number and Month (MMM d)
      // Screenshot shows "Jul 25", "Jul 26"...
      // We can fit "Jul 25" if dayWidth is enough.
      textPainter.text = TextSpan(
        text: DateFormat('MMM d').format(date),
        style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
            fontWeight: FontWeight.w500),
      );
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(x + (dayWidth - textPainter.width) / 2,
              (headerHeight - textPainter.height) / 2));
    }

    // 3. Draw Task Rows
    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i].task;
      final y = headerHeight + (i * rowHeight);

      // Row Separator (Horizontal)
      paint.color = Colors.grey.shade100;
      // Don't draw over the task name area if we want a clean look, or draw full width.
      // Screenshot implies light lines.
      canvas.drawLine(
          Offset(0, y + rowHeight), Offset(size.width, y + rowHeight), paint);

      // Task Name
      textPainter.text = TextSpan(
        text: task.name,
        style: const TextStyle(
            color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
      );
      textPainter.layout(maxWidth: taskNameWidth - 32);
      textPainter.paint(
          canvas, Offset(16, y + (rowHeight - textPainter.height) / 2));

      // Task Bar
      final startOffset = task.startDate.difference(projectStart).inDays;
      final duration = task.endDate.difference(task.startDate).inDays + 1;

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
          style: const TextStyle(
              color: Colors.black87, fontSize: 10, fontWeight: FontWeight.w600),
        );
        textPainter.layout(maxWidth: barWidth - 8);
        // Check if text fits, if not maybe just progress?
        // For now let's prioritize the name as per screenshot style implies "Product Detail Page" inside.
        textPainter.paint(canvas,
            Offset(barX + 8, barTop + (barHeight - textPainter.height) / 2));
      }
    }

    // 4. Vertical Separator (Task Name | Timeline)
    paint.color = Colors.grey.shade300;
    canvas.drawLine(
        Offset(taskNameWidth, 0), Offset(taskNameWidth, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant GanttChartPainter oldDelegate) {
    return oldDelegate.tasks != tasks ||
        oldDelegate.dayWidth != dayWidth ||
        oldDelegate.projectStart != projectStart;
  }
}
