import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_paths.dart';
import '../../core/outbox/outbox_processor.dart';
import '../../dependency_injection.dart';
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/widgets/app_text_field.dart';

/// Cambio de PIN propio. Necesita señal (no es un hecho de campo).
class ChangePinPage extends StatefulWidget {
  const ChangePinPage({super.key});

  @override
  State<ChangePinPage> createState() => _ChangePinPageState();
}

class _ChangePinPageState extends State<ChangePinPage> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _repeat = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l = context.l10n;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await sl<ApiClient>().patch(ApiPaths.changePin, body: {
        if (_current.text.isNotEmpty) 'currentPin': _current.text,
        'newPin': _next.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.pinChanged)));
      context.pop();
    } on OfflineException {
      setState(() => _error = l.needsConnection);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final digits = [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)];
    return Scaffold(
      appBar: AppBar(title: Text(l.changePin)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            AppTextField(
              controller: _current,
              label: l.currentPin,
              isPassword: true,
              keyboardType: TextInputType.number,
              inputFormatters: digits,
            ),
            const SizedBox(height: AppSizes.md),
            AppTextField(
              controller: _next,
              label: l.newPin,
              isPassword: true,
              keyboardType: TextInputType.number,
              inputFormatters: digits,
              validator: (v) => (v ?? '').length < 4 ? l.pinTooShort : null,
            ),
            const SizedBox(height: AppSizes.md),
            AppTextField(
              controller: _repeat,
              label: l.repeatPin,
              isPassword: true,
              keyboardType: TextInputType.number,
              inputFormatters: digits,
              validator: (v) => v != _next.text ? l.pinMismatch : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSizes.md),
              Text(_error!, style: TextStyle(color: context.colorScheme.error)),
            ],
            const SizedBox(height: AppSizes.lg),
            FilledButton(onPressed: _saving ? null : _save, child: Text(l.save)),
          ],
        ),
      ),
    );
  }
}
