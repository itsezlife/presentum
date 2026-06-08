import 'package:example/src/campaigns/presentum/payload.dart';
import 'package:example/src/campaigns/presentum/surfaces.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:presentum/presentum.dart';

/// Extension methods for [BuildContext].
extension CampaignsBuildContextExtension on BuildContext {
  /// Active [CampaignPresentumItem] from [InheritedPresentumItem].
  CampaignPresentumItem get campaignItem =>
      presentumItem<CampaignPresentumItem, CampaignSurface, CampaignVariant>();

  /// Watches the active [CampaignPresentumItem].
  CampaignPresentumItem get watchCampaignPresentumItem =>
      watchPresentumItem<
        CampaignPresentumItem,
        CampaignSurface,
        CampaignVariant
      >();
}
