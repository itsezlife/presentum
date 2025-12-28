import 'package:example/src/maintenance/presentum/payload.dart';
import 'package:flutter/cupertino.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

const _maintancePayload = MaintenancePayload(
  id: 'maintenance',
  priority: 1000,
  metadata: {
    'any_of': [
      {
        'time_range': {
          'start': '2025-12-28T00:00:00Z',
          'end': '2025-12-28T23:59:59Z',
        },
      },
      {'is_active': true},
    ],
  },
  options: [
    MaintenanceOption(
      surface: AppSurface.maintenanceView,
      variant: AppVariant.maintenanceScreenRestartButton,
      isDismissible: false,
      alwaysOnIfEligible: true,
    ),
  ],
);

class MaintenanceProvider extends ChangeNotifier {
  MaintenanceProvider({required this.engine}) {
    _initialize();
  }

  final PresentumEngine<MaintenanceItem, AppSurface, AppVariant> engine;

  void _initialize() {
    final maintanceCandidates = _maintancePayload.options
        .map(
          (option) =>
              MaintenanceItem(payload: _maintancePayload, option: option),
        )
        .toList();
    engine.setCandidates((state, candidates) => maintanceCandidates);
  }
}
