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
  Widget build(BuildContext context) =>
      PresentumOutlet<CampaignPresentumItem, CampaignSurface, CampaignVariant>(
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
            CampaignSurface.menuTile => factory.buildMenuTile(context, entry),
          };

          /// Do not apply padding if the resolved factory widget is
          /// SizedBox(empty).
          ///
          /// SizedBox can be returned in case of unhandled surface or variant
          /// or if the outlet has no active state value for specific surface.
          if (child case final SizedBox c) return c;

          // Render widget from the factory with padding.
          return Padding(padding: padding, child: child);
        },
      );
}
