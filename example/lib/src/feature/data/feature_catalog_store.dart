import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:example/src/feature/data/feature_catalog_repository.dart';
import 'package:firebase_remote_config_client/firebase_remote_config_client.dart';
import 'package:flutter/foundation.dart';
import 'package:remote_config_repository/remote_config_repository.dart';
import 'package:shared/shared.dart';

final class FeatureCatalogStore extends ChangeNotifier {
  FeatureCatalogStore({
    required IFeatureCatalogRepository repository,
    required RemoteConfigRepository remoteConfigRepository,
  }) : _repository = repository,
       _remoteConfigRepository = remoteConfigRepository;

  final IFeatureCatalogRepository _repository;
  final RemoteConfigRepository _remoteConfigRepository;
  StreamSubscription<RemoteConfigUpdate>? _remoteConfigSubscription;

  /// Store all features from remote config, which serves as the source of
  /// truth for feature definitions. This is used only in the [add] method
  /// just for showcasing and in development purposes. In production it is not
  /// needed.
  Map<String, FeatureDefinition> _allFeatures = const {};
  Map<String, FeatureDefinition> _features = const {};

  Map<String, FeatureDefinition> get features => _features;
  Map<String, FeatureDefinition> get allFeatures => _allFeatures;
  bool exists(String key) => _features.containsKey(key);
  bool allExists(String key) => _allFeatures.containsKey(key);

  /// Initializes the feature catalog by fetching from remote config
  /// and merging with local user preferences.
  Future<void> init() async {
    try {
      // Fetch feature definitions from remote config
      final remoteFeatures = await _fetchFeaturesFromRemoteConfig();

      // Load local storage to get user overrides
      final savedFeatures = await _repository.getFeatures();

      // Merge: use remote config as base, preserve local enabled/disabled overrides
      final mergedFeatures = _mergeFeatures(remoteFeatures, savedFeatures);

      _features = mergedFeatures;
      _allFeatures = remoteFeatures;
      notifyListeners();
      _saveFeatures();

      // Set up listener for remote config updates
      _setupRemoteConfigListener();
    } on Object catch (error, stackTrace) {
      dev.log(
        'Failed to initialize feature catalog',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
        name: 'FeatureCatalogStore',
      );
      // On error, start with empty features
      _features = const {};
      notifyListeners();
    }
  }

  /// Sets up a listener for Firebase Remote Config updates to automatically
  /// refresh the feature catalog when changes occur.
  void _setupRemoteConfigListener() {
    _remoteConfigSubscription = _remoteConfigRepository
        .onConfigUpdated()
        .listen((update) async {
          try {
            await _remoteConfigRepository.activate();

            dev.log(
              'Remote config updated: ${update.updatedKeys}',
              name: 'FeatureCatalogStore',
            );

            // Check if any feature keys were updated
            final hasFeatureUpdates = update.updatedKeys.any(
              (key) => FeatureId.all.contains(key),
            );

            if (!hasFeatureUpdates) {
              return;
            }

            // Refresh features from remote config
            await _refreshFeatures();
          } on Object catch (error, stackTrace) {
            dev.log(
              'Failed to handle remote config update',
              error: error,
              stackTrace: stackTrace,
              level: 900,
              name: 'FeatureCatalogStore',
            );
          }
        });
  }

  /// Refreshes features from remote config and merges with local preferences.
  Future<void> _refreshFeatures() async {
    final remoteFeatures = await _fetchFeaturesFromRemoteConfig();
    final savedFeatures = await _repository.getFeatures();
    final mergedFeatures = _mergeFeatures(remoteFeatures, savedFeatures);

    _features = mergedFeatures;
    _allFeatures = remoteFeatures;
    notifyListeners();
    _saveFeatures();

    dev.log(
      'Features refreshed from remote config',
      name: 'FeatureCatalogStore',
    );
  }

  /// Fetches feature definitions from remote config for all known feature IDs.
  Future<Map<String, FeatureDefinition>>
  _fetchFeaturesFromRemoteConfig() async {
    final features = <String, FeatureDefinition>{};

    for (final featureKey in FeatureId.all) {
      try {
        final featureJsonData = await _remoteConfigRepository
            .fetchRemoteData<String>(featureKey);

        if (featureJsonData case final json when json.isNotEmpty) {
          final featureData =
              jsonDecode(featureJsonData) as Map<String, dynamic>;

          final feature = FeatureDefinition.fromJson({
            'key': featureKey,
            ...featureData,
          });

          features[featureKey] = feature;
        }
      } on Object catch (error) {
        dev.log(
          'Failed to fetch feature $featureKey from remote config',
          error: error,
          level: 900,
          name: 'FeatureCatalogStore',
        );
        // Continue fetching other features even if one fails
      }
    }

    return features;
  }

  /// Merges remote features with local user preferences.
  /// Remote config is the source of truth for feature definitions,
  /// but local overrides for enabled/disabled state are preserved.
  Map<String, FeatureDefinition> _mergeFeatures(
    Map<String, FeatureDefinition> remoteFeatures,
    Map<String, FeatureDefinition>? localFeatures,
  ) {
    if (localFeatures == null || localFeatures.isEmpty) {
      return remoteFeatures;
    }

    // Prune: only keep features that exist in remote config
    final merged = <String, FeatureDefinition>{};

    for (final entry in remoteFeatures.entries) {
      final key = entry.key;
      final remoteFeature = entry.value;
      final localFeature = localFeatures[key];

      // If local feature exists, preserve its enabled state override
      if (localFeature != null) {
        merged[key] = FeatureDefinition(
          key: remoteFeature.key,
          defaultEnabled: localFeature.defaultEnabled,
          metadata: localFeature.metadata,
          order: remoteFeature.order,
        );
      } else {
        merged[key] = remoteFeature;
      }
    }

    return merged;
  }

  void replaceAll(Iterable<FeatureDefinition> list) {
    _features = {for (final f in list) f.key: f};
    notifyListeners();
    _saveFeatures();
  }

  void add(String key, {FeatureDefinition? feature}) {
    final newFeature = feature ?? _allFeatures[key];
    if (newFeature == null) {
      dev.log(
        'Cannot add feature $key without providing feature definition',
        level: 500,
        name: 'FeatureCatalogStore',
      );
      return;
    }
    _features = Map.from(_features)..putIfAbsent(key, () => newFeature);
    notifyListeners();
    _saveFeatures();
  }

  void remove(String key) {
    _features = Map.from(_features)..remove(key);
    notifyListeners();
    _saveFeatures();
  }

  void _saveFeatures() {
    _repository.updateFeatures(_features);
  }

  @override
  void dispose() {
    _remoteConfigSubscription?.cancel();
    super.dispose();
  }
}
