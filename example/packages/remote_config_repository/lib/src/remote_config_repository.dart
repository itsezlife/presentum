import 'dart:async';

import 'package:remote_config_client/remote_config_client.dart';

/// {@template remote_config_repository}
/// A repository for fetching remote data from the remote config client.
/// {@endtemplate}
class RemoteConfigRepository {
  /// {@macro remote_config_repository}
  const RemoteConfigRepository({
    required RemoteConfigClient remoteConfigClient,
  }) : _remoteConfigClient = remoteConfigClient;

  final RemoteConfigClient _remoteConfigClient;

  /// Fetches the remote data from the remote config.
  ///
  /// Throws [FetchRemoteDataFailure] if the fetch fails.
  FutureOr<T> fetchRemoteData<T>(String key) async {
    try {
      return _remoteConfigClient.fetchRemoteData<T>(key);
    } on FetchRemoteDataFailure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(FetchRemoteDataFailure(error), stackTrace);
    }
  }

  /// Broadcasts a stream of [RemoteConfigUpdate] whenever there is
  /// a change in remote config, e.g when some features become
  /// available to use.
  Stream<RemoteConfigUpdate> onConfigUpdated() =>
      _remoteConfigClient.onConfigUpdated();

  /// Sets up custom remote config settings.
  ///
  /// Throws [SetConfigFailure] if setting the config fails.
  Future<void> setConfigSettings(RemoteConfigSettings settings) async {
    try {
      await _remoteConfigClient.setConfigSettings(settings);
    } on SetConfigFailure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(SetConfigFailure(error), stackTrace);
    }
  }

  /// Activates the remote config.
  ///
  /// Throws [ActivateFailure] if the activate fails.
  Future<bool> activate() async {
    try {
      return _remoteConfigClient.activate();
    } on ActivateFailure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(ActivateFailure(error), stackTrace);
    }
  }
}

/// {@template remote_config_parameter}
/// A parameter for the remote config.
/// {@endtemplate}
extension type RemoteConfigParameter(String key) {
  /// Defines the key for the cyber monday campaign.
  static const campaigns = 'campaigns';
}
