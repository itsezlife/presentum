import 'package:example/src/campaigns/camapigns.dart';
import 'package:flutter/material.dart';
import 'package:presentum/presentum.dart';

/// Presents campaign popup dialogs using [PresentumPopupHost] callbacks.
abstract final class CampaignPopupPresenter {
  const CampaignPopupPresenter._();

  static Future<PopupPresentResult> present(
    BuildContext context,
    CampaignPresentumItem entry,
  ) async {
    final factory = campaignsPresentationWidgetFactory;
    final fullscreenDialog =
        entry.option.variant == CampaignVariant.fullscreenDialog;

    final result = await showDialog<bool?>(
      context: context,
      builder: (dialogContext) =>
          InheritedPresentumItem<
            CampaignPresentumItem,
            CampaignSurface,
            CampaignVariant
          >(item: entry, child: factory.buildPopup(dialogContext, entry)),
      barrierDismissible: false,
      fullscreenDialog: fullscreenDialog,
    );

    return result == true
        ? PopupPresentResult.userDismissed
        : PopupPresentResult.systemDismissed;
  }
}
