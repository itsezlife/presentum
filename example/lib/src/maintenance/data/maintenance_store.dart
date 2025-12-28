import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:example/src/maintenance/presentum/payload.dart';
import 'package:firebase_remote_config_client/firebase_remote_config_client.dart';
import 'package:flutter/foundation.dart';
import 'package:remote_config_repository/remote_config_repository.dart';

class MaintenanceStore extends ChangeNotifier {
  MaintenanceStore({required RemoteConfigRepository remoteConfigRepository})
    : _remoteConfigRepository = remoteConfigRepository;

  final RemoteConfigRepository _remoteConfigRepository;
  StreamSubscription<RemoteConfigUpdate>? _remoteConfigSubscription;

  MaintenancePayload? _maintenancePayload;
  MaintenancePayload? get maintenancePayload => _maintenancePayload;

  Future<void> initialize() async {
    await _fetchAndUpdateMaintenance();

    await _remoteConfigSubscription?.cancel();
    _remoteConfigSubscription = _remoteConfigRepository
        .onConfigUpdated()
        .listen((update) async {
          await _remoteConfigRepository.activate();

          dev.log(
            'remote config updated: ${update.updatedKeys}',
            name: 'MaintenanceStore',
          );
          if (!update.updatedKeys.contains(MaintenanceId.maintenance)) {
            return;
          }

          await _fetchAndUpdateMaintenance();
        });
  }

  Future<void> _fetchAndUpdateMaintenance() async {
    final maintenance = await _remoteConfigRepository.fetchRemoteData<String>(
      MaintenanceId.maintenance,
    );

    if (maintenance case final maintenance
        when maintenance.isEmpty || maintenance == '{}') {
      return;
    }

    final maintenanceJson = jsonDecode(maintenance) as Map<String, dynamic>;
    final payload = MaintenancePayload.fromJson(maintenanceJson);
    if (payload.options.isEmpty) {
      return;
    }

    _maintenancePayload = payload;
    notifyListeners();
  }

  @override
  void dispose() {
    _remoteConfigSubscription?.cancel();
    super.dispose();
  }
}
