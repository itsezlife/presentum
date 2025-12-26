import 'package:app_ui/app_ui.dart';
import 'package:example/src/common/model/dependencies.dart';
import 'package:example/src/common/widgets/scaffold_padding.dart';
import 'package:example/src/feature/widgets/snow_outlet.dart';
import 'package:example/src/settings/widgets/enabled_catalog_features.dart';
import 'package:example/src/settings/widgets/reset_feautre_presentum_items_storage.dart';
import 'package:example/src/settings/widgets/settings_feature_toggles_outlet.dart';
import 'package:flutter/material.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = Dependencies.of(context);
    final catalog = deps.featureCatalog;
    final prefs = deps.featurePreferences;

    return Scaffold(
      body: SnowOutlet(
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(
              title: Text('Settings'),
              pinned: true,
              floating: true,
              snap: true,
            ),
            SliverPadding(
              padding: ScaffoldPadding.of(
                context,
                padding: 0,
              ).copyWith(top: AppSpacing.lg, bottom: AppSpacing.lg),
              sliver: SliverList.list(
                children: [
                  SettingsFeatureTogglesOutlet(catalog: catalog, prefs: prefs),
                  const SizedBox(height: AppSpacing.lg),
                  const EnabledCatalogFeatures(),
                  const SizedBox(height: AppSpacing.lg),
                  const ResetFeaturePresentumItemsStorage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
