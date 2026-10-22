import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/field_repository.dart';
import '../../core/data/models.dart';
import '../../dependency_injection.dart';
import '../../routing/route_names.dart';
import '../../shared/constants/app_sizes.dart';
import '../../shared/extensions/context_extensions.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/live_query.dart';
import '../../shared/widgets/sync_indicator.dart';
import '../auth/presentation/session_cubit.dart';
import 'item_lookup.dart';
import 'widgets/asset_tile.dart';

/// Mis ítems a cargo y los ítems del proyecto, con búsqueda y escaneo.
class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = context.watch<SessionCubit>().state;
    final projectId = session.projectId;
    final employeeId = session.profile?.employeeId;
    final repo = sl<FieldRepository>();

    return DefaultTabController(
      length: 2,
      initialIndex: employeeId == null ? 1 : 0,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.tabItems),
          actions: [
            IconButton(
              key: const Key('scanButton'),
              tooltip: l.actionScan,
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => context.push(RouteNames.scan),
            ),
            const SyncIndicator(),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(112),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSizes.md, 0, AppSizes.md, AppSizes.sm),
                  child: TextField(
                    key: const Key('itemSearch'),
                    controller: _search,
                    onChanged: (v) => setState(() => _q = v),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search),
                      hintText: l.searchItems,
                      suffixIcon: _q.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() {
                                _search.clear();
                                _q = '';
                              }),
                            ),
                    ),
                  ),
                ),
                TabBar(tabs: [Tab(text: l.myItems), Tab(text: l.projectItems)]),
              ],
            ),
          ),
        ),
        body: LiveQuery<(ItemContext, List<Asset>, List<Asset>, List<StockBalance>)>(
          sources: itemSources,
          deps: [projectId, employeeId],
          query: () async => (
            await ItemContext.load(),
            employeeId == null ? <Asset>[] : await repo.myAssets(employeeId),
            projectId == null ? <Asset>[] : await repo.projectAssets(projectId),
            projectId == null ? <StockBalance>[] : await repo.projectStock(projectId),
          ),
          builder: (context, d) {
            final (ctx, mine, project, stock) = d;
            List<Asset> filter(List<Asset> list) => [
                  for (final a in list)
                    if (a.matches(_q, model: ctx.models[a.modelId])) a,
                ]..sort((a, b) => a.internalCode.compareTo(b.internalCode));
            final stockFiltered = [
              for (final s in stock)
                if (_q.isEmpty ||
                    (ctx.models[s.modelId]?.name.toLowerCase().contains(_q.toLowerCase()) ?? false))
                  s,
            ];
            return TabBarView(
              children: [
                _AssetList(ctx: ctx, assets: filter(mine), empty: l.noMyItems),
                _AssetList(
                  ctx: ctx,
                  assets: filter(project),
                  empty: projectId == null ? l.noProject : l.noProjectItems,
                  stock: stockFiltered,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AssetList extends StatelessWidget {
  const _AssetList({
    required this.ctx,
    required this.assets,
    required this.empty,
    this.stock = const [],
  });

  final ItemContext ctx;
  final List<Asset> assets;
  final String empty;
  final List<StockBalance> stock;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (assets.isEmpty && stock.isEmpty) {
      return EmptyState(icon: Icons.inventory_2_outlined, text: empty);
    }
    return ListView(
      padding: const EdgeInsets.all(AppSizes.md),
      children: [
        for (final a in assets)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.sm),
            child: AssetTile(
              asset: a,
              ctx: ctx,
              onTap: () => context.push(RouteNames.itemDetail(a.id)),
            ),
          ),
        if (stock.isNotEmpty) ...[
          SectionTitle(l.consumables),
          Card(
            child: Column(
              children: [
                for (final s in stock)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.category_outlined),
                    title: Text(ctx.models[s.modelId]?.name ?? ''),
                    subtitle: Text([
                      if (s.variant.isNotEmpty) s.variant,
                      if (s.holderType == 'LOCATION') ctx.locations[s.holderId]?.name ?? '',
                      if (s.holderType != 'LOCATION') l.holderType(s.holderType),
                    ].where((e) => e.isNotEmpty).join(' · ')),
                    trailing: Text(
                      '${s.quantity}${ctx.models[s.modelId]?.unitOfMeasure == null ? '' : ' ${ctx.models[s.modelId]!.unitOfMeasure}'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
