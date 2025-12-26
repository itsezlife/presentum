import 'package:example/src/feature/data/feature_catalog_store.dart';
import 'package:example/src/feature/data/feature_store.dart';
import 'package:example/src/feature/presentum/payload.dart';
import 'package:example/src/l10n/l10n.dart';
import 'package:example/src/settings/widgets/settings_toggle_row.dart';
import 'package:flutter/material.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

class SettingsFeatureTogglesOutlet extends StatelessWidget {
  const SettingsFeatureTogglesOutlet({
    required this.catalog,
    required this.prefs,
    super.key,
  });

  final FeatureCatalogStore catalog;
  final FeaturePreferencesStore prefs;

  String? _titleFor(String featureId, AppLocalizations l10n) =>
      l10n.featureName(featureId);

  String? _descriptionFor(String featureId, AppLocalizations l10n) {
    final featureName = l10n.featureName(featureId);
    return l10n.settingsFeatureEnabledDescription(featureName);
  }

  bool _valueFor(String featureId) =>
      prefs.overrideFor(featureId) ??
      (catalog.features[featureId]?.defaultEnabled ?? true);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PresentumOutlet$Composition<FeatureItem, AppSurface, AppVariant>(
      surface: AppSurface.settingsToggles,
      surfaceMode: OutletGroupMode.custom,
      resolver: (items) => items,
      builder: (context, items) => Column(
        children: [
          for (final item in items)
            ListenableBuilder(
              listenable: prefs,
              builder: (context, child) => SettingToggleRow(
                title: _titleFor(item.payload.featureKey, l10n),
                description: _descriptionFor(item.payload.featureKey, l10n),
                value: _valueFor(item.payload.featureKey),
                onChanged: (enabled) =>
                    prefs.setEnabled(item.payload.featureKey, enabled: enabled),
              ),
            ),
        ],
      ),
    );
  }
}
