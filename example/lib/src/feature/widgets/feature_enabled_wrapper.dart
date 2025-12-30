import 'package:collection/collection.dart';
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

  bool _isFeatureEnabled() {
    final enabled =
        _featurePreferences.overrideFor(widget.featureKey) ??
        _featureCatalog.features[widget.featureKey]?.defaultEnabled ??
        true;
    return enabled;
  }

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
          builder: (context, items) => widget.builder(
            isEnabled: items.isNotEmpty && _isFeatureEnabled(),
          ),
        ),
  );
}

/// {@template has_feature_candidates_and_enabled_wrapper}
/// Widget wrapper that shows a widget only if the feature is enabled and there
/// are presentum candidates for the feature.
/// {@endtemplate}
class HasFeatureCandidatesAndEnabledWrapper extends StatefulWidget {
  const HasFeatureCandidatesAndEnabledWrapper({
    required this.featureKey,
    required this.builder,
    super.key,
  });

  final String featureKey;
  final Widget Function({required bool isEnabled}) builder;

  @override
  State<HasFeatureCandidatesAndEnabledWrapper> createState() =>
      HasFeatureCandidatesAndEnabledWrapperState();
}

class HasFeatureCandidatesAndEnabledWrapperState
    extends State<HasFeatureCandidatesAndEnabledWrapper> {
  List<FeatureItem> _items = [];
  late final Presentum<FeatureItem, AppSurface, AppVariant> _presentum;
  late final PresentumStateObserver<FeatureItem, AppSurface, AppVariant>
  _observer;

  late final FeaturePreferencesStore _featurePreferences;
  late final FeatureCatalogStore _featureCatalog;

  @override
  void initState() {
    super.initState();
    _presentum = context.presentum<FeatureItem, AppSurface, AppVariant>();
    _observer = _presentum.observer;

    final dependencies = Dependencies.of(context);
    _featurePreferences = dependencies.featurePreferences;
    _featureCatalog = dependencies.featureCatalog;

    _onStateChange();

    _observer.addListener(_onStateChange);
    _featurePreferences.addListener(_onStateChange);
    _featureCatalog.addListener(_onStateChange);
  }

  void _onStateChange() {
    final items = _presentum.config.engine.currentCandidates
        .where((e) => e.payload.id == widget.featureKey)
        .toList();
    if (const ListEquality<FeatureItem>().equals(_items, items)) {
      return;
    }
    final enabledItems = <FeatureItem>[];
    for (final item in items) {
      if (item.payload.dependsOnFeatureKey == null) {
        if (_isFeatureEnabled()) {
          enabledItems.add(item);
        }
      } else {
        final dependsOnFeature =
            _featureCatalog.features[item.payload.dependsOnFeatureKey];
        if (dependsOnFeature != null && _isFeatureEnabled()) {
          enabledItems.add(item);
        }
      }
    }
    if (const ListEquality<FeatureItem>().equals(_items, enabledItems)) {
      return;
    }
    setState(() {
      _items = enabledItems;
    });
  }

  @override
  void dispose() {
    _observer.removeListener(_onStateChange);
    _featurePreferences.removeListener(_onStateChange);
    _featureCatalog.removeListener(_onStateChange);
    super.dispose();
  }

  bool _isFeatureEnabled() {
    final enabled =
        _featurePreferences.overrideFor(widget.featureKey) ??
        _featureCatalog.features[widget.featureKey]?.defaultEnabled ??
        true;
    return enabled;
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(isEnabled: _items.isNotEmpty);
}
