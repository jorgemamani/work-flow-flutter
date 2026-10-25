import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/session_manager.dart';
import '../../../dependency_injection.dart';
import '../../../shared/constants/app_branding.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_sizes.dart';
import '../../../shared/extensions/context_extensions.dart';
import '../../../shared/widgets/app_text_field.dart';
import 'session_cubit.dart';

/// Un solo login para campo y oficina (contrato §2): empresa (CUIT, opcional),
/// email o DNI/CUIL, y contraseña o PIN. Lo que cada uno ve adentro depende
/// de sus permisos.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _cuit = TextEditingController();
  final _identifier = TextEditingController();
  final _secret = TextEditingController();
  String? _tenantName;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  /// Sesión vencida: con quién estaba. Si no, lo último que se tipeó.
  Future<void> _prefill() async {
    final cubit = context.read<SessionCubit>();
    final p = cubit.state.profile;
    String? cuit;
    String? identifier;
    if (p != null) {
      cuit = p.tenantCuit;
      identifier = p.email ?? p.documentNumber;
    } else {
      (cuit, identifier) = await cubit.lastLogin();
    }
    if (!mounted) return;
    setState(() {
      _cuit.text = cuit ?? '';
      _identifier.text = identifier ?? '';
    });
    if (_cuit.text.isNotEmpty) _resolve(_cuit.text);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_cuit, _identifier, _secret]) {
      c.dispose();
    }
    super.dispose();
  }

  static String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

  void _onCuitChanged(String v) {
    _debounce?.cancel();
    if (_digits(v).length != 11) {
      if (_tenantName != null) setState(() => _tenantName = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _resolve(v));
  }

  Future<void> _resolve(String cuit) async {
    final name = await sl<SessionManager>().resolveTenant(_digits(cuit));
    if (mounted) setState(() => _tenantName = name);
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<SessionCubit>().login(
          cuit: _digits(_cuit.text),
          identifier: _identifier.text.trim(),
          secret: _secret.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<SessionCubit, SessionState>(
          builder: (context, state) {
            final error = state.error == 'offline' ? l.loginOffline : state.error;
            return ListView(
              padding: const EdgeInsets.all(AppSizes.lg),
              children: [
                const SizedBox(height: AppSizes.xl),
                const Icon(Icons.work_rounded, size: 56, color: AppColors.primary),
                const SizedBox(height: AppSizes.md),
                Text(
                  AppBranding.appName,
                  textAlign: TextAlign.center,
                  style: context.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSizes.xl),
                if (state.expired)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.md),
                    child: _Notice(text: l.sessionExpiredKeepQueue, color: AppColors.statusWarning),
                  ),
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      AppTextField(
                        key: const Key('cuit'),
                        controller: _cuit,
                        label: l.companyCuitOptional,
                        hint: '30-12345678-9',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.business),
                        onChanged: _onCuitChanged,
                        validator: (v) {
                          final d = _digits(v ?? '');
                          return d.isEmpty || d.length == 11 ? null : l.invalidCuit;
                        },
                      ),
                      if (_tenantName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSizes.xs),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, size: 16, color: AppColors.statusSuccess),
                              const SizedBox(width: 6),
                              Text(_tenantName!, style: context.textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSizes.md),
                      AppTextField(
                        key: const Key('identifier'),
                        controller: _identifier,
                        label: l.identifierLabel,
                        hint: l.identifierHint,
                        // El teclado de email tiene @ y números: sirve para los dos.
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.person_outline),
                        validator: (v) {
                          final t = (v ?? '').trim();
                          if (t.isEmpty) return l.requiredField;
                          if (!t.contains('@') && _digits(t).length < 7) return l.invalidIdentifier;
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSizes.md),
                      AppTextField(
                        key: const Key('secret'),
                        controller: _secret,
                        label: l.secretLabel,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        prefixIcon: const Icon(Icons.lock_outline),
                        onFieldSubmitted: (_) => _submit(),
                        validator: (v) => (v == null || v.isEmpty) ? l.requiredField : null,
                      ),
                    ],
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: AppSizes.md),
                  _Notice(text: error, color: AppColors.statusError),
                ],
                const SizedBox(height: AppSizes.lg),
                FilledButton(
                  key: const Key('loginButton'),
                  onPressed: state.busy ? null : _submit,
                  child: state.busy
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l.signIn),
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  l.loginHelp,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(text, style: TextStyle(color: color)),
      );
}
