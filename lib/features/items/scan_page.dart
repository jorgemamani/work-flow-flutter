import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/auth/profile.dart';
import '../../core/data/field_repository.dart';
import '../../core/data/models.dart';
import '../../dependency_injection.dart';
import '../../routing/route_names.dart';
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';
import '../auth/presentation/session_cubit.dart';

/// Escanear el código de barras o QR de un ítem (LOG-02) y abrirlo. Busca en
/// la base local: funciona sin señal. Si no hay cámara, se tipea el código.
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
  final _manual = TextEditingController();
  String? _notFound;
  bool _notFoundFromCamera = false;
  bool _handling = false;

  @override
  void dispose() {
    _controller.dispose();
    _manual.dispose();
    super.dispose();
  }

  /// [fromCamera]: el código vino del escáner (probablemente el de barras del
  /// fabricante) y no tipeado.
  Future<void> _lookup(String code, {bool fromCamera = false}) async {
    if (_handling || code.trim().isEmpty) return;
    _handling = true;
    if (widget.captureCode) {
      context.pop(code.trim());
      return;
    }
    final asset = await sl<FieldRepository>().findByCode(code.trim());
    if (!mounted) return;
    if (asset == null) {
      setState(() {
        _notFound = code.trim();
        _notFoundFromCamera = fromCamera;
      });
      _handling = false;
      return;
    }
    _found(asset);
  }

  void _found(Asset asset) {
    if (widget.pickOnly) {
      context.pop(asset);
    } else {
      context.pushReplacement(RouteNames.itemDetail(asset.id));
    }
  }

  bool _canCreate(BuildContext context) {
    final s = context.read<SessionCubit>().state;
    return s.profile?.can(Perms.inventoryWrite, projectId: s.projectId) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.captureCode ? l.scanCodeTitle : l.scanTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
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
              errorBuilder: (context, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: Text(l.cameraUnavailable, textAlign: TextAlign.center),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                children: [
                  if (_notFound != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.sm),
                      child: Text(
                        l.codeNotFound(_notFound!),
                        style: TextStyle(color: context.colorScheme.error),
                      ),
                    ),
                    if (!widget.pickOnly && _canCreate(context))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.sm),
                        child: OutlinedButton.icon(
                          key: const Key('createFromScan'),
                          icon: const Icon(Icons.add),
                          label: Text(l.createWithThisCode),
                          onPressed: () => context.pushReplacement(
                            RouteNames.newItemWith(
                              // Escaneado: suele ser el código del fabricante.
                              code: _notFoundFromCamera ? null : _notFound,
                              barcode: _notFoundFromCamera ? _notFound : null,
                            ),
                          ),
                        ),
                      ),
                  ],
                  TextField(
                    key: const Key('manualCode'),
                    controller: _manual,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _lookup,
                    decoration: InputDecoration(
                      labelText: l.typeCode,
                      prefixIcon: const Icon(Icons.keyboard),
                      suffixIcon: IconButton(
                        key: const Key('manualCodeGo'),
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () => _lookup(_manual.text),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
