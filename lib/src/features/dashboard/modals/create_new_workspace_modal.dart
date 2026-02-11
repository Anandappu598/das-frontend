import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:project_pm/src/core/database/database.dart';
import 'package:project_pm/src/features/projects/project_providers.dart';
import 'package:project_pm/src/core/providers/user_providers.dart';
import 'package:intl/intl.dart';

enum CreationStep { type, details, tasks }

enum WorkspaceType { project, course, routine }

/// Helper model for temporary tasks during creation
class _TempTask {
  String name;
  String priority;
  DateTime? startDate;
  DateTime? endDate;
  List<String> assignees; // User IDs
  List<String> milestones;

  _TempTask({
    required this.name,
    this.priority = 'Medium',
    this.startDate,
    this.endDate,
    this.assignees = const [],
    this.milestones = const [],
  });
}

class CreateNewWorkspaceModal extends HookConsumerWidget {
  const CreateNewWorkspaceModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = useState(CreationStep.type);
    final selectedType = useState<WorkspaceType?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Fetch Users for Assignees
    final allUsersAsync = ref.watch(allUsersProvider);

    // Common Controllers
    final nameController = useTextEditingController();
    final descriptionController = useTextEditingController();

    // Project Specific
    final projectLeadController = useTextEditingController();
    final projectDeadline = useState<DateTime?>(null);

    // Project Date Controllers (Hoisted to avoid Hook crash)
    final deadlineController = useTextEditingController(
      text: projectDeadline.value != null
          ? DateFormat('MM/dd/yyyy').format(projectDeadline.value!)
          : '',
    );
    // Effects to sync controllers with state
    useEffect(() {
      deadlineController.text = projectDeadline.value != null
          ? DateFormat('MM/dd/yyyy').format(projectDeadline.value!)
          : '';
      return null;
    }, [projectDeadline.value]);

    // Task Planning State
    final taskList = useState<List<_TempTask>>([]);
    final taskNameController = useTextEditingController();
    final taskPriority = useState<String>('Medium');
    final taskStartDate = useState<DateTime?>(null);
    final taskEndDate = useState<DateTime?>(null);
    final taskAssignees = useState<List<String>>([]);
    final taskMilestones = useState<List<String>>([]);
    final milestoneController = useTextEditingController();

    // Task Date Controllers (Hoisted)
    final taskStartController = useTextEditingController(
      text: taskStartDate.value != null
          ? DateFormat('MM/dd').format(taskStartDate.value!)
          : '',
    );
    final taskEndController = useTextEditingController(
      text: taskEndDate.value != null
          ? DateFormat('MM/dd').format(taskEndDate.value!)
          : '',
    );
    // Sync Task Date Controllers
    useEffect(() {
      taskStartController.text = taskStartDate.value != null
          ? DateFormat('MM/dd').format(taskStartDate.value!)
          : '';
      return null;
    }, [taskStartDate.value]);
    useEffect(() {
      taskEndController.text = taskEndDate.value != null
          ? DateFormat('MM/dd').format(taskEndDate.value!)
          : '';
      return null;
    }, [taskEndDate.value]);

    // Course Specific Controllers
    final subjectCodeController = useTextEditingController();
    final instructorController = useTextEditingController();
    final scheduleController = useTextEditingController();

    // Routine Specific Controllers
    final routineCategory = useState<String?>('Work');
    final routineFrequency = useState<String?>('Daily');

    void goBack() {
      if (step.value == CreationStep.tasks) {
        step.value = CreationStep.details;
      } else if (step.value == CreationStep.details) {
        step.value = CreationStep.type;
      }
    }

    void selectType(WorkspaceType type) {
      selectedType.value = type;
      step.value = CreationStep.details;
    }

    // Helper to pick date
    Future<void> pickDate(
        BuildContext context, ValueNotifier<DateTime?> dateState) async {
      final picked = await showDatePicker(
        context: context,
        initialDate: dateState.value ?? DateTime.now(),
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      );
      if (picked != null) {
        dateState.value = picked;
      }
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;
          final dialogWidth = isNarrow ? constraints.maxWidth : 900.0;
          final dialogHeight = isNarrow ? constraints.maxHeight * 0.95 : 800.0;

          return Container(
            width: dialogWidth,
            height: dialogHeight,
            constraints: BoxConstraints(
              maxWidth: 900,
              maxHeight: constraints.maxHeight * 0.95,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(32, 28, 32, 20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1F2937)
                        : const Color(0xFFF9FAFB),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (step.value != CreationStep.type)
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: InkWell(
                            onTap: goBack,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(Icons.arrow_back_rounded,
                                  color: isDark
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade700),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Create New Workspace",
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111827),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _Breadcrumb(
                              currentStep: step.value,
                              isDark: isDark,
                              isProject:
                                  selectedType.value == WorkspaceType.project,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                        color: Colors.grey.shade400,
                        splashRadius: 24,
                      ),
                    ],
                  ),
                ),

                // Body
                Expanded(
                  child: step.value == CreationStep.tasks
                      ? Padding(
                          padding: EdgeInsets.all(isNarrow ? 20.0 : 40.0),
                          child: _buildBody(
                            context,
                            ref,
                            step.value,
                            isDark,
                            selectedType.value,
                            selectType,
                            nameController,
                            descriptionController,
                            projectLeadController,
                            projectDeadline,
                            deadlineController,
                            // Task Props
                            taskList,
                            taskNameController,
                            taskPriority,
                            taskStartDate,
                            taskEndDate,
                            taskStartController,
                            taskEndController,
                            taskAssignees,
                            taskMilestones,
                            milestoneController,
                            allUsersAsync,
                            // Course Props
                            subjectCodeController,
                            instructorController,
                            scheduleController,
                            // Routine Props
                            routineCategory,
                            routineFrequency,
                            goBack,
                            (state) => pickDate(context, state),
                            () {
                              step.value = CreationStep.tasks;
                            },
                          ),
                        )
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(isNarrow ? 20.0 : 40.0),
                          child: _buildBody(
                            context,
                            ref,
                            step.value,
                            isDark,
                            selectedType.value,
                            selectType,
                            nameController,
                            descriptionController,
                            projectLeadController,
                            projectDeadline,
                            deadlineController,
                            // Task Props
                            taskList,
                            taskNameController,
                            taskPriority,
                            taskStartDate,
                            taskEndDate,
                            taskStartController,
                            taskEndController,
                            taskAssignees,
                            taskMilestones,
                            milestoneController,
                            allUsersAsync,
                            // Course Props
                            subjectCodeController,
                            instructorController,
                            scheduleController,
                            // Routine Props
                            routineCategory,
                            routineFrequency,
                            goBack,
                            (state) => pickDate(context, state),
                            () {
                              step.value = CreationStep.tasks;
                            },
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    CreationStep step,
    bool isDark,
    WorkspaceType? selectedType,
    Function(WorkspaceType) onSelectType,
    TextEditingController nameController,
    TextEditingController descController,
    TextEditingController projectLeadController,
    ValueNotifier<DateTime?> projectDeadline,
    TextEditingController deadlineController,
    // Task Props
    ValueNotifier<List<_TempTask>> taskList,
    TextEditingController taskNameController,
    ValueNotifier<String> taskPriority,
    ValueNotifier<DateTime?> taskStartDate,
    ValueNotifier<DateTime?> taskEndDate,
    TextEditingController taskStartController,
    TextEditingController taskEndController,
    ValueNotifier<List<String>> taskAssignees,
    ValueNotifier<List<String>> taskMilestones,
    TextEditingController milestoneController,
    AsyncValue<List<User>> allUsersAsync,
    // Course Props
    TextEditingController subjectCodeController,
    TextEditingController instructorController,
    TextEditingController scheduleController,
    // Routine Props
    ValueNotifier<String?> routineCategory,
    ValueNotifier<String?> routineFrequency,
    VoidCallback onBack,
    Function(ValueNotifier<DateTime?>) onPickDate,
    VoidCallback onStartPlanning,
  ) {
    switch (step) {
      case CreationStep.type:
        return LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              SizedBox(
                width: isWide
                    ? (constraints.maxWidth - 48) / 3
                    : constraints.maxWidth,
                child: _SelectionCard(
                  title: "Dev Project",
                  description:
                      "Software, Design, Marketing tasks with deadlines.",
                  icon: FontAwesomeIcons.code,
                  isSelected: selectedType == WorkspaceType.project,
                  isDark: isDark,
                  onTap: () => onSelectType(WorkspaceType.project),
                ),
              ),
              SizedBox(
                width: isWide
                    ? (constraints.maxWidth - 48) / 3
                    : constraints.maxWidth,
                child: _SelectionCard(
                  title: "Class / Course",
                  description: "Syllabus, Lessons, and Training Modules.",
                  icon: FontAwesomeIcons.graduationCap,
                  isSelected: selectedType == WorkspaceType.course,
                  isDark: isDark,
                  onTap: () => onSelectType(WorkspaceType.course),
                ),
              ),
              SizedBox(
                width: isWide
                    ? (constraints.maxWidth - 48) / 3
                    : constraints.maxWidth,
                child: _SelectionCard(
                  title: "Routine Group",
                  description: "Recurring meetings, CRM, and daily admin.",
                  icon: FontAwesomeIcons.mugHot,
                  isSelected: selectedType == WorkspaceType.routine,
                  isDark: isDark,
                  onTap: () => onSelectType(WorkspaceType.routine),
                ),
              ),
            ],
          );
        });

      case CreationStep.details:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Badge(
                    label: _getWorkspaceLabel(selectedType!), isDark: isDark),
              ],
            ),
            const SizedBox(height: 32),

            // Dynamic Fields based on Type
            if (selectedType == WorkspaceType.project) ...[
              _buildTextField(
                  nameController, "Project Name", "e.g. Q3 Marketing Plan"),
              const SizedBox(height: 24),
              _buildTextField(
                  descController, "Description / Goal", "Brief description...",
                  maxLines: 4),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                        projectLeadController, "Project Lead", "e.g. John Doe",
                        suffixIcon: Icons.person_outline_rounded),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildTextField(
                        deadlineController, "Deadline (Optional)", "mm/dd/yyyy",
                        suffixIcon: Icons.calendar_today_rounded,
                        readOnly: true,
                        onTap: () => onPickDate(projectDeadline)),
                  ),
                ],
              ),
            ] else if (selectedType == WorkspaceType.course) ...[
              Row(
                children: [
                  Expanded(
                      flex: 2,
                      child: _buildTextField(nameController, "Course Name",
                          "e.g. Advanced Flutter")),
                  const SizedBox(width: 24),
                  Expanded(
                      child: _buildTextField(
                          subjectCodeController, "Subject Code", "e.g. CS101")),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                      child: _buildTextField(instructorController, "Instructor",
                          "e.g. Dr. Smith")),
                  const SizedBox(width: 24),
                  Expanded(
                      child: _buildTextField(scheduleController, "Schedule",
                          "e.g. Mon/Wed 10-11 AM")),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField(descController, "Description / Syllabus Summary",
                  "Brief overview...",
                  maxLines: 4),
            ] else if (selectedType == WorkspaceType.routine) ...[
              _buildTextField(
                  nameController, "Routine Name", "e.g. Daily Standup"),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: "Category",
                      value: routineCategory.value,
                      items: ["Health", "Work", "Personal"],
                      onChanged: (val) => routineCategory.value = val,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildDropdown(
                      label: "Frequency",
                      value: routineFrequency.value,
                      items: ["Daily", "Weekly", "Monthly"],
                      onChanged: (val) => routineFrequency.value = val,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField(
                  descController, "Description / Notes", "Routine details...",
                  maxLines: 4),
            ],

            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onBack,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    textStyle: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  child: const Text("Back"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter a name")),
                      );
                      return;
                    }

                    if (selectedType == WorkspaceType.project) {
                      // Move to Step 2
                      onStartPlanning();
                    } else {
                      // Create Immediately for other types
                      await _createWorkspace(
                        context,
                        ref,
                        selectedType,
                        nameController.text,
                        descController.text,
                        subjectCodeController.text,
                        instructorController.text,
                        scheduleController.text,
                        routineCategory.value,
                        routineFrequency.value,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  child: Text(selectedType == WorkspaceType.project
                      ? "Start Plan"
                      : "Create Workspace"),
                ),
              ],
            ),
          ],
        );

      case CreationStep.tasks:
        return LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Task Planning",
                        style: GoogleFonts.inter(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Project: ${nameController.text}",
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // FINAL CREATE for Project
                      await _createProjectWithTasks(
                        context,
                        ref,
                        nameController.text,
                        descController.text,
                        projectLeadController.text,
                        projectDeadline.value,
                        taskList.value,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981), // Emerald Green
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: const Text("Create Project"),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LEFT: ADD TASK FORM
                            Expanded(
                              flex: 4,
                              child: _buildAddTaskForm(
                                  context,
                                  isDark,
                                  taskNameController,
                                  taskPriority,
                                  taskStartDate,
                                  taskEndDate,
                                  taskStartController,
                                  taskEndController, // Use passed controllers
                                  taskAssignees,
                                  taskMilestones,
                                  milestoneController,
                                  allUsersAsync,
                                  taskList,
                                  onPickDate),
                            ),
                            const SizedBox(width: 32),

                            // RIGHT: TASK LIST
                            Expanded(
                              flex: 6,
                              child: _buildTaskList(isDark, taskList),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Column(children: [
                          _buildAddTaskForm(
                              context,
                              isDark,
                              taskNameController,
                              taskPriority,
                              taskStartDate,
                              taskEndDate,
                              taskStartController,
                              taskEndController,
                              taskAssignees,
                              taskMilestones,
                              milestoneController,
                              allUsersAsync,
                              taskList,
                              onPickDate),
                          const SizedBox(height: 32),
                          SizedBox(
                              height: 400,
                              child: _buildTaskList(isDark, taskList)),
                        ]))),
            ],
          );
        });
    }
  }

  // Helper for Add Task Form to keep _buildBody clean
  Widget _buildAddTaskForm(
    BuildContext context,
    bool isDark,
    TextEditingController taskNameController,
    ValueNotifier<String> taskPriority,
    ValueNotifier<DateTime?> taskStartDate,
    ValueNotifier<DateTime?> taskEndDate,
    TextEditingController taskStartController, // passed controller
    TextEditingController taskEndController, // passed controller
    ValueNotifier<List<String>> taskAssignees,
    ValueNotifier<List<String>> taskMilestones,
    TextEditingController milestoneController,
    AsyncValue<List<User>> allUsersAsync,
    ValueNotifier<List<_TempTask>> taskList,
    Function(ValueNotifier<DateTime?>) onPickDate,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade800.withOpacity(0.3)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Add New Task",
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 20),
          _buildTextField(taskNameController, "Task Name", "e.g. Setup Repo"),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: "Priority",
                  value: taskPriority.value,
                  items: ["Low", "Medium", "High"],
                  onChanged: (val) => taskPriority.value = val!,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  taskStartController, // Use hoisted controller
                  "Start",
                  "Select",
                  readOnly: true,
                  suffixIcon: Icons.calendar_today_rounded,
                  onTap: () => onPickDate(taskStartDate),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  taskEndController, // Use hoisted controller
                  "End",
                  "Select",
                  readOnly: true,
                  suffixIcon: Icons.calendar_today_rounded,
                  onTap: () => onPickDate(taskEndDate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Assignees
          Text("Assignees",
              style:
                  GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          allUsersAsync.when(
            data: (users) => DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                hintText: "Select User",
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: users
                  .map(
                      (u) => DropdownMenuItem(value: u.id, child: Text(u.name)))
                  .toList(),
              onChanged: (val) {
                if (val != null && !taskAssignees.value.contains(val)) {
                  taskAssignees.value = [...taskAssignees.value, val];
                }
              },
              dropdownColor: isDark ? const Color(0xFF374151) : Colors.white,
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text("Error loading users"),
          ),
          if (taskAssignees.value.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: taskAssignees.value.map((uid) {
                final user = allUsersAsync.valueOrNull?.firstWhere(
                    (u) => u.id == uid,
                    orElse: () => User(
                        id: uid,
                        name: 'Unknown',
                        avatarUrl: '',
                        email: '',
                        role: '',
                        department: ''));
                return Chip(
                  label: Text(user?.name ?? uid,
                      style: GoogleFonts.inter(fontSize: 11)),
                  deleteIcon: const Icon(Icons.close_rounded, size: 14),
                  onDeleted: () {
                    taskAssignees.value =
                        taskAssignees.value.where((id) => id != uid).toList();
                  },
                  visualDensity: VisualDensity.compact,
                  backgroundColor: isDark
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.blue.shade50,
                  side: BorderSide.none,
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),

          // Milestones
          Text("Milestones",
              style:
                  GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTextField(milestoneController, "Add Milestone",
                    "e.g. Design Approved"),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  if (milestoneController.text.isNotEmpty) {
                    taskMilestones.value = [
                      ...taskMilestones.value,
                      milestoneController.text
                    ];
                    milestoneController.clear();
                  }
                },
                icon: const Icon(Icons.add_circle, color: Colors.blue),
                tooltip: "Add Milestone",
              ),
            ],
          ),
          if (taskMilestones.value.isNotEmpty) ...[
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: taskMilestones.value
                  .map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flag_rounded,
                                size: 14, color: Colors.orange),
                            const SizedBox(width: 6),
                            Text(m, style: GoogleFonts.inter(fontSize: 13)),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                taskMilestones.value = taskMilestones.value
                                    .where((im) => im != m)
                                    .toList();
                              },
                              child: const Icon(Icons.close_rounded,
                                  size: 14, color: Colors.red),
                            )
                          ],
                        ),
                      ))
                  .toList(),
            )
          ],

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                if (taskNameController.text.isEmpty) return;
                final newTask = _TempTask(
                  name: taskNameController.text,
                  priority: taskPriority.value,
                  startDate: taskStartDate.value,
                  endDate: taskEndDate.value,
                  assignees: taskAssignees.value,
                  milestones: taskMilestones.value,
                );
                taskList.value = [...taskList.value, newTask];

                taskNameController.clear();
                taskPriority.value = 'Medium';
                taskStartDate.value = null;
                taskEndDate.value = null;
                taskAssignees.value = [];
                taskMilestones.value = [];
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add),
              label: Text("Add New Task",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(bool isDark, ValueNotifier<List<_TempTask>> taskList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Planned Tasks (${taskList.value.length})",
            style:
                GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Expanded(
          child: taskList.value.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text("No tasks added yet.",
                          style:
                              GoogleFonts.inter(color: Colors.grey.shade400)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: taskList.value.length,
                  itemBuilder: (context, index) {
                    final task = taskList.value[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade200)),
                      color: isDark ? const Color(0xFF374151) : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: task.priority == 'High'
                                      ? Colors.red.shade50
                                      : Colors.blue.shade50,
                                  radius: 14,
                                  child: Icon(
                                    task.priority == 'High'
                                        ? Icons.priority_high_rounded
                                        : Icons.check_rounded,
                                    color: task.priority == 'High'
                                        ? Colors.red
                                        : Colors.blue,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(task.name,
                                          style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${task.priority} • ${task.endDate != null ? DateFormat('MM/dd').format(task.endDate!) : 'No Due Date'}",
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded,
                                      size: 20, color: Colors.grey.shade400),
                                  onPressed: () {
                                    final newList = [...taskList.value];
                                    newList.removeAt(index);
                                    taskList.value = newList;
                                  },
                                ),
                              ],
                            ),
                            if (task.assignees.isNotEmpty ||
                                task.milestones.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(height: 1),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (task.assignees.isNotEmpty) ...[
                                    Icon(Icons.people_outline_rounded,
                                        size: 14, color: Colors.grey.shade500),
                                    const SizedBox(width: 6),
                                    Text("${task.assignees.length} Assignees",
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.grey.shade600)),
                                    const SizedBox(width: 20),
                                  ],
                                  if (task.milestones.isNotEmpty) ...[
                                    Icon(Icons.flag_outlined,
                                        size: 14, color: Colors.grey.shade500),
                                    const SizedBox(width: 6),
                                    Text("${task.milestones.length} Milestones",
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.grey.shade600)),
                                  ],
                                ],
                              )
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _createWorkspace(
    BuildContext context,
    WidgetRef ref,
    WorkspaceType type,
    String name,
    String desc,
    String subject,
    String instructor,
    String schedule,
    String? category,
    String? frequency,
  ) async {
    try {
      final projectRepo = ref.read(projectRepositoryProvider);
      final newId = 'proj-${DateTime.now().millisecondsSinceEpoch}';

      String finalDescription = desc;
      if (type == WorkspaceType.course) {
        finalDescription =
            "Subject: $subject\nInstructor: $instructor\nSchedule: $schedule\n\n$desc";
      } else if (type == WorkspaceType.routine) {
        finalDescription =
            "Category: $category\nFrequency: $frequency\n\n$desc";
      }

      await projectRepo.createProject(
        ProjectsCompanion(
          id: Value(newId),
          name: Value(name),
          context: Value(finalDescription),
          status: const Value('active'),
          approvalStatus: const Value('pending_creation'),
        ),
      );

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("Workspace '$name' Created!", style: GoogleFonts.inter()),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _createProjectWithTasks(
    BuildContext context,
    WidgetRef ref,
    String name,
    String desc,
    String lead,
    DateTime? deadline,
    List<_TempTask> tasks,
  ) async {
    try {
      final projectRepo = ref.read(projectRepositoryProvider);
      final newId = 'proj-${DateTime.now().millisecondsSinceEpoch}';

      // Persist Head/Deadline in context for now as per schema plan
      String finalDescription = desc;
      if (lead.isNotEmpty) finalDescription += "\n\nProject Lead: $lead";
      if (deadline != null) {
        finalDescription +=
            "\nDeadline: ${DateFormat('MM/dd/yyyy').format(deadline)}";
      }

      // 1. Create Project
      await projectRepo.createProject(
        ProjectsCompanion(
          id: Value(newId),
          name: Value(name),
          context: Value(finalDescription),
          status: const Value('active'),
          approvalStatus: const Value('pending_creation'),
        ),
      );

      // 2. Create Tasks
      for (var tempTask in tasks) {
        final taskId =
            'task-${DateTime.now().millisecondsSinceEpoch}-${tasks.indexOf(tempTask)}';
        await projectRepo.createTask(
          TasksCompanion(
            id: Value(taskId),
            name: Value(tempTask.name),
            projectId: Value(newId),
            priority: Value(tempTask.priority),
            startDate: Value(tempTask.startDate ?? DateTime.now()),
            endDate: Value(tempTask.endDate ??
                DateTime.now().add(const Duration(days: 7))),
            progress: const Value(0),
            approvalStatus: const Value('pending_creation'),
            assigneesJson: Value(jsonEncode(tempTask.assignees)),
            milestonesJson: Value(jsonEncode(tempTask.milestones)),
          ),
        );
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Project '$name' with ${tasks.length} tasks created!",
                style: GoogleFonts.inter()),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
    IconData? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, size: 18, color: Colors.grey.shade500)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          dropdownColor: isDark ? const Color(0xFF374151) : Colors.white,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: GoogleFonts.inter(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  String _getWorkspaceLabel(WorkspaceType type) {
    switch (type) {
      case WorkspaceType.project:
        return "Dev Project";
      case WorkspaceType.course:
        return "Class / Course";
      case WorkspaceType.routine:
        return "Routine Group";
    }
  }
}

class _Breadcrumb extends StatelessWidget {
  final CreationStep currentStep;
  final bool isDark;
  final bool isProject;

  const _Breadcrumb(
      {required this.currentStep,
      required this.isDark,
      required this.isProject});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _step("Type", CreationStep.type),
        _arrow(),
        _step("Details", CreationStep.details),
        if (isProject) ...[
          _arrow(),
          _step("Tasks", CreationStep.tasks),
        ],
      ],
    );
  }

  Widget _step(String label, CreationStep? step) {
    final isActive = step == currentStep;
    final isPast = step != null && step.index < currentStep.index;

    Color color;
    if (isActive) {
      color = Colors.blue;
    } else if (isPast) {
      color = isDark ? Colors.grey.shade400 : Colors.grey.shade800;
    } else {
      color = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    }

    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        color: isActive ? Colors.blue : color,
      ),
    );
  }

  Widget _arrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(Icons.chevron_right, size: 12, color: Colors.grey.shade400),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF374151) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.blue
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey.shade700
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDark ? Colors.grey.shade300 : Colors.blue,
                size: 24,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.blue
                    : (isDark ? Colors.white : const Color(0xFF111827)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool isDark;

  const _Badge({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }
}
