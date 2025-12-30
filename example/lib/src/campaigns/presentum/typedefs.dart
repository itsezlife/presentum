import 'package:example/src/campaigns/camapigns.dart';
import 'package:presentum/presentum.dart';

/// Guard for validating campaign presentation access.
typedef CampaignGuard =
    PresentumGuard<CampaignPresentumItem, CampaignSurface, CampaignVariant>;

/// Observer for campaign presentations.
typedef CampaignStateObserver =
    PresentumStateObserver<
      CampaignPresentumItem,
      CampaignSurface,
      CampaignVariant
    >;

typedef CampaignPresentumState =
    PresentumState<CampaignPresentumItem, CampaignSurface, CampaignVariant>;

typedef CampaignPresentumState$Mutable =
    PresentumState$Mutable<
      CampaignPresentumItem,
      CampaignSurface,
      CampaignVariant
    >;

typedef CampaignPresentumState$Immutable =
    PresentumState$Immutable<
      CampaignPresentumItem,
      CampaignSurface,
      CampaignVariant
    >;

typedef CampaignPresentumHistoryEntry =
    PresentumHistoryEntry<
      CampaignPresentumItem,
      CampaignSurface,
      CampaignVariant
    >;
