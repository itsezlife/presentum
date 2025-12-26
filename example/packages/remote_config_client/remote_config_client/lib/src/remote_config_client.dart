import 'dart:async';

import 'package:equatable/equatable.dart';

/// {@template remote_config_exception}
/// Base exception class for remote config operations.
/// {@endtemplate}
abstract class RemoteConfigException with EquatableMixin implements Exception {
  /// {@macro remote_config_exception}
  const RemoteConfigException(this.error, [this.message]);

  /// The error which was caught.
  final Object error;

  /// The message of the error.
  final String? message;

  @override
  List<Object?> get props => [error, message];
}

/// {@template initialize_remote_config_failure}
/// Thrown during the initialization of the remote config
/// if a failure occurs.
/// {@endtemplate}
class InitializeRemoteConfigFailure extends RemoteConfigException {
  /// {@macro initialize_remote_config_failure}
  const InitializeRemoteConfigFailure(super.error);
}

/// {@template check_feature_available_failure}
/// Thrown during the check whether the feature is available
/// if a failure occurs.
/// {@endtemplate}
class CheckFeatureAvailableFailure extends RemoteConfigException {
  /// {@macro check_feature_available_failure}
  const CheckFeatureAvailableFailure(super.error);
}

/// {@template fetch_remote_data_failure}
/// Thrown during the remote data fetch if a failure occurs.
/// {@endtemplate}
class FetchRemoteDataFailure extends RemoteConfigException {
  /// {@macro fetch_remote_data_failure}
  const FetchRemoteDataFailure(super.error);
}

/// {@template fetch_and_activate_failure}
/// Thrown during the fetch and activate if a failure occurs.
/// {@endtemplate}
class FetchAndActivateFailure extends RemoteConfigException {
  /// {@macro fetch_and_activate_failure}
  const FetchAndActivateFailure(super.error);
}

/// {@template activate_failure}
/// Thrown during the activate if a failure occurs.
/// {@endtemplate}
class ActivateFailure extends RemoteConfigException {
  /// {@macro activate_failure}
  const ActivateFailure(super.error);
}

/// {@template set_config_failure}
/// Thrown during the config set if a failure occurs.
/// {@endtemplate}
class SetConfigFailure extends RemoteConfigException {
  /// {@macro set_config_failure}
  const SetConfigFailure(super.error);
}

/// {@template remote_config_settings}
/// Configuration settings for remote config client.
/// {@endtemplate}
class RemoteConfigSettings {
  /// {@macro remote_config_settings}
  const RemoteConfigSettings({
    required this.fetchTimeout,
    required this.minimumFetchInterval,
  });

  /// Maximum duration to wait for a fetch to complete.
  final Duration fetchTimeout;

  /// Minimum interval between fetch requests.
  final Duration minimumFetchInterval;
}

/// {@template remote_config_update}
/// Represents an update to the remote configuration.
/// {@endtemplate}
abstract class RemoteConfigUpdate extends Equatable {
  /// {@macro remote_config_update}
  const RemoteConfigUpdate();

  /// The keys that were updated.
  abstract final Set<String> updatedKeys;

  @override
  List<Object?> get props => [updatedKeys];
}

/// {@template remote_config_client}
/// A pure-dart base remote config client for managing application
/// configuration from remote sources.
/// {@endtemplate}
abstract class RemoteConfigClient {
  /// {@macro remote_config_client}
  const RemoteConfigClient();

  /// Fetches the static remote data from the remote config.
  ///
  /// Throws [FetchRemoteDataFailure] if the fetch fails.
  FutureOr<T> fetchRemoteData<T>(String key);

  /// Broadcasts a stream of [RemoteConfigUpdate] whenever there is
  /// a change in remote config, e.g when some features become
  /// available to use.
  Stream<RemoteConfigUpdate> onConfigUpdated();

  /// Sets up custom remote config settings.
  ///
  /// Throws [SetConfigFailure] if setting the config fails.
  Future<void> setConfigSettings(RemoteConfigSettings settings);

  /// Activates the remote config.
  ///
  /// Throws [ActivateFailure] if the activate fails.
  Future<bool> activate();
}
