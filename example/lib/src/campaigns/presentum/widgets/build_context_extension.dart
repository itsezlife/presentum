import 'package:example/src/campaigns/presentum/payload.dart';
import 'package:example/src/campaigns/presentum/surfaces.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:presentum/presentum.dart';

/// Extension methods for [BuildContext].
extension CampaignsBuildContextExtension on BuildContext {
  /// Receives the [InheritedPresentum] instance from the elements tree.
  Presentum<CampaignPresentumItem, CampaignSurface, CampaignVariant>
  get campaignsPresentum =>
      presentum<CampaignPresentumItem, CampaignSurface, CampaignVariant>();

  /// Receives the [CampaignPresentumItem] instance from the elements tree.
  CampaignPresentumItem get campaignItem =>
      presentumItem<CampaignPresentumItem, CampaignSurface, CampaignVariant>();

  /// Receives the [CampaignPayload] instance from the elements tree.
  CampaignPresentumItem get watchCampaignPresentumItem =>
      watchPresentumItem<
        CampaignPresentumItem,
        CampaignSurface,
        CampaignVariant
      >();
}
