import 'dart:async';

import 'package:example/src/campaigns/camapigns.dart';
import 'package:example/src/common/presentum/remove_ineligible_candidates_guard.dart';
import 'package:presentum/presentum.dart';

final class RemoveIneligibleCampaignsGuard
    extends
        IRemoveIneligibleCandidatesGuard<
          CampaignPresentumItem,
          CampaignSurface,
          CampaignVariant
        > {
  RemoveIneligibleCampaignsGuard({required super.eligibility});

  @override
  FutureOr<
    PresentumState<CampaignPresentumItem, CampaignSurface, CampaignVariant>
  >
  call(
    PresentumStorage storage,
    List<
      PresentumHistoryEntry<
        CampaignPresentumItem,
        CampaignSurface,
        CampaignVariant
      >
    >
    history,
    PresentumState$Mutable<
      CampaignPresentumItem,
      CampaignSurface,
      CampaignVariant
    >
    state,
    List<CampaignPresentumItem> candidates,
    Map<String, Object?> context,
  ) async {
    var newState = await super.call(
      storage,
      history,
      state,
      candidates,
      context,
    );

    newState =
        newState
            is PresentumState$Mutable<
              CampaignPresentumItem,
              CampaignSurface,
              CampaignVariant
            >
        ? newState
        : newState.mutate();

    final homeTopBannerSlot = newState.findSlot(
      (surface, slot) => surface == CampaignSurface.homeTopBanner,
    );
    if (homeTopBannerSlot?.active != null) {
      newState.clearSurface(CampaignSurface.homeFooterBanner);
    }
    return newState;
  }
}
