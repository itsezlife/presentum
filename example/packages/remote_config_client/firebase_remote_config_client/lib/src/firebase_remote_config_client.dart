import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart' as firebase;
import 'package:remote_config_client/remote_config_client.dart';

/// {@template firebase_remote_config_update}
/// Firebase implementation of [RemoteConfigUpdate].
/// {@endtemplate}
class FirebaseRemoteConfigUpdate extends RemoteConfigUpdate {
  /// {@macro firebase_remote_config_update}
  const FirebaseRemoteConfigUpdate(this._update);

  final firebase.RemoteConfigUpdate _update;

  @override
  Set<String> get updatedKeys => _update.updatedKeys;
}

/// {@template firebase_remote_config_client}
/// A Firebase implementation of [RemoteConfigClient] that communicates
/// with Firebase Remote Config.
/// {@endtemplate}
class FirebaseRemoteConfigClient extends RemoteConfigClient {
  /// {@macro firebase_remote_config_client}
  FirebaseRemoteConfigClient({
    required firebase.FirebaseRemoteConfig firebaseRemoteConfig,
    RemoteConfigSettings? remoteConfigSettings,
  }) : _firebaseRemoteConfig = firebaseRemoteConfig,
       _remoteConfigSettings =
           remoteConfigSettings ?? _defaultRemoteConfigSettings {
    unawaited(_initializeRemoteConfig());
  }

  final firebase.FirebaseRemoteConfig _firebaseRemoteConfig;
  final RemoteConfigSettings _remoteConfigSettings;

  static const _defaultRemoteConfigSettings = RemoteConfigSettings(
    fetchTimeout: Duration(seconds: 10),
    minimumFetchInterval: Duration.zero,
  );

  Completer<bool>? _fetchAndActivateCompleter;

  Future<bool> _fetchAndActivate() async {
    try {
      _fetchAndActivateCompleter = Completer<bool>();
      final result = await _firebaseRemoteConfig.fetchAndActivate();
      _fetchAndActivateCompleter!.complete(result);
      return result;
    } catch (error, stackTrace) {
      _fetchAndActivateCompleter!.completeError(error, stackTrace);
      Error.throwWithStackTrace(
        FetchAndActivateFailure(error),
        stackTrace,
      );
    }
  }

  /// Initializes the [firebase.FirebaseRemoteConfig].
  Future<void> _initializeRemoteConfig() async {
    try {
      await _firebaseRemoteConfig.ensureInitialized();
      await setConfigSettings(_remoteConfigSettings);
      await _fetchAndActivate();
    } on SetConfigFailure {
      rethrow;
    } on FetchAndActivateFailure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        InitializeRemoteConfigFailure(error),
        stackTrace,
      );
    }
  }

  @override
  FutureOr<T> fetchRemoteData<T>(String key) async {
    try {
      var completer = _fetchAndActivateCompleter;
      while (completer == null) {
        completer = _fetchAndActivateCompleter;
        await Future.delayed(const Duration(milliseconds: 100), () {});
      }

      await completer.future;

      final typeString = T.toString();
      return switch (typeString) {
        'String' => _firebaseRemoteConfig.getString(key) as T,
        'int' => _firebaseRemoteConfig.getInt(key) as T,
        'double' => _firebaseRemoteConfig.getDouble(key) as T,
        'bool' => _firebaseRemoteConfig.getBool(key) as T,
        _ => throw UnsupportedError('Unsupported type: $T'),
      };
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        FetchRemoteDataFailure(error),
        stackTrace,
      );
    }
  }

  @override
  Stream<RemoteConfigUpdate> onConfigUpdated() => _firebaseRemoteConfig
      .onConfigUpdated
      .map(FirebaseRemoteConfigUpdate.new)
      .asBroadcastStream();

  @override
  Future<void> setConfigSettings(RemoteConfigSettings settings) async {
    try {
      await _firebaseRemoteConfig.setConfigSettings(
        firebase.RemoteConfigSettings(
          fetchTimeout: settings.fetchTimeout,
          minimumFetchInterval: settings.minimumFetchInterval,
        ),
      );
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(SetConfigFailure(error), stackTrace);
    }
  }

  @override
  Future<bool> activate() async {
    try {
      final result = await _firebaseRemoteConfig.activate();
      return result;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(ActivateFailure(error), stackTrace);
    }
  }
}
