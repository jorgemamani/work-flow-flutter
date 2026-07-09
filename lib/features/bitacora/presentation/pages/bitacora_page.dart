import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/domain/entities/user.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/entities/employee_obra_entities.dart';
import '../../data/mock_bitacora_datasource.dart';
import '../../domain/entities/bitacora_entry.dart';

/// Pantalla de Bitácora con filtrado por rol.
///
/// - Empleado: ve solo su propia bitácora.
/// - Admin / RRHH / Logística: ven todas las entradas, filtrables por obra.
///
/// TODO(workflow): Reemplazar [MockBitacoraDataSource] por repositorio real.
/// Buscar: BITACORA-MOCK.
class BitacoraPage extends StatefulWidget {
  const BitacoraPage({super.key});

  @override
  State<BitacoraPage> createState() => _BitacoraPageState();
}

class _BitacoraPageState extends State<BitacoraPage> {
  String? _selectedObraId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final user = state.user;
        final perms = user.permissions;
        final isEmpleado = user.role.isFieldRole;

        // Filtrado según rol.
        final allEntries = isEmpleado
            ? MockBitacoraDataSource.getByEmpleado(user.id)
            : MockBitacoraDataSource.getAll();

        final entries = _selectedObraId != null
            ? allEntries.where((e) => e.obraId == _selectedObraId).toList()
            : allEntries;

        // Obras disponibles para el filtro (solo para roles globales).
        final obras = isEmpleado ? <ObraAssignment>[] : user.obras;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            title: const Text('Bitácora'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            actions: [
              if (perms.canWriteBitacora)
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'Nueva entrada',
                  onPressed: () => _showAddEntrySheet(context, user),
                ),
            ],
          ),
          body: Column(
            children: [
              // Filtro por obra (solo para roles globales con +1 obra).
              if (!isEmpleado && obras.length > 1)
                _ObraFilterBar(
                  obras: obras,
                  selectedId: _selectedObraId,
                  onChanged: (id) => setState(() => _selectedObraId = id),
                ),
              Expanded(
                child: entries.isEmpty
                    ? _EmptyBitacora(canWrite: perms.canWriteBitacora)
                    : _EntriesList(
                        entries: entries,
                        showAuthor: !isEmpleado,
                      ),
              ),
            ],
          ),
          floatingActionButton: perms.canWriteBitacora
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddEntrySheet(context, user),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nueva entrada'),
                )
              : null,
        );
      },
    );
  }

  void _showAddEntrySheet(BuildContext context, User user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddEntrySheet(user: user),
    );
  }
}

// ── Filtro de obras ──────────────────────────────────────────────────────────

class _ObraFilterBar extends StatelessWidget {
  const _ObraFilterBar({
    required this.obras,
    required this.selectedId,
    required this.onChanged,
  });

  final List<ObraAssignment> obras;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('Todas'),
              selected: selectedId == null,
              onSelected: (_) => onChanged(null),
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
            ),
            ...obras.map(
              (o) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FilterChip(
                  label: Text(o.nombre),
                  selected: selectedId == o.id,
                  onSelected: (_) =>
                      onChanged(selectedId == o.id ? null : o.id),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Lista de entradas ────────────────────────────────────────────────────────

class _EntriesList extends StatelessWidget {
  const _EntriesList({
    required this.entries,
    required this.showAuthor,
  });

  final List<BitacoraEntry> entries;
  final bool showAuthor;

  @override
  Widget build(BuildContext context) {
    // Agrupamos por fecha.
    final grouped = <String, List<BitacoraEntry>>{};
    for (final e in entries) {
      final key = e.fechaLabel;
      grouped.putIfAbsent(key, () => []).add(e);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: grouped.entries
          .expand((group) => [
                _DateHeader(label: group.key),
                ...group.value.map(
                  (e) => _EntryCard(entry: e, showAuthor: showAuthor),
                ),
              ])
          .toList(),
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.showAuthor});

  final BitacoraEntry entry;
  final bool showAuthor;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat.Hm('es').format(entry.fecha);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado: obra + hora
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  entry.obraNombre,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Text(
                timeStr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Descripción
          Text(
            entry.descripcion,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          // Tareas (si existen)
          if (entry.tareas.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: entry.tareas
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        t,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          // Autor (solo para roles globales)
          if (showAuthor) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    entry.empleadoNombre.isNotEmpty
                        ? entry.empleadoNombre[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  entry.empleadoNombre,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyBitacora extends StatelessWidget {
  const _EmptyBitacora({required this.canWrite});

  final bool canWrite;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.book_outlined,
                  size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'Sin entradas todavía',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              canWrite
                  ? 'Registrá tus tareas del día usando el botón +.'
                  : 'No hay entradas de bitácora disponibles.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add entry sheet ──────────────────────────────────────────────────────────

class _AddEntrySheet extends StatefulWidget {
  const _AddEntrySheet({required this.user});

  final User user;

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  final _controller = TextEditingController();
  String? _selectedObraId;

  @override
  void initState() {
    super.initState();
    if (widget.user.obras.isNotEmpty) {
      _selectedObraId = widget.user.obras.first.id;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final obras = widget.user.obras;
    final bottomPad = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Nueva entrada',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (obras.isNotEmpty && obras.length > 1) ...[
            DropdownButtonFormField<String>(
              initialValue: _selectedObraId,
              decoration: const InputDecoration(
                labelText: 'Obra',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              items: obras
                  .map((o) => DropdownMenuItem(value: o.id, child: Text(o.nombre)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedObraId = v),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Descripción de las tareas realizadas',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _onSave,
            child: const Text('Guardar entrada'),
          ),
        ],
      ),
    );
  }

  void _onSave() {
    // TODO(workflow): Persistir la entrada via repositorio real. BITACORA-MOCK.
    if (_controller.text.trim().isEmpty) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entrada registrada (mock)')),
    );
  }
}
