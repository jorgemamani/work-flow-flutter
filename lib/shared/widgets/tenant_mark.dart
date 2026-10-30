import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/session_cubit.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../theme/tenant_brand.dart';

/// Marca de la empresa: su inicial sobre su color (`brandColor` de
/// `/auth/me`; sin color, el petróleo de Workflow).
class TenantMark extends StatelessWidget {
  const TenantMark({super.key, this.size = 28, this.showName = false});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final profile = context.select((SessionCubit c) => c.state.profile);
    final name = profile?.tenantName ?? '';
    final brand = context.brand;
    final fill = brand.fill;
    final mark = Semantics(
      label: name,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(size / 4)),
        child: Text(
          name.isEmpty ? '·' : name.characters.first.toUpperCase(),
          style: TextStyle(
            fontFamily: AppFonts.sans,
            fontSize: size * 0.44,
            fontWeight: FontWeight.w700,
            color: brand.on,
          ),
        ),
      ),
    );
    if (!showName) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
          ),
        ),
      ],
    );
  }
}
