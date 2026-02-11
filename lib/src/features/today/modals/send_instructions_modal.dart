import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project_pm/src/core/database/database.dart';
import 'package:project_pm/src/core/providers/user_providers.dart';
import 'package:project_pm/src/features/projects/project_providers.dart';

class SendInstructionsModal extends HookConsumerWidget {
  const SendInstructionsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allUsersAsync = ref.watch(allUsersProvider);
    final projectsAsync = ref.watch(projectsWithTasksProvider);

    final selectedProject = useState<String?>(null);
    final selectedRecipients = useState<List<User>>([]);
    final subjectController = useTextEditingController();
    final instructionsController = useTextEditingController();

    // Determine if submit is enabled
    final canSubmit = selectedRecipients.value.isNotEmpty &&
        instructionsController.text.isNotEmpty;
    // Rebuild when text changes to update button state
    useListenable(instructionsController);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.people_outline,
                    color: Colors.blue.shade600, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Send Team Instructions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filter & Add Recipient Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project Context Filter
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Filter: Project Context',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: selectedProject.value,
                            isExpanded: true,
                            hint: const Text('-- General / No Project --'),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('-- General / No Project --'),
                              ),
                              ...projectsAsync.when(
                                data: (projects) => projects.map((p) =>
                                    DropdownMenuItem(
                                        value: p.project.id,
                                        child: Text(p.project.name))),
                                loading: () => [],
                                error: (_, __) => [],
                              ),
                            ],
                            onChanged: (val) => selectedProject.value = val,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Add Recipient Dropdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add Recipient',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<User?>(
                            value: null, // Always reset after selection
                            isExpanded: true,
                            hint: const Text('+ Add Person...'),
                            items: [
                              const DropdownMenuItem<User?>(
                                value: null,
                                child: Text('+ Add Person...'),
                              ),
                              ...allUsersAsync.when(
                                data: (users) => users
                                    .where((u) => !selectedRecipients.value
                                        .any((r) => r.id == u.id))
                                    .map((u) => DropdownMenuItem(
                                        value: u, child: Text(u.name))),
                                loading: () => [],
                                error: (_, __) => [],
                              ),
                            ],
                            onChanged: (User? user) {
                              if (user != null) {
                                selectedRecipients.value = [
                                  ...selectedRecipients.value,
                                  user
                                ];
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recipients List
            Text.rich(
              TextSpan(
                text: 'Recipients ',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600),
                children: const [
                  TextSpan(text: '*', style: TextStyle(color: Colors.red))
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(minHeight: 60),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: isDark ? Colors.black12 : Colors.grey.shade50,
              ),
              child: selectedRecipients.value.isEmpty
                  ? Center(
                      child: Text(
                        'No recipients selected yet. Add from dropdown above.',
                        style: TextStyle(
                            color: Colors.grey.shade400,
                            fontStyle: FontStyle.italic,
                            fontSize: 13),
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedRecipients.value.map((user) {
                        return Chip(
                          label: Text(user.name,
                              style: const TextStyle(fontSize: 12)),
                          avatar: CircleAvatar(
                            backgroundImage: NetworkImage(user.avatarUrl),
                          ),
                          onDeleted: () {
                            selectedRecipients.value = selectedRecipients.value
                                .where((u) => u.id != user.id)
                                .toList();
                          },
                          backgroundColor:
                              isDark ? Colors.grey.shade700 : Colors.white,
                          side: BorderSide(color: Colors.grey.shade300),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 16),

            // Subject
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Subject / Title',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Plan for today, Urgent Task Update',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Instructions
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: 'Instructions / Day Plan ',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600),
                      children: const [
                        TextSpan(text: '*', style: TextStyle(color: Colors.red))
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: instructionsController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText:
                            'Outline the tasks, priorities, or feedback for the team...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                const Spacer(),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: canSubmit
                      ? () {
                          // TODO: Implement actual email sending logic
                          debugPrint(
                              'Sending instructions to ${selectedRecipients.value.length} recipients');
                          debugPrint('Subject: ${subjectController.text}');
                          debugPrint('Body: ${instructionsController.text}');
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Instructions sent to ${selectedRecipients.value.length} people!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.send, size: 18),
                  label:
                      Text('Send Email (${selectedRecipients.value.length})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B7280), // Grayish
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
