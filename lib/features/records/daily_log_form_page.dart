import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/field_actions.dart';
import '../../dependency_injection.dart';
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/widgets/common.dart';
import '../auth/presentation/session_cubit.dart';

/// Bitácora diaria (REP-01): qué se hizo hoy, con tareas opcionales.
class DailyLogFormPage extends StatefulWidget {
  const DailyLogFormPage({super.key});

  @override
  State<DailyLogFormPage> createState() => _DailyLogFormPageState();
}

class _DailyLogFormPageState extends State<DailyLogFormPage> {
  final _notes = TextEditingController();
  final _task = TextEditingController();
  final _tasks = <String>[];
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    _task.dispose();
    super.dispose();
  }

  void _addTask() {
    final t = _task.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _tasks.add(t);
      _task.clear();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await sl<FieldActions>().submitDailyLog(
      projectId: context.read<SessionCubit>().state.projectId!,
      notes: _notes.text.trim(),
      tasks: _tasks,
    );
    if (!mounted) return;
    showSaved(context);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final canSave = _notes.text.trim().isNotEmpty || _tasks.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(l.actionDailyLog)),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          TextField(
            key: const Key('dailyLogNotes'),
            controller: _notes,
            maxLines: 6,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l.whatDidYouDoToday, alignLabelWithHint: true),
          ),
          SectionTitle(l.tasks),
          for (final t in _tasks)
            ListTile(
              dense: true,
              leading: const Icon(Icons.check_box_outlined),
              title: Text(t),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _tasks.remove(t)),
              ),
            ),
          TextField(
            controller: _task,
            onSubmitted: (_) => _addTask(),
            decoration: InputDecoration(
              labelText: l.addTask,
              isDense: true,
              suffixIcon: IconButton(icon: const Icon(Icons.add), onPressed: _addTask),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          const LocalSaveHint(),
          FilledButton(
            key: const Key('saveDailyLog'),
            onPressed: !canSave || _saving ? null : _save,
            child: Text(l.save),
          ),
        ],
      ),
    );
  }
}
