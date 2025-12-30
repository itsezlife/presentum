import 'package:example/src/campaigns/camapigns.dart';
import 'package:example/src/campaigns/presentum/widgets/cyber_monday_banner.dart';
import 'package:example/src/campaigns/presentum/widgets/cyber_monday_dismissible_promo.dart';
import 'package:flutter/widgets.dart';

final campaignsPresentationWidgetFactory = CampaignPresentationWidgetFactory();

/// Basic implementation mapping campaign ids to widgets.
class CampaignPresentationWidgetFactory {
  factory CampaignPresentationWidgetFactory() => _instance;

  CampaignPresentationWidgetFactory._();

  static final CampaignPresentationWidgetFactory _instance =
      CampaignPresentationWidgetFactory._();

  Widget buildPopup(BuildContext context, CampaignPresentumItem entry) {
    final payload = entry.payload;
    final variant = entry.option.variant;

    switch (payload.id) {
      case CampaignId.blackFriday2025:
        return const BlackFridayDialog();
      case CampaignId.cyberMonday2025:
        return switch (variant) {
          CampaignVariant.fullscreenDialog =>
            const CyberMondayFullScreenDialog(),
          CampaignVariant.dialog => const CyberMondayDialog(),
          _ => const SizedBox.shrink(),
        };
      default:
        return const SizedBox.shrink();
    }
  }

  Widget buildBanner(BuildContext context, CampaignPresentumItem entry) {
    final payload = entry.payload;
    final isDismissible = entry.option.isDismissible;

    return switch (payload.id) {
      CampaignId.cyberMonday2025 =>
        isDismissible
            ? const RepaintBoundary(child: CyberMondayDismissiblePromo())
            : const CyberMondayBanner(),
      _ => const SizedBox.shrink(),
    };
  }

  Widget buildMenuTile(BuildContext context, CampaignPresentumItem entry) {
    final payload = entry.payload;
    return switch (payload.id) {
      CampaignId.cyberMonday2025 => const CyberMondayBanner(),
      _ => const SizedBox.shrink(),
    };
  }

  Widget buildFullscreenDialogPage(
    BuildContext context,
    CampaignPresentumItem entry,
  ) {
    final item = entry.payload;
    return switch (item.id) {
      CampaignId.cyberMonday2025 => const CyberMondayFullScreenDialog(),
      _ => const SizedBox.shrink(),
    };
  }
}
