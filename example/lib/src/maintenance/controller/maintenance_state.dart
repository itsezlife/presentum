import 'package:equatable/equatable.dart';
import 'package:example/src/maintenance/presentum/payload.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

typedef MaintenanceSlots =
    PresentumSlotState<MaintenanceItem, AppSurface, AppVariant>;

typedef MaintenanceSlotsHistory =
    PresentumSlotsHistory<MaintenanceItem, AppSurface, AppVariant>;

final class MaintenanceState extends Equatable {
  const MaintenanceState._({
    required this.slots,
    required this.history,
    required this.candidates,
  });

  const MaintenanceState.initial()
    : this._(
        slots: const PresentumSlotState.empty(),
        history: const PresentumSlotsHistory(),
        candidates: const [],
      );

  final MaintenanceSlots slots;
  final MaintenanceSlotsHistory history;
  final List<MaintenanceItem> candidates;

  MaintenanceState copyWith({
    MaintenanceSlots? slots,
    MaintenanceSlotsHistory? history,
    List<MaintenanceItem>? candidates,
  }) => MaintenanceState._(
    slots: slots ?? this.slots,
    history: history ?? this.history,
    candidates: candidates ?? this.candidates,
  );

  @override
  List<Object?> get props => [slots, history, candidates];
}
