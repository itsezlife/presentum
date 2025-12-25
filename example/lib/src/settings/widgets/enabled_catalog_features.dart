import 'package:example/src/common/model/dependencies.dart';
import 'package:example/src/feature/data/feature_catalog_store.dart';
import 'package:example/src/l10n/l10n.dart';
import 'package:example/src/settings/widgets/settings_toggle_row.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class EnabledCatalogFeatures extends StatelessWidget {
  const EnabledCatalogFeatures({super.key});

  String? _titleFor(String featureId, AppLocalizations l10n) {
    final featureName = l10n.featureName(featureId);
    return l10n.toggleFeatureTitle(featureName);
  }

  bool _valueFor(String featureId, FeatureCatalogStore catalog) {
    return catalog.exists(featureId);
  }

  @override
  Widget build(BuildContext context) {
    final deps = Dependencies.of(context);
    final catalog = deps.featureCatalog;
    final l10n = context.l10n;

    return ExpansionTile(
      title: Text(l10n.settingsCatalogFeaturesTitle),
      subtitle: Text(l10n.settingsCatalogFeaturesDescription),
      initiallyExpanded: true,
      children: [
        for (final featureId in FeatureId.all)
          ListenableBuilder(
            listenable: catalog,
            builder: (context, child) {
              return SettingToggleRow(
                title: _titleFor(featureId, l10n),
                value: _valueFor(featureId, catalog),
                onChanged: (enable) =>
                    enable ? catalog.add(featureId) : catalog.remove(featureId),
              );
            },
          ),
      ],
    );
  }
}
