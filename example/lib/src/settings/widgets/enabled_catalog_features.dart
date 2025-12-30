import 'package:collection/collection.dart';
import 'package:example/src/common/model/dependencies.dart';
import 'package:example/src/feature/data/feature_catalog_store.dart';
import 'package:example/src/feature/presentum/payload.dart';
import 'package:example/src/l10n/l10n.dart';
import 'package:example/src/settings/widgets/settings_toggle_row.dart';
import 'package:flutter/material.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

class EnabledCatalogFeatures extends StatefulWidget {
  const EnabledCatalogFeatures({super.key});

  @override
  State<EnabledCatalogFeatures> createState() => _EnabledCatalogFeaturesState();
}

class _EnabledCatalogFeaturesState extends State<EnabledCatalogFeatures> {
  late final FeatureCatalogStore _catalog;

  /// Could've used observer to update the whole catalog whenever presentum
  /// items payload changes to reflect the latest state, but since this whole
  /// catalog scope is for a showcase only this is not needed.
  late final Presentum<FeatureItem, AppSurface, AppVariant> _presentum;

  @override
  void initState() {
    super.initState();
    _presentum = context.presentum<FeatureItem, AppSurface, AppVariant>();

    final deps = Dependencies.of(context);
    _catalog = deps.featureCatalog;
  }

  String _titleFor(String featureId, AppLocalizations l10n) {
    final featureName = l10n.featureName(featureId);
    return l10n.toggleFeatureTitle(featureName);
  }

  String? _subtitleFor(String featureId, AppLocalizations l10n) {
    final featureItemPayload = _presentum.config.engine.currentCandidates
        .firstWhereOrNull((e) => e.payload.id == featureId)
        ?.payload;
    if (featureItemPayload == null) {
      return null;
    }
    if (featureItemPayload.dependsOnFeatureKey != null) {
      return null;
    }
    return l10n.settingsCatalogFeatureNotDependentDescription;
  }

  bool _valueFor(String featureId, FeatureCatalogStore catalog) =>
      catalog.exists(featureId);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListenableBuilder(
      listenable: _catalog,
      builder: (context, child) => ExpansionTile(
        title: Text(l10n.settingsCatalogFeaturesTitle),
        subtitle: Text(l10n.settingsCatalogFeaturesDescription),
        initiallyExpanded: true,
        children: [
          for (final feature
              in _catalog.allFeatures.values.toList()
                ..sort((a, b) => a.order.compareTo(b.order)))
            ListenableBuilder(
              listenable: _catalog,
              builder: (context, child) => SettingToggleRow(
                key: ValueKey(feature.key),
                title: _titleFor(feature.key, l10n),
                value: _valueFor(feature.key, _catalog),
                description: _subtitleFor(feature.key, l10n),
                onChanged: (enable) async {
                  if (enable) {
                    await _catalog.add(feature.key);
                  } else {
                    await _catalog.remove(feature.key);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
