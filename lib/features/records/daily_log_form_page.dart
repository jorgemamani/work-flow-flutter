import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/data/field_actions.dart';
import '../../core/data/field_repository.dart';
import '../../core/data/models.dart';
import '../../core/photos/photo_service.dart';
import '../../dependency_injection.dart';
import '../../routing/route_names.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/field_scaffold.dart';
import '../../shared/widgets/photo_strip.dart';
import '../auth/presentation/session_cubit.dart';

/// Bitácora diaria (REP-01): qué se hizo hoy, cómo están las herramientas y
/// vehículos, novedades, tareas y fotos opcionales.
class DailyLogFormPage extends StatefulWidget {
  const DailyLogFormPage({super.key});

  @override
  State<DailyLogFormPage> createState() => _DailyLogFormPageState();
}

class _DailyLogFormPageState extends State<DailyLogFormPage> {
  final _notes = TextEditingController();
  final _news = TextEditingController();
  final _task = TextEditingController();
  final _tasks = <String>[];
  final _photos = <LocalPhoto>[];
  bool? _equipmentOk;
  Project? _project;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final projectId = context.read<SessionCubit>().state.projectId;
    sl<FieldRepository>().project(projectId).then((p) {
      if (mounted) setState(() => _project = p);
    });
  }

  @override
  void dispose() {
    _notes.dispose();
    _news.dispose();
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
      equipmentOk: _equipmentOk,
      news: _news.text,
      photos: _photos,
    );
    if (!mounted) return;
    showSaved(context);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final maxPhotos = context.read<SessionCubit>().state.profile?.maxPhotosPerVerification ?? 5;
    final canSave = _notes.text.trim().isNotEmpty || _tasks.isNotEmpty;
    final today = toBeginningOfSentenceCase(DateFormat.MMMMEEEEd().format(DateTime.now()));
    return FieldScaffold(
      title: l.dailyLogTitle,
      subtitle: Text([today, if (_project != null) _project!.name].join(' · ')),
      footer: FieldFooter(
        hint: l.savedOnPhoneSentLater,
        children: [
          AppButton(
            key: const Key('saveDailyLog'),
            label: l.saveDailyLog,
            isLoading: _saving,
            onPressed: canSave ? _save : null,
          ),
        ],
      ),
      children: [
        FieldLabel(
          l.whatWasDoneToday,
          child: TextField(
            key: const Key('dailyLogNotes'),
            controller: _notes,
            minLines: 4,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 17, height: 1.45),
            onChanged: (_) => setState(() {}),
          ),
        ),
        FieldLabel(
          l.toolsAndVehicles,
          child: ChoiceGrid<bool>(
            semanticLabel: l.toolsAndVehicles,
            allowNone: true,
            selected: _equipmentOk,
            onChanged: (v) => setState(() => _equipmentOk = v),
            options: [ChoiceOption(true, l.allGood), ChoiceOption(false, l.somethingWrong)],
          ),
        ),
        FieldLabel(
          l.news,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _news,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 17, height: 1.45),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  textStyle: const TextStyle(fontSize: 15, decoration: TextDecoration.underline),
                ),
                onPressed: () => context.push(RouteNames.newIncident),
                child: Text(l.needsFixReport),
              ),
            ],
          ),
        ),
        FieldLabel(
          l.tasks,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_tasks.isNotEmpty) ...[
                RuledList(
                  children: [
                    for (final t in _tasks)
                      Row(
                        children: [
                          const Icon(Icons.check, size: 20, color: AppColors.statusSuccess),
                          const SizedBox(width: 10),
                          Expanded(child: Text(t, style: const TextStyle(fontSize: 16))),
                          IconButton(
                            tooltip: l.discard,
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => setState(() => _tasks.remove(t)),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: _task,
                onSubmitted: (_) => _addTask(),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: l.addTask,
                  suffixIcon: IconButton(tooltip: l.addTask, icon: const Icon(Icons.add), onPressed: _addTask),
                ),
              ),
            ],
          ),
        ),
        FieldLabel(
          l.photos,
          note: l.photosOptional,
          child: PhotoStrip(photos: _photos, max: maxPhotos, onChanged: () => setState(() {})),
        ),
      ],
    );
  }
}
