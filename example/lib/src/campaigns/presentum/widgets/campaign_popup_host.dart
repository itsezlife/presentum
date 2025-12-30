import 'dart:async';

import 'package:example/src/campaigns/camapigns.dart';
import 'package:flutter/material.dart';
import 'package:presentum/presentum.dart';

/// Watches the popup surface and presents dialogs/fullscreen promos.
class CampaignPopupHost extends StatefulWidget {
  const CampaignPopupHost({required this.child, super.key});

  final Widget child;

  @override
  State<CampaignPopupHost> createState() => _CampaignPopupHostState();
}

class _CampaignPopupHostState extends State<CampaignPopupHost>
    with
        PresentumPopupSurfaceStateMixin<
          CampaignPresentumItem,
          CampaignSurface,
          CampaignVariant,
          CampaignPopupHost
        > {
  @override
  CampaignSurface get surface => CampaignSurface.popup;

  @override
  bool get ignoreDuplicates => true; // for simplicity, we ignore duplicates

  @override
  Future<void> markDismissed({required CampaignPresentumItem entry}) async {
    final campaigns = context.campaignsPresentum;
    await campaigns.markDismissed(entry);
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  Future<PopupPresentResult> present(CampaignPresentumItem entry) async {
    if (!mounted) return PopupPresentResult.notPresented;

    // Record impression through the campaigns.
    final campaigns = context.campaignsPresentum;
    await campaigns.markShown(entry);

    if (!mounted) return PopupPresentResult.notPresented;

    final factory = campaignsPresentationWidgetFactory;

    final fullscreenDialog =
        entry.option.variant == CampaignVariant.fullscreenDialog;

    // Result is true if dismissed by user(already marked as dismissed), null
    // if it was dismissed by the system or otherwise, without marking as
    // dismissed.
    final result = await showDialog<bool?>(
      context: context,
      builder: (context) => InheritedPresentum.value(
        value: campaigns,
        child:
            InheritedPresentumItem<
              CampaignPresentumItem,
              CampaignSurface,
              CampaignVariant
            >(item: entry, child: factory.buildPopup(context, entry)),
      ),
      barrierDismissible: false,
      fullscreenDialog: fullscreenDialog,
    );

    return result == true
        ? PopupPresentResult.userDismissed
        : PopupPresentResult.systemDismissed;
  }
}
