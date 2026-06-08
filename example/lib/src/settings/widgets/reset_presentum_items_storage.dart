import 'package:collection/collection.dart';
import 'package:control/control.dart';
import 'package:example/src/campaigns/camapigns.dart';
import 'package:example/src/common/constant/config.dart';
import 'package:example/src/common/model/dependencies.dart';
import 'package:example/src/feature/controller/feature_controller.dart';
import 'package:example/src/feature/presentum/payload.dart';
import 'package:example/src/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:presentum/presentum.dart';

class ResetFeaturePresentumItemsStorage extends StatefulWidget {
  const ResetFeaturePresentumItemsStorage({super.key});

  @override
  State<ResetFeaturePresentumItemsStorage> createState() =>
      _ResetFeaturePresentumItemsStorageState();
}

class _ResetFeaturePresentumItemsStorageState
    extends State<ResetFeaturePresentumItemsStorage> {
  late final FeatureController _featureController;
  late final CampaignsController _campaignsController;

  List<PresentumItem> _items = [];

  @override
  void initState() {
    super.initState();
    _featureController = context.controllerOf<FeatureController>();
    _campaignsController = context.controllerOf<CampaignsController>();

    _onStateChange();
    _featureController.addListener(_onStateChange);
    _campaignsController.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _featureController.removeListener(_onStateChange);
    _campaignsController.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    final items = <PresentumItem>[
      ..._featureController.state.candidates,
      ..._campaignsController.state.candidates,
    ];
    if (const ListEquality<PresentumItem>().equals(items, _items)) return;
    if (!mounted) return;
    setState(() => _items = items);
  }

  void _resetItem(PresentumItem item) {
    switch (item) {
      case FeatureItem(:final surface, :final variant):
        _featureController.storage.clearItem(
          item.id,
          surface: surface,
          variant: variant,
        );
        _featureController.revalidate();
      case CampaignPresentumItem(:final surface, :final variant):
        _campaignsController.storage.clearItem(
          item.id,
          surface: surface,
          variant: variant,
        );
        _campaignsController.revalidate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final deps = Dependencies.of(context);
    final catalog = deps.featureCatalog;
    final l10n = context.l10n;

    return ExpansionTile(
      title: Text(l10n.resetPresentumItemsStorageTitle),
      subtitle: Text(l10n.resetPresentumItemsStorageSubtitle),
      initiallyExpanded: Config.environment.isDevelopment,
      children: [
        ListTile(
          title: Text(l10n.resetAllPresentumItemsStorageTitle),
          leading: const Icon(Icons.refresh),
          onTap: () => _items.forEach(_resetItem),
        ),
        for (final item in _items)
          ListenableBuilder(
            listenable: catalog,
            builder: (context, child) => ListTile(
              title: Text(
                l10n.resetPresentumItemSurfaceVariant(
                  item.surface.key,
                  item.variant.key,
                ),
              ),
              subtitle: Text(l10n.resetPresentumItemId(item.id)),
              onTap: () => _resetItem(item),
            ),
          ),
      ],
    );
  }
}
