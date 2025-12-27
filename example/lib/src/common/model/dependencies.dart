import 'package:example/src/app/initialization/widget/inherited_dependencies.dart';
import 'package:example/src/feature/data/feature_catalog_store.dart';
import 'package:example/src/feature/data/feature_store.dart';
import 'package:example/src/updates/data/updated_store.dart';
import 'package:firebase_remote_config_client/firebase_remote_config_client.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:remote_config_repository/remote_config_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dependencies
class Dependencies {
  Dependencies();

  /// The state from the closest instance of this class.
  factory Dependencies.of(BuildContext context) =>
      InheritedDependencies.of(context);

  /// Shared preferences
  late final SharedPreferencesWithCache sharedPreferences;

  /// Firebase remote config
  late final FirebaseRemoteConfig firebaseRemoteConfig;

  /// Remote config repository
  late final RemoteConfigRepository remoteConfigRepository;

  /// Feature catalog
  late final FeatureCatalogStore featureCatalog;

  /// Feature preferences
  late final FeaturePreferencesStore featurePreferences;

  /// Shorebird updates store
  late final ShorebirdUpdatesStore shorebirdUpdatesStore;
}
