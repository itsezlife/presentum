import 'package:equatable/equatable.dart';
import 'package:example/src/campaigns/camapigns.dart';
import 'package:presentum/presentum.dart';

typedef CampaignSlots =
    PresentumSlotState<CampaignPresentumItem, CampaignSurface, CampaignVariant>;

/// Immutable campaigns domain state owned by [CampaignsController].
final class CampaignsState extends Equatable {
  const CampaignsState._({
    required this.slots,
    required this.history,
    required this.candidates,
  });

  const CampaignsState.initial()
    : this._(
        slots: const PresentumSlotState.empty(),
        history: const PresentumSlotsHistory(),
        candidates: const [],
      );

  final CampaignSlots slots;
  final CampaignSlotsHistory history;
  final List<CampaignPresentumItem> candidates;

  CampaignsState copyWith({
    CampaignSlots? slots,
    CampaignSlotsHistory? history,
    List<CampaignPresentumItem>? candidates,
  }) => CampaignsState._(
    slots: slots ?? this.slots,
    history: history ?? this.history,
    candidates: candidates ?? this.candidates,
  );

  @override
  List<Object?> get props => [slots, history, candidates];
}
