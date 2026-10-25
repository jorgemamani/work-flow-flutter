import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/auth/profile.dart';
import '../../core/data/field_repository.dart';
import '../../core/data/models.dart';
import '../../dependency_injection.dart';
import '../../routing/route_names.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/constants/app_fonts.dart';
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/connection_strip.dart';
import '../auth/presentation/session_cubit.dart';
import 'item_lookup.dart';

/// Escanear el código de barras o QR de un ítem (LOG-02). Busca en la base
/// local: funciona sin señal. Si no hay cámara, se tipea el código. Lo
/// encontrado aparece en una hoja abajo, con lo que se puede hacer.
///
/// Con [pickOnly] devuelve el ítem (para armar listas) en vez de abrirlo.
/// Con [captureCode] devuelve el código leído, exista o no (para dar de alta).
class ScanPage extends StatefulWidget {
  const ScanPage({super.key, this.pickOnly = false, this.captureCode = false});

  final bool pickOnly;
  final bool captureCode;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.all],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  String? _notFound;
  bool _notFoundFromCamera = false;
  bool _handling = false;
  bool _torch = false;
  Asset? _found;
  ItemContext? _ctx;

  @override
  void initState() {
    super.initState();
    // Fuera del build/dispose: la franja está más arriba en el árbol.
    Future.microtask(() => fullScreenDepth.value++);
  }

  @override
  void dispose() {
    Future.microtask(() => fullScreenDepth.value--);
    _controller.dispose();
    super.dispose();
  }

  /// [fromCamera]: el código vino del escáner (probablemente el de barras del
  /// fabricante) y no tipeado.
  Future<void> _lookup(String code, {bool fromCamera = false}) async {
    if (_handling || _found != null || code.trim().isEmpty) return;
    _handling = true;
    if (widget.captureCode) {
      context.pop(code.trim());
      return;
    }
    final asset = await sl<FieldRepository>().findByCode(code.trim());
    if (!mounted) return;
    if (asset == null) {
      HapticFeedback.heavyImpact();
      setState(() {
        _notFound = code.trim();
        _notFoundFromCamera = fromCamera;
      });
      _handling = false;
      return;
    }
    HapticFeedback.mediumImpact();
    if (widget.pickOnly) {
      context.pop(asset);
      return;
    }
    final ctx = await ItemContext.load();
    if (!mounted) return;
    setState(() {
      _found = asset;
      _ctx = ctx;
      _notFound = null;
    });
    _handling = false;
  }

  void _again() => setState(() {
        _found = null;
        _notFound = null;
      });

  Future<void> _typeCode() async {
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CodeSheet(),
    );
    if (code != null) await _lookup(code);
  }

  bool _canCreate(BuildContext context) {
    final s = context.read<SessionCubit>().state;
    return s.profile?.can(Perms.inventoryWrite, projectId: s.projectId) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.scannerBackground,
        body: Stack(
          children: [
            Positioned.fill(
              child: MobileScanner(
                controller: _controller,
                onDetect: (capture) {
                  for (final b in capture.barcodes) {
                    final v = b.rawValue;
                    if (v != null) {
                      _lookup(v, fromCamera: true);
                      break;
                    }
                  }
                },
                errorBuilder: (context, error) => DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.3),
                      radius: 1.1,
                      colors: [Color(0xFF3A3C3E), Color(0xFF1D1F21), AppColors.scannerBackground],
                      stops: [0, 0.55, 1],
                    ),
                  ),
                  child: Align(
                    alignment: const Alignment(0, 0.35),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
                      child: Text(
                        l.cameraUnavailableWrite,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, height: 1.4, color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: l.close,
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        Expanded(
                          child: Text(
                            widget.captureCode ? l.scanCodeTitle : l.actionScan,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                        IconButton(
                          tooltip: l.torch,
                          isSelected: _torch,
                          icon: const Icon(Icons.flashlight_off_outlined, color: Colors.white),
                          selectedIcon: const Icon(Icons.flashlight_on, color: Colors.white),
                          onPressed: () {
                            _controller.toggleTorch();
                            setState(() => _torch = !_torch);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 44),
                  const SizedBox(width: 272, height: 180, child: CustomPaint(painter: _FramePainter())),
                  const SizedBox(height: 18),
                  Text(
                    l.scanAimHint,
                    style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.86)),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    onPressed: _typeCode,
                    child: Text(l.scanWriteCode),
                  ),
                ],
              ),
            ),
            if (_found != null || _notFound != null)
              Positioned(left: 0, right: 0, bottom: 0, child: _sheet(context)),
          ],
        ),
      ),
    );
  }

  Widget _sheet(BuildContext context) {
    final l = context.l10n;
    final children = <Widget>[];
    final found = _found;
    if (found != null) {
      final ctx = _ctx!;
      final session = context.read<SessionCubit>().state;
      final can = ItemAbilities.of(found, profile: session.profile!, projectId: session.projectId);
      final custodian = ctx.employees[found.custodianEmployeeId]?.fullName;
      final inTransit = found.holderType == HolderTypes.inTransit;
      final where = [
        ctx.where(found, inTransit: l.inTransit, withPerson: l.withPerson),
        if (custodian != null) l.inChargeOf(custodian),
      ].where((s) => s.isNotEmpty).join(' · ');
      children.addAll([
        Row(
          children: [
            Chapa(found.internalCode),
            const Spacer(),
            inTransit
                ? StatusChip(l.inTransit, color: AppColors.statusMove, fontSize: 15)
                : StatusChip(l.assetStatus(found.status), color: assetStatusColor(found.status), fontSize: 15),
          ],
        ),
        const SizedBox(height: 8),
        Text(ctx.modelName(found), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
        if (where.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(where, style: const TextStyle(fontSize: 15, height: 1.4, color: AppColors.textSecondary)),
        ],
        const SizedBox(height: 16),
        if (can.canMove || can.canChangeStatus) ...[
          Row(
            children: [
              if (can.canMove)
                Expanded(
                  child: AppButton(
                    label: l.moveItem,
                    isOutlined: true,
                    onPressed: () => context.pushReplacement(RouteNames.moveItem(found.id)),
                  ),
                ),
              if (can.canMove && can.canChangeStatus) const SizedBox(width: 8),
              if (can.canChangeStatus)
                Expanded(
                  child: AppButton(
                    label: l.changeStatus,
                    isOutlined: true,
                    onPressed: () => context.pushReplacement(RouteNames.changeStatus(found.id)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        AppButton(label: l.scanViewItem, onPressed: () => context.pushReplacement(RouteNames.itemDetail(found.id))),
        TextButton(onPressed: _again, child: Text(l.scanAgain)),
      ]);
    } else {
      children.addAll([
        StatusChip(l.codeNotFound(_notFound!), color: AppColors.statusError, fontSize: 16),
        const SizedBox(height: 16),
        if (!widget.pickOnly && _canCreate(context)) ...[
          AppButton(
            key: const Key('createFromScan'),
            label: l.createWithThisCode,
            isOutlined: true,
            onPressed: () => context.pushReplacement(
              RouteNames.newItemWith(
                // Escaneado: suele ser el código del fabricante.
                code: _notFoundFromCamera ? null : _notFound,
                barcode: _notFoundFromCamera ? _notFound : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        AppButton(label: l.scanAgain, onPressed: _again),
      ]);
    }
    return Semantics(
      label: found != null ? l.itemFound : null,
      container: true,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: AppSizes.md),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.md, 10, AppSizes.md, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: AppColors.lineStrong, borderRadius: BorderRadius.circular(3)),
                  ),
                ),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tipear el código (sin cámara, o una etiqueta gastada). Dueño de su
/// controlador: se libera cuando la hoja termina de cerrarse.
class _CodeSheet extends StatefulWidget {
  const _CodeSheet();

  @override
  State<_CodeSheet> createState() => _CodeSheetState();
}

class _CodeSheetState extends State<_CodeSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSizes.md, 0, AppSizes.md, MediaQuery.viewInsetsOf(context).bottom + AppSizes.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel(
            l.scanWriteCode,
            child: TextField(
              key: const Key('manualCode'),
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.search,
              style: AppFonts.monoStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.ink),
              onSubmitted: (v) => Navigator.pop(context, v),
              decoration: const InputDecoration(hintText: 'WF-00231'),
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            key: const Key('manualCodeGo'),
            label: l.search,
            onPressed: () => Navigator.pop(context, _controller.text),
          ),
        ],
      ),
    );
  }
}

/// Las cuatro esquinas del visor.
class _FramePainter extends CustomPainter {
  const _FramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const arm = 34.0;
    const r = 14.0;
    for (final (dx, dy) in [(0.0, 0.0), (1.0, 0.0), (0.0, 1.0), (1.0, 1.0)]) {
      final x = dx * size.width;
      final y = dy * size.height;
      final sx = dx == 0 ? 1.0 : -1.0;
      final sy = dy == 0 ? 1.0 : -1.0;
      final path = Path()
        ..moveTo(x, y + sy * arm)
        ..lineTo(x, y + sy * r)
        ..quadraticBezierTo(x, y, x + sx * r, y)
        ..lineTo(x + sx * arm, y);
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
