import 'package:equatable/equatable.dart';
import 'package:example/src/feature/presentum/payload.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

typedef FeatureSlots = PresentumSlotState<FeatureItem, AppSurface, AppVariant>;

typedef FeatureSlotsHistory =
    PresentumSlotsHistory<FeatureItem, AppSurface, AppVariant>;

final class FeatureState extends Equatable {
  const FeatureState._({
    required this.slots,
    required this.history,
    required this.candidates,
  });

  const FeatureState.initial()
    : this._(
        slots: const PresentumSlotState.empty(),
        history: const PresentumSlotsHistory(),
        candidates: const [],
      );

  final FeatureSlots slots;
  final FeatureSlotsHistory history;
  final List<FeatureItem> candidates;

  FeatureState copyWith({
    FeatureSlots? slots,
    FeatureSlotsHistory? history,
    List<FeatureItem>? candidates,
  }) => FeatureState._(
    slots: slots ?? this.slots,
    history: history ?? this.history,
    candidates: candidates ?? this.candidates,
  );

  @override
  List<Object?> get props => [slots, history, candidates];
}
