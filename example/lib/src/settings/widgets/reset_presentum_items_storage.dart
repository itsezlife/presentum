import 'package:collection/collection.dart';
import 'package:example/src/campaigns/camapigns.dart';
import 'package:example/src/common/model/dependencies.dart';
import 'package:example/src/feature/presentum/payload.dart';
import 'package:example/src/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

class ResetFeaturePresentumItemsStorage extends StatefulWidget {
  const ResetFeaturePresentumItemsStorage({super.key});

  @override
  State<ResetFeaturePresentumItemsStorage> createState() =>
      _ResetFeaturePresentumItemsStorageState();
}

class _ResetFeaturePresentumItemsStorageState
    extends State<ResetFeaturePresentumItemsStorage> {
  late final Presentum<FeatureItem, AppSurface, AppVariant> _presentum;
  late final Presentum<CampaignPresentumItem, CampaignSurface, CampaignVariant>
  _campaignPresentum;
  late final PresentumStateObserver<FeatureItem, AppSurface, AppVariant>
  _observer;
  late final PresentumStateObserver<
    CampaignPresentumItem,
    CampaignSurface,
    CampaignVariant
  >
  _campaignObserver;

  List<PresentumItem> _items = [];

  @override
  void initState() {
    super.initState();
    _presentum = context.presentum<FeatureItem, AppSurface, AppVariant>();
    _campaignPresentum = context
        .presentum<CampaignPresentumItem, CampaignSurface, CampaignVariant>();
    _observer = context
        .presentum<FeatureItem, AppSurface, AppVariant>()
        .observer;
    _campaignObserver = context
        .presentum<CampaignPresentumItem, CampaignSurface, CampaignVariant>()
        .observer;

    // Initial state evaluation.
    _onStateChange();

    _observer.addListener(_onStateChange);
    _campaignObserver.addListener(_onStateChange);
  }

  void _onStateChange() {
    final candidates = _presentum.config.engine.currentCandidates;
    final campaignCandidates =
        _campaignPresentum.config.engine.currentCandidates;
    final items = <PresentumItem>[...candidates, ...campaignCandidates];
    if (const ListEquality<PresentumItem>().equals(items, _items)) return;
    if (!mounted) return;
    setState(() {
      _items = items;
    });
  }

  void _resetItem(PresentumItem item) {
    switch (item) {
      case FeatureItem(:final surface, :final variant):
        _presentum.config.storage.clearItem(
          item.id,
          surface: surface,
          variant: variant,
        );
      case CampaignPresentumItem(:final surface, :final variant):
        _campaignPresentum.config.storage.clearItem(
          item.id,
          surface: surface,
          variant: variant,
        );
    }

    // Force state update and all guards to re-evaluate.
    switch (item) {
      case FeatureItem():
        _presentum.config.engine.setCandidates((_, candidates) => candidates);
      case CampaignPresentumItem():
        _campaignPresentum.config.engine.setCandidates(
          (_, candidates) => candidates,
        );
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
      initiallyExpanded: false,
      children: [
        ListTile(
          title: Text(l10n.resetAllPresentumItemsStorageTitle),
          leading: const Icon(Icons.refresh),
          onTap: () {
            _items.forEach(_resetItem);
          },
        ),
        for (final item in _items)
          ListenableBuilder(
            listenable: catalog,
            builder: (context, child) => ListTile(
              title: Text(
                l10n.resetPresentumItemSurfaceVariant(
                  item.surface.name,
                  item.variant.name,
                ),
              ),
              subtitle: Text(l10n.resetPresentumItemId(item.id)),
              onTap: () {
                _resetItem(item);
              },
            ),
          ),
      ],
    );
  }
}
