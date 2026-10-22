import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/session_manager.dart';
import '../../../dependency_injection.dart';
import '../../../shared/constants/app_branding.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_sizes.dart';
import '../../../shared/extensions/context_extensions.dart';
import '../../../shared/widgets/app_text_field.dart';
import 'session_cubit.dart';

/// Login de campo (CUIT + DNI/CUIL + PIN) u oficina (email + contraseña).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _cuit = TextEditingController();
  final _doc = TextEditingController();
  final _pin = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _office = false;
  String? _tenantName;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Sesión vencida: precargar con quién estaba.
    final p = context.read<SessionCubit>().state.profile;
    if (p != null) {
      _cuit.text = p.tenantCuit ?? '';
      _doc.text = p.documentNumber ?? '';
      _email.text = p.email ?? '';
      _office = p.documentNumber == null && p.email != null;
      if (_cuit.text.isNotEmpty) _resolve(_cuit.text);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_cuit, _doc, _pin, _email, _password]) {
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
    final cubit = context.read<SessionCubit>();
    if (_office) {
      cubit.loginOffice(
        email: _email.text.trim(),
        password: _password.text,
        cuit: _digits(_cuit.text),
      );
    } else {
      cubit.loginField(
        cuit: _digits(_cuit.text),
        documentNumber: _digits(_doc.text),
        pin: _pin.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String? required(String? v) => (v == null || v.trim().isEmpty) ? l.requiredField : null;

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
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: false, label: Text(l.loginField), icon: const Icon(Icons.badge_outlined)),
                    ButtonSegment(value: true, label: Text(l.loginOffice), icon: const Icon(Icons.mail_outline)),
                  ],
                  selected: {_office},
                  onSelectionChanged: (s) => setState(() => _office = s.first),
                ),
                const SizedBox(height: AppSizes.lg),
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      AppTextField(
                        key: const Key('cuit'),
                        controller: _cuit,
                        label: _office ? l.companyCuitOptional : l.companyCuit,
                        hint: '30-12345678-9',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.business),
                        onChanged: _onCuitChanged,
                        validator: _office
                            ? null
                            : (v) => _digits(v ?? '').length == 11 ? null : l.invalidCuit,
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
                      if (!_office) ...[
                        AppTextField(
                          key: const Key('document'),
                          controller: _doc,
                          label: l.documentNumber,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(Icons.person_outline),
                          validator: required,
                        ),
                        const SizedBox(height: AppSizes.md),
                        AppTextField(
                          key: const Key('pin'),
                          controller: _pin,
                          label: l.pin,
                          isPassword: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          textInputAction: TextInputAction.done,
                          prefixIcon: const Icon(Icons.lock_outline),
                          onFieldSubmitted: (_) => _submit(),
                          validator: required,
                        ),
                      ] else ...[
                        AppTextField(
                          key: const Key('email'),
                          controller: _email,
                          label: l.email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(Icons.mail_outline),
                          validator: required,
                        ),
                        const SizedBox(height: AppSizes.md),
                        AppTextField(
                          key: const Key('password'),
                          controller: _password,
                          label: l.password,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          prefixIcon: const Icon(Icons.lock_outline),
                          onFieldSubmitted: (_) => _submit(),
                          validator: required,
                        ),
                      ],
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
