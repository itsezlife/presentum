import 'package:equatable/equatable.dart';
import 'package:example/src/shop/presentum/recommendation_payload.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

typedef RecommendationSlots =
    PresentumSlotState<RecommendationItem, AppSurface, AppVariant>;

typedef RecommendationSlotsHistory =
    PresentumSlotsHistory<RecommendationItem, AppSurface, AppVariant>;

final class RecommendationState extends Equatable {
  const RecommendationState._({
    required this.slots,
    required this.history,
    required this.candidates,
  });

  const RecommendationState.initial()
    : this._(
        slots: const PresentumSlotState.empty(),
        history: const PresentumSlotsHistory(),
        candidates: const [],
      );

  final RecommendationSlots slots;
  final RecommendationSlotsHistory history;
  final List<RecommendationItem> candidates;

  RecommendationState copyWith({
    RecommendationSlots? slots,
    RecommendationSlotsHistory? history,
    List<RecommendationItem>? candidates,
  }) => RecommendationState._(
    slots: slots ?? this.slots,
    history: history ?? this.history,
    candidates: candidates ?? this.candidates,
  );

  @override
  List<Object?> get props => [slots, history, candidates];
}
