import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project_pm/src/core/database/database.dart';
import 'package:project_pm/src/features/projects/project_providers.dart';
import 'package:drift/drift.dart' as drift;

class TaskDetailModal extends HookConsumerWidget {
  final Task task;

  const TaskDetailModal({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressState = useState(task.progress.toDouble());
    final statusController = useTextEditingController(text: task.priority);

    return AlertDialog(
      title: Text(task.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Status: ${task.approvalStatus}"),
          const SizedBox(height: 16),
          const Text("Progress"),
          Slider(
            value: progressState.value,
            min: 0,
            max: 100,
            divisions: 100,
            label: progressState.value.round().toString(),
            onChanged: (val) => progressState.value = val,
          ),
          TextField(
              controller: statusController,
              decoration: const InputDecoration(labelText: 'Priority')),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
        FilledButton(
          onPressed: () async {
            final updated = TasksCompanion(
              id: drift.Value(task.id),
              progress: drift.Value(progressState.value.toInt()),
              priority: drift.Value(statusController.text),
            );
            await ref.read(projectRepositoryProvider).updateTask(updated);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
