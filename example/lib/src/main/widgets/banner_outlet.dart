import 'package:app_ui/app_ui.dart';
import 'package:example/src/campaigns/camapigns.dart';
import 'package:example/src/common/widgets/fade_size_transition_switcher.dart';
import 'package:example/src/feature/presentum/payload.dart';
import 'package:example/src/main/widgets/new_year_banner.dart';
import 'package:flutter/material.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

/// {@template banner_outlet}
/// BannerOutlet widget
/// {@endtemplate}
class BannerOutlet extends StatelessWidget {
  const BannerOutlet({super.key});

  @override
  Widget build(BuildContext context) =>
      PresentumOutlet$Composition2<
        CampaignPresentumItem,
        FeatureItem,
        CampaignSurface,
        CampaignVariant,
        AppSurface,
        AppVariant
      >(
        surface1: CampaignSurface.homeTopBanner,
        surface2: AppSurface.homeHeader,
        resolverMode: OutletGroupMode.custom,
        resolver: (campaignItems, featureItems) {
          final allItems = <PresentumItem>[...campaignItems, ...featureItems]
            ..sort((a, b) => b.priority.compareTo(a.priority));

          if (allItems.isEmpty) {
            return <PresentumItem>[];
          }

          return [allItems.first];
        },
        compositeBuilder: (context, items) => FadeSizeTransitionSwitcher(
          isForwardMove: true,
          child: switch (items.firstOrNull) {
            CampaignPresentumItem(:final surface) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: CampaignOutlet(surface: surface),
            ),
            FeatureItem() => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: NewYearBanner(),
            ),
            _ => const SizedBox.shrink(),
          },
        ),
      );
}
