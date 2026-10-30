import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/session_manager.dart';
import '../../../dependency_injection.dart';
import '../../../shared/constants/app_branding.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/extensions/context_extensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/common.dart';
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
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: BlocBuilder<SessionCubit, SessionState>(
            builder: (context, state) {
              final error = state.error == 'offline' ? l.loginOffline : state.error;
              return Form(
                key: _form,
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  children: [
                    const Text(
                      AppBranding.appName,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 22),
                    Text(l.loginTitle, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600, height: 1.15)),
                    const SizedBox(height: 22),
                    if (state.expired) ...[
                      FieldNotice(
                        icon: Icons.lock_clock_outlined,
                        iconColor: AppColors.statusWarning,
                        child: Text(l.sessionExpiredKeepQueue),
                      ),
                      const SizedBox(height: 16),
                    ],
                    AppTextField(
                      key: const Key('cuit'),
                      controller: _cuit,
                      label: l.companyCuit,
                      note: l.optional,
                      hint: '30-12345678-9',
                      mono: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      onChanged: _onCuitChanged,
                      validator: (v) {
                        final d = _digits(v ?? '');
                        return d.isEmpty || d.length == 11 ? null : l.invalidCuit;
                      },
                    ),
                    if (_tenantName != null) ...[
                      const SizedBox(height: 8),
                      StatusChip(_tenantName!, color: AppColors.statusSuccess, fontSize: 15),
                    ],
                    const SizedBox(height: 16),
                    AppTextField(
                      key: const Key('identifier'),
                      controller: _identifier,
                      label: l.identifierLabel,
                      hint: l.identifierHint,
                      // El teclado de email tiene @ y números: sirve para los dos.
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return l.requiredField;
                        if (!t.contains('@') && _digits(t).length < 7) return l.invalidIdentifier;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      key: const Key('secret'),
                      controller: _secret,
                      label: l.secretLabel,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) => (v == null || v.isEmpty) ? l.requiredField : null,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 16),
                      FieldNotice(
                        icon: Icons.error_outline,
                        iconColor: AppColors.statusError,
                        child: Text(error),
                      ),
                    ],
                    const SizedBox(height: 22),
                    AppButton(
                      key: const Key('loginButton'),
                      label: l.signIn,
                      isLoading: state.busy,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 22),
                    Text(l.loginHelp, style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Text(l.loginFirstTime, style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.textSecondary)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
