import 'dart:convert';

import 'package:example/src/maintenance/data/maintenance_store.dart';
import 'package:example/src/maintenance/presentum/inherited_provider.dart';
import 'package:example/src/maintenance/presentum/payload.dart';
import 'package:flutter/cupertino.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

/// See sample payload in [MaintenancePayload].
class MaintenanceProvider extends ChangeNotifier {
  MaintenanceProvider({
    required this.maintenanceStore,
    required this.engine,
    required this.eligibilityResolver,
    this.onError,
  }) {
    maintenanceStore.addListener(_onMaintenanceStoreChanged);
    _evaluateCandidates();

    _lifecycleListener = AppLifecycleListener(onResume: _evaluateCandidates);
  }

  final MaintenanceStore maintenanceStore;
  final EligibilityResolver<MaintenanceItem> eligibilityResolver;
  final PresentumEngine<MaintenanceItem, AppSurface, AppVariant> engine;
  final void Function(Object error, StackTrace stackTrace)? onError;

  static MaintenanceProvider of(BuildContext context) =>
      MaintenanceProviderScope.of(context).provider;

  late final AppLifecycleListener _lifecycleListener;

  List<MaintenanceItem> candidates = [];

  void _onMaintenanceStoreChanged() {
    _evaluateCandidates();
  }

  Future<void> _evaluateCandidates() async {
    try {
      final maintenancePayload = maintenanceStore.maintenancePayload;
      if (maintenancePayload == null) {
        candidates = [];
        engine.setCandidates(
          (state, candidates) => candidates
              .where(
                (candidate) =>
                    candidate.payload.id != MaintenanceId.maintenance,
              )
              .toList(),
        );
        notifyListeners();
        return;
      }

      final maintenanceCandidates = <MaintenanceItem>[];
      for (final option in maintenancePayload.options) {
        maintenanceCandidates.add(
          MaintenanceItem(payload: maintenancePayload, option: option),
        );
      }

      final eligibleCandidates = <MaintenanceItem>[];
      for (final candidate in maintenanceCandidates) {
        final isEligible = await eligibilityResolver.isEligible(candidate, {});
        if (isEligible) {
          eligibleCandidates.add(candidate);
        }
      }

      final hasEligibleCandidates = eligibleCandidates.isNotEmpty;
      candidates = eligibleCandidates;

      if (hasEligibleCandidates) {
        engine.setCandidates((state, candidates) => eligibleCandidates);
      } else {
        engine.setCandidates(
          (state, candidates) => candidates
              .where(
                (candidate) => candidate.payload.id != maintenancePayload.id,
              )
              .toList(),
        );
      }
      notifyListeners();
    } on Object catch (error, stackTrace) {
      onError?.call(error, stackTrace);
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    maintenanceStore.removeListener(_onMaintenanceStoreChanged);
    super.dispose();
  }
}

/// {@template pretty_json_extension}
/// Extension methods for the Object class.
/// {@endtemplate}
extension PrettyJsonExtension on Map<String, dynamic> {
  /// Returns the object as a pretty JSON string.
  String prettyJson() => const JsonEncoder.withIndent('  ').convert(this);
}
