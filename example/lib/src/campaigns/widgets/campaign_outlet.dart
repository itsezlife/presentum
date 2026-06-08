import 'package:control/control.dart';
import 'package:example/src/campaigns/camapigns.dart';
import 'package:flutter/widgets.dart';
import 'package:presentum/presentum.dart';

typedef CampaignBuilder =
    Widget Function(BuildContext context, CampaignPresentumItem entry);

class CampaignOutlet extends StatelessWidget {
  const CampaignOutlet({
    required this.surface,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final CampaignSurface surface;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final controller = context.controllerOf<CampaignsController>();
    return ValueListenableBuilder(
      valueListenable: controller.select((s) => s.slots),
      builder: (context, slots, _) =>
          PresentumOutlet<
            CampaignPresentumItem,
            CampaignSurface,
            CampaignVariant
          >(
            slots: slots,
            surface: surface,
            builder: (context, entry) {
              final factory = campaignsPresentationWidgetFactory;
              final child = switch (surface) {
                CampaignSurface.popup => factory.buildPopup(context, entry),
                CampaignSurface.homeTopBanner ||
                CampaignSurface.homeFooterBanner => factory.buildBanner(
                  context,
                  entry,
                ),
                CampaignSurface.menuTile => factory.buildMenuTile(
                  context,
                  entry,
                ),
              };

              if (child case final SizedBox c) return c;

              return Padding(padding: padding, child: child);
            },
          ),
    );
  }
}
