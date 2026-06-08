import 'package:example/src/campaigns/camapigns.dart';
import 'package:presentum/presentum.dart';

typedef CampaignSlotsHistoryEntry =
    PresentumSlotsHistoryEntry<
      CampaignPresentumItem,
      CampaignSurface,
      CampaignVariant
    >;

typedef CampaignSlotsHistory =
    PresentumSlotsHistory<
      CampaignPresentumItem,
      CampaignSurface,
      CampaignVariant
    >;

typedef CampaignSlotState =
    PresentumSlotState<CampaignPresentumItem, CampaignSurface, CampaignVariant>;
