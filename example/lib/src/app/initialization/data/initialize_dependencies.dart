import 'dart:async';
import 'dart:developer' as dev;

import 'package:example/firebase_options.dart';
import 'package:example/src/app/initialization/data/platform/platform_initialization.dart';
import 'package:example/src/common/model/dependencies.dart';
import 'package:example/src/feature/data/feature_catalog_repository.dart';
import 'package:example/src/feature/data/feature_catalog_store.dart';
import 'package:example/src/feature/data/feature_repository.dart';
import 'package:example/src/feature/data/feature_store.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config_client/firebase_remote_config_client.dart';
import 'package:remote_config_repository/remote_config_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Initializes the app and returns a [Dependencies] object
Future<Dependencies> $initializeDependencies({
  void Function(int progress, String message)? onProgress,
}) async {
  final dependencies = Dependencies();
  final totalSteps = _initializationSteps.length;
  var currentStep = 0;
  for (final step in _initializationSteps.entries) {
    try {
      currentStep++;
      final percent = (currentStep * 100 ~/ totalSteps).clamp(0, 100);
      onProgress?.call(percent, step.key);
      dev.log(
        'Initialization | $currentStep/$totalSteps ($percent%) | "${step.key}"',
      );
      await step.value(dependencies);
    } on Object catch (error, stackTrace) {
      dev.log(
        'Initialization failed at step "${step.key}"',
        error: error,
        stackTrace: stackTrace,
      );
      Error.throwWithStackTrace(
        'Initialization failed at step "${step.key}": $error',
        stackTrace,
      );
    }
  }
  return dependencies;
}

typedef _InitializationStep =
    FutureOr<void> Function(Dependencies dependencies);
final Map<String, _InitializationStep> _initializationSteps =
    <String, _InitializationStep>{
      'Platform pre-initialization': (_) => $platformInitialization(),
      'Creating app metadata': (_) {},
      'Observer state managment': (_) {},
      'Initializing analytics': (_) {},
      'Log app open': (_) {},
      'Get remote config': (_) {},
      'Restore settings': (_) {},
      'Initialize shared preferences': (dependencies) async =>
          dependencies.sharedPreferences =
              await SharedPreferencesWithCache.create(
                cacheOptions: const SharedPreferencesWithCacheOptions(),
              ),
      'Initialize Firebase core': (dependencies) async {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      },
      'Initialize Firebase remote config': (dependencies) async {
        final firebaseRemoteConfig = FirebaseRemoteConfig.instance;
        dependencies.firebaseRemoteConfig = firebaseRemoteConfig;
      },
      'Initialize remote config': (dependencies) async {
        final remoteConfigClient = FirebaseRemoteConfigClient(
          firebaseRemoteConfig: dependencies.firebaseRemoteConfig,
        );
        final remoteConfigRepository = RemoteConfigRepository(
          remoteConfigClient: remoteConfigClient,
        );

        await remoteConfigRepository.activate();
        dependencies.remoteConfigRepository = remoteConfigRepository;
      },
      'Initialize feature preferences': (dependencies) async {
        final prefs = await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(),
        );

        // await prefs.clear();

        final repo = FeaturePreferencesRepositoryImpl(prefs: prefs);
        final preferencesStore = FeaturePreferencesStore(repo: repo);
        await preferencesStore.init();
        dependencies.featurePreferences = preferencesStore;

        final catalogRepo = FeatureCatalogRepositoryImpl(prefs: prefs);

        final catalogStore = FeatureCatalogStore(
          repository: catalogRepo,
          remoteConfigRepository: dependencies.remoteConfigRepository,
        );
        await catalogStore.init();
        dependencies.featureCatalog = catalogStore;
      },
      'Initialize localization': (_) {},
      'Migrate app from previous version': (_) {},
      'Collect logs': (_) {},
      'Log app initialized': (_) {},
    };
