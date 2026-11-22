import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/app_user.dart';
import '../../data/models/planner.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';

/// Wedding checklist (objective: "help couples manage guests, budget and
/// tasks", §4.3; concept screen B2).
class ChecklistTab extends StatefulWidget {
  const ChecklistTab({super.key, required this.couple});
  final Couple couple;

  @override
  State<ChecklistTab> createState() => _ChecklistTabState();
}

class _ChecklistTabState extends State<ChecklistTab> {
  TaskPhase? _phase;

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _editTask(context, widget.couple),
      icon: const Icon(Icons.add),
      label: const Text('Add task'),
    ),
    body: SafeArea(
      child: StreamView<List<ChecklistTask>>(
        stream: () => context.backend.watchTasks(widget.couple.id),
        builder: (context, tasks) {
          final done = tasks.where((t) => t.done).length;
          final shown = tasks.where((t) => _phase == null || t.phase == _phase).toList()
            ..sort((a, b) => a.done == b.done ? 0 : (a.done ? 1 : -1));
          final progress = tasks.isEmpty ? 0.0 : done / tasks.length;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text('Checklist', style: context.text.displaySmall),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: HennaHero(
                    radius: 18,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Overall progress', style: context.text.bodyMedium?.copyWith(color: heroMuted)),
                              const SizedBox(height: 4),
                              Text(
                                '$done of ${tasks.length} tasks done',
                                style: context.text.headlineSmall?.copyWith(
                                  color: heroInk,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(_nextUp(tasks), style: context.text.bodySmall?.copyWith(color: heroMuted)),
                            ],
                          ),
                        ),
                        ProgressRing(
                          value: progress,
                          color: context.colors.glow,
                          center: Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(color: heroInk, fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 60,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('All'),
                          selected: _phase == null,
                          onSelected: (_) => setState(() => _phase = null),
                        ),
                      ),
                      for (final p in TaskPhase.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(p.label),
                            selected: _phase == p,
                            onSelected: (_) => setState(() => _phase = p),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (shown.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.checklist,
                    title: 'No tasks here',
                    message: 'Add the things you need to do before the big day.',
                    action: 'Add task',
                    onAction: () => _editTask(context, widget.couple),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                  sliver: SliverList.separated(
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _TaskTile(task: shown[i], couple: widget.couple),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );

  String _nextUp(List<ChecklistTask> tasks) {
    final open = tasks.where((t) => !t.done && t.dueDate != null).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    if (open.isEmpty) return tasks.isEmpty ? 'Add your first task' : 'Everything with a date is done';
    return 'Next: ${open.first.title}';
  }
}

String dueText(ChecklistTask t) {
  final d = t.dueDate;
  if (t.done) return 'Completed';
  if (d == null) return 'No due date';
  final today = DateTime.now();
  final days = DateTime(d.year, d.month, d.day).difference(DateTime(today.year, today.month, today.day)).inDays;
  if (days < 0) return 'Overdue by ${-days} ${-days == 1 ? 'day' : 'days'}';
  if (days == 0) return 'Due today';
  if (days == 1) return 'Due tomorrow';
  if (days < 14) return 'Due in $days days';
  if (days < 60) return 'Due in ${(days / 7).round()} weeks';
  return 'Due in ${(days / 30).round()} months';
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.couple});
  final ChecklistTask task;
  final Couple couple;

  @override
  Widget build(BuildContext context) {
    final t = task;
    final c = context.colors;
    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(color: c.danger.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
        child: Icon(Icons.delete_outline, color: c.danger),
      ),
      onDismissed: (_) => runGuarded(context, () => context.backend.deleteTask(t.id), success: 'Task deleted'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
          onTap: () => _editTask(context, couple, task: t),
          leading: Checkbox(
            value: t.done,
            shape: const CircleBorder(),
            onChanged: (v) => context.backend.saveTask(t.copyWith(done: v ?? false)),
          ),
          title: Text(
            t.title,
            style: context.text.titleSmall?.copyWith(
              decoration: t.done ? TextDecoration.lineThrough : null,
              color: t.done ? c.muted : null,
            ),
          ),
          subtitle: Text(
            '${t.phase.label} · ${dueText(t)}',
            style: context.text.bodySmall?.copyWith(color: t.isOverdue ? c.danger : null),
          ),
          trailing: Icon(Icons.chevron_right, color: c.muted),
        ),
      ),
    );
  }
}

Future<void> _editTask(BuildContext context, Couple couple, {ChecklistTask? task}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _TaskSheet(couple: couple, task: task),
);

class _TaskSheet extends StatefulWidget {
  const _TaskSheet({required this.couple, this.task});
  final Couple couple;
  final ChecklistTask? task;

  @override
  State<_TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends State<_TaskSheet> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.task?.title);
  late TaskPhase _phase = widget.task?.phase ?? TaskPhase.planning;
  late DateTime? _due = widget.task?.dueDate;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final backend = context.backend;
    final t = widget.task;
    final task = t == null
        ? ChecklistTask(
            id: backend.newId(),
            userId: widget.couple.id,
            title: _title.text.trim(),
            phase: _phase,
            dueDate: _due,
          )
        : t.copyWith(title: _title.text.trim(), phase: _phase, dueDate: _due);
    final ok = await runGuarded(
      context,
      () => backend.saveTask(task),
      success: t == null ? 'Task added' : 'Task updated',
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.task == null ? 'New task' : 'Edit task', style: context.text.headlineMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                autofocus: widget.task == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Task'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Describe the task.' : null,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [
                  for (final p in TaskPhase.values)
                    ChoiceChip(
                      label: Text(p.label),
                      selected: _phase == p,
                      onSelected: (_) => setState(() => _phase = p),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              DateField(label: 'Due date (optional)', value: _due, onChanged: (d) => setState(() => _due = d)),
              const SizedBox(height: 18),
              AsyncButton(label: 'Save task', onPressed: _save),
              if (widget.task != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: context.colors.danger),
                  onPressed: () async {
                    final ok = await runGuarded(
                      context,
                      () => context.backend.deleteTask(widget.task!.id),
                      success: 'Task deleted',
                    );
                    if (ok && context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete task'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
