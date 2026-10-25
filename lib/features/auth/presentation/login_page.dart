import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/session_manager.dart';
import '../../../dependency_injection.dart';
import '../../../shared/constants/app_branding.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_fonts.dart';
import '../../../shared/constants/app_sizes.dart';
import '../../../shared/extensions/context_extensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/common.dart';
import 'session_cubit.dart';

enum _Mode { field, office }

/// Un solo login para campo y oficina (contrato §2): empresa (CUIT, opcional),
/// email o DNI/CUIL, y contraseña o PIN. "Campo" es DNI + teclado de PIN
/// grande (guantes, sol); "Oficina", email y contraseña. Lo que cada uno ve
/// adentro depende de sus permisos, no del modo.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _pinMax = 8;
  static const _pinMin = 4;

  final _form = GlobalKey<FormState>();
  final _cuit = TextEditingController();
  final _document = TextEditingController();
  final _email = TextEditingController();
  final _secret = TextEditingController();
  String _pin = '';
  _Mode _mode = _Mode.field;
  bool _showCuit = false;
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
      _showCuit = _cuit.text.isNotEmpty;
      final id = identifier ?? '';
      if (id.contains('@')) {
        _mode = _Mode.office;
        _email.text = id;
      } else {
        _document.text = id;
      }
    });
    if (_cuit.text.isNotEmpty) _resolve(_cuit.text);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_cuit, _document, _email, _secret]) {
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

  bool get _ready => _mode == _Mode.office || _pin.length >= _pinMin;

  void _press(String digit) {
    if (_pin.length >= _pinMax) return;
    HapticFeedback.selectionClick();
    setState(() => _pin += digit);
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _submit() {
    if (!_form.currentState!.validate() || !_ready) return;
    FocusScope.of(context).unfocus();
    final field = _mode == _Mode.field;
    context.read<SessionCubit>().login(
          cuit: _digits(_cuit.text),
          identifier: field ? _digits(_document.text) : _email.text.trim(),
          secret: field ? _pin : _secret.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: BlocBuilder<SessionCubit, SessionState>(
          builder: (context, state) {
            final error = state.error == 'offline' ? l.loginOffline : state.error;
            return Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                children: [
                  const Text(
                    AppBranding.appName,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                  ),
                  const SizedBox(height: 22),
                  Text(l.loginTitle, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600, height: 1.15)),
                  const SizedBox(height: 16),
                  _ModeTabs(
                    label: l.loginModeLabel,
                    mode: _mode,
                    field: l.loginField,
                    office: l.loginOffice,
                    onChanged: (m) => setState(() => _mode = m),
                  ),
                  const SizedBox(height: 22),
                  if (state.expired) ...[
                    FieldNotice(
                      icon: Icons.lock_clock_outlined,
                      iconColor: AppColors.statusWarning,
                      child: Text(l.sessionExpiredKeepQueue),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _cuitField(context),
                  if (_mode == _Mode.field) ..._fieldMode(context) else ..._officeMode(context),
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    FieldNotice(
                      icon: Icons.error_outline,
                      iconColor: AppColors.statusError,
                      child: Text(error),
                    ),
                  ],
                  const SizedBox(height: 16),
                  AppButton(
                    key: const Key('loginButton'),
                    label: l.signIn,
                    isLoading: state.busy,
                    onPressed: _ready ? _submit : null,
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
    );
  }

  Widget _cuitField(BuildContext context) {
    final l = context.l10n;
    if (!_showCuit) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero, textStyle: const TextStyle(fontSize: 15, decoration: TextDecoration.underline)),
            onPressed: () => setState(() => _showCuit = true),
            child: Text(l.companyCuitToggle),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
        ],
      ),
    );
  }

  List<Widget> _fieldMode(BuildContext context) {
    final l = context.l10n;
    final slots = _pin.length > 6 ? _pinMax : 6;
    return [
      AppTextField(
        key: const Key('identifier'),
        controller: _document,
        label: l.documentNumber,
        mono: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
        textInputAction: TextInputAction.done,
        validator: (v) => _digits(v ?? '').length < 7 ? l.invalidDocument : null,
      ),
      const SizedBox(height: 16),
      Text(l.pin, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      const SizedBox(height: 10),
      Semantics(
        key: const Key('secret'),
        label: '${l.pin}: ${l.pinEntered(_pin.length)}',
        child: Row(
          children: [
            for (var i = 0; i < slots; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pin.length ? AppColors.ink : Colors.transparent,
                  border: Border.all(color: AppColors.ink, width: 2),
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      _PinPad(onDigit: _press, onBackspace: _backspace, backspaceLabel: l.deleteDigit),
    ];
  }

  List<Widget> _officeMode(BuildContext context) {
    final l = context.l10n;
    return [
      AppTextField(
        key: const Key('identifier'),
        controller: _email,
        label: l.email,
        hint: l.emailHint,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        validator: (v) => (v ?? '').trim().contains('@') ? null : l.invalidEmail,
      ),
      const SizedBox(height: 16),
      AppTextField(
        key: const Key('secret'),
        controller: _secret,
        label: l.password,
        isPassword: true,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _submit(),
        validator: (v) => (v == null || v.isEmpty) ? l.requiredField : null,
      ),
    ];
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({
    required this.label,
    required this.mode,
    required this.field,
    required this.office,
    required this.onChanged,
  });

  final String label;
  final _Mode mode;
  final String field;
  final String office;
  final ValueChanged<_Mode> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(_Mode m, String text) {
      final on = m == mode;
      return Expanded(
        child: Semantics(
          selected: on,
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? AppColors.surfaceLight : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                boxShadow: on
                    ? [BoxShadow(color: AppColors.ink.withValues(alpha: 0.12), blurRadius: 3, offset: const Offset(0, 1))]
                    : null,
              ),
              child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: label,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.selected, borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        child: Row(children: [tab(_Mode.field, field), const SizedBox(width: 4), tab(_Mode.office, office)]),
      ),
    );
  }
}

/// Teclado de PIN grande: teclas de 60 px en mono.
class _PinPad extends StatelessWidget {
  const _PinPad({required this.onDigit, required this.onBackspace, required this.backspaceLabel});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final String backspaceLabel;

  @override
  Widget build(BuildContext context) {
    Widget key(String? digit) {
      if (digit == null) return const SizedBox(height: 60);
      final back = digit == '⌫';
      return Material(
        color: back ? Colors.transparent : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: InkWell(
          key: Key('pin-${back ? 'back' : digit}'),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          onTap: back ? onBackspace : () => onDigit(digit),
          child: Semantics(
            label: back ? backspaceLabel : digit,
            button: true,
            excludeSemantics: true,
            child: SizedBox(
              height: 60,
              child: Center(
                child: back
                    ? const Icon(Icons.backspace_outlined, size: 24, color: AppColors.ink)
                    : Text(digit, style: AppFonts.monoStyle(fontSize: 24, fontWeight: FontWeight.w500, color: AppColors.ink)),
              ),
            ),
          ),
        ),
      );
    }

    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      [null, '0', '⌫'],
    ];
    return Column(
      children: [
        for (final (ri, row) in rows.indexed) ...[
          if (ri > 0) const SizedBox(height: 8),
          Row(
            children: [
              for (final (i, d) in row.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: key(d)),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
