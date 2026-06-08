import 'package:equatable/equatable.dart';
import 'package:example/src/updates/presentum/payload.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

typedef UpdatesSlots =
    PresentumSlotState<AppUpdatesItem, AppSurface, AppVariant>;

typedef UpdatesSlotsHistory =
    PresentumSlotsHistory<AppUpdatesItem, AppSurface, AppVariant>;

final class UpdatesState extends Equatable {
  const UpdatesState._({
    required this.slots,
    required this.history,
    required this.candidates,
  });

  const UpdatesState.initial()
    : this._(
        slots: const PresentumSlotState.empty(),
        history: const PresentumSlotsHistory(),
        candidates: const [],
      );

  final UpdatesSlots slots;
  final UpdatesSlotsHistory history;
  final List<AppUpdatesItem> candidates;

  UpdatesState copyWith({
    UpdatesSlots? slots,
    UpdatesSlotsHistory? history,
    List<AppUpdatesItem>? candidates,
  }) => UpdatesState._(
    slots: slots ?? this.slots,
    history: history ?? this.history,
    candidates: candidates ?? this.candidates,
  );

  @override
  List<Object?> get props => [slots, history, candidates];
}
