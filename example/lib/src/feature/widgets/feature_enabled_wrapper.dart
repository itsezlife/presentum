import 'package:example/src/common/model/dependencies.dart';
import 'package:example/src/feature/data/feature_catalog_store.dart';
import 'package:example/src/feature/data/feature_store.dart';
import 'package:example/src/feature/presentum/payload.dart';
import 'package:flutter/material.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

/// {@template feature_enabled_wrapper}
/// Wraps a widget and only shows it if the feature is enabled.
/// {@endtemplate}
class FeatureEnabledWrapper extends StatefulWidget {
  const FeatureEnabledWrapper({
    required this.featureKey,
    required this.builder,
    this.surface = AppSurface.settingsToggles,
    super.key,
  });

  final AppSurface surface;
  final String featureKey;
  final Widget Function({required bool isEnabled}) builder;

  @override
  State<FeatureEnabledWrapper> createState() => _FeatureEnabledWrapperState();
}

class _FeatureEnabledWrapperState extends State<FeatureEnabledWrapper> {
  late final FeaturePreferencesStore _featurePreferences;
  late final FeatureCatalogStore _featureCatalog;

  @override
  void initState() {
    super.initState();
    final dependencies = Dependencies.of(context);
    _featurePreferences = dependencies.featurePreferences;
    _featureCatalog = dependencies.featureCatalog;
  }

  bool _isFeatureEnabled(FeatureItem? item) =>
      item != null &&
      (_featurePreferences.overrideFor(widget.featureKey) ??
          _featureCatalog.features[widget.featureKey]?.defaultEnabled ??
          true);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _featurePreferences,
    builder: (context, child) =>
        PresentumOutlet$Composition<FeatureItem, AppSurface, AppVariant>(
          surface: widget.surface,
          // Collect all items, both active and queue
          surfaceMode: OutletGroupMode.custom,
          resolver: (items) => items
              .where((e) => e.payload.featureKey == widget.featureKey)
              .toList(),
          builder: (context, items) =>
              widget.builder(isEnabled: _isFeatureEnabled(items.first)),
        ),
  );
}
