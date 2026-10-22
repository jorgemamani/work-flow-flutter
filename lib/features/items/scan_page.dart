import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/data/field_repository.dart';
import '../../core/data/models.dart';
import '../../dependency_injection.dart';
import '../../routing/route_names.dart';
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';

/// Escanear el código de barras o QR de un ítem (LOG-02) y abrirlo. Busca en
/// la base local: funciona sin señal. Si no hay cámara, se tipea el código.
///
/// Con [pickOnly] devuelve el ítem (para armar listas) en vez de abrirlo.
class ScanPage extends StatefulWidget {
  const ScanPage({super.key, this.pickOnly = false});

  final bool pickOnly;

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
  bool _handling = false;

  @override
  void dispose() {
    _controller.dispose();
    _manual.dispose();
    super.dispose();
  }

  Future<void> _lookup(String code) async {
    if (_handling || code.trim().isEmpty) return;
    _handling = true;
    final asset = await sl<FieldRepository>().findByCode(code.trim());
    if (!mounted) return;
    if (asset == null) {
      setState(() => _notFound = code.trim());
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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.scanTitle),
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
                    _lookup(v);
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
                  if (_notFound != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.sm),
                      child: Text(
                        l.codeNotFound(_notFound!),
                        style: TextStyle(color: context.colorScheme.error),
                      ),
                    ),
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
