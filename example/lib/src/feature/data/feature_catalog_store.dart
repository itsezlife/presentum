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

      // Merge: use local overrides if they exist, otherwise use remote config
      final mergedFeatures = await _mergeFeatures(
        remoteFeatures,
        savedFeatures,
      );

      _features = mergedFeatures;
      _allFeatures = remoteFeatures;
      notifyListeners();

      // Only save if we actually merged new features from remote
      if (mergedFeatures.isNotEmpty) {
        await _saveFeatures();
      }

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

  /// Refreshes features from remote config with the latest data.
  ///
  /// Unlike init, refresh always uses the most up-to-date data from remote
  /// config and doesn't preserve local modifications (except explicitly
  /// removed features). Features not in remote config are pruned.
  Future<void> _refreshFeatures() async {
    final remoteFeatures = await _fetchFeaturesFromRemoteConfig();

    final refreshedFeatures = await _refreshMerge(remoteFeatures);

    _features = refreshedFeatures;
    _allFeatures = remoteFeatures;
    notifyListeners();

    if (refreshedFeatures.isNotEmpty) {
      await _saveFeatures();
    }

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

  /// Merges remote features with local user preferences during initial load.
  ///
  /// - Always use the latest data from remote config for features
  /// - Only respect explicitly removed features (user preference)
  /// - Prune features not present in remote config
  Future<Map<String, FeatureDefinition>> _mergeFeatures(
    Map<String, FeatureDefinition> remoteFeatures,
    Map<String, FeatureDefinition>? localFeatures,
  ) async {
    final merged = <String, FeatureDefinition>{};

    // Process all features from remote config
    for (final entry in remoteFeatures.entries) {
      final key = entry.key;
      final remoteFeature = entry.value;
      final localFeature = localFeatures?[key];

      // Check if user explicitly removed this feature
      final isRemoved = await _repository.isRemoved(key);

      if (isRemoved) {
        // User explicitly removed this feature - respect their choice
        dev.log(
          'Feature $key is explicitly removed by user, keeping it removed',
          name: 'FeatureCatalogStore',
        );
        continue; // Don't add to merged features
      }

      // Always use remote config data to keep features up-to-date
      merged[key] = remoteFeature;
      if (localFeature != null) {
        dev.log(
          'Updating feature $key from remote config',
          name: 'FeatureCatalogStore',
        );
      } else {
        dev.log(
          'Adding new feature $key from remote config',
          name: 'FeatureCatalogStore',
        );
      }
    }

    // Prune overrides for features no longer in remote config
    await _repository.pruneTo(remoteFeatures.keys.toSet());

    return merged;
  }

  /// Refreshes features with the latest remote config data.
  ///
  /// Strategy for refresh:
  /// - Always use the most up-to-date data from remote config
  /// - Only respect explicitly removed features (user preference)
  /// - Prune features not present in remote config
  /// - Don't preserve local modifications (they get overwritten)
  Future<Map<String, FeatureDefinition>> _refreshMerge(
    Map<String, FeatureDefinition> remoteFeatures,
  ) async {
    final refreshed = <String, FeatureDefinition>{};

    // Process all features from remote config
    for (final entry in remoteFeatures.entries) {
      final key = entry.key;
      final remoteFeature = entry.value;

      // Check if user explicitly removed this feature
      final isRemoved = await _repository.isRemoved(key);

      if (isRemoved) {
        // User explicitly removed this feature - respect their choice
        dev.log(
          'Feature $key is explicitly removed by user, keeping it removed',
          name: 'FeatureCatalogStore',
        );
        continue; // Don't add to refreshed features
      }

      // Always use remote config data during refresh
      refreshed[key] = remoteFeature;
      dev.log(
        'Refreshing feature $key with remote config data',
        name: 'FeatureCatalogStore',
      );
    }

    // Prune features and overrides not in remote config
    await _repository.pruneTo(remoteFeatures.keys.toSet());

    return refreshed;
  }

  Future<void> replaceAll(Iterable<FeatureDefinition> list) async {
    _features = {for (final f in list) f.key: f};
    notifyListeners();
    await _saveFeatures();
  }

  Future<void> add(String key, {FeatureDefinition? feature}) async {
    final newFeature = feature ?? _allFeatures[key];
    if (newFeature == null) {
      dev.log(
        'Cannot add feature $key without providing feature definition',
        level: 500,
        name: 'FeatureCatalogStore',
      );
      return;
    }

    // Update local state
    _features = Map.from(_features)..putIfAbsent(key, () => newFeature);
    notifyListeners();

    // Save to repository (this will mark as overridden and remove from removed list)
    await _saveFeatures();
  }

  Future<void> remove(String key) async {
    // Mark as explicitly removed by user
    await _repository.markAsRemoved(key);

    // Update local state
    _features = Map.from(_features)..remove(key);
    notifyListeners();
  }

  Future<void> _saveFeatures() async {
    await _repository.updateFeatures(_features);
  }

  @override
  void dispose() {
    _remoteConfigSubscription?.cancel();
    super.dispose();
  }
}
