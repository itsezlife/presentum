import 'package:presentum/presentum.dart';

enum CampaignSurface with PresentumSurface {
  popup,
  homeTopBanner,
  homeFooterBanner,
  menuTile;

  static CampaignSurface fromName(String name, {CampaignSurface? fallback}) =>
      switch (name) {
        'popup' => CampaignSurface.popup,
        'homeTopBanner' => CampaignSurface.homeTopBanner,
        'homeFooterBanner' => CampaignSurface.homeFooterBanner,
        'menuTile' => CampaignSurface.menuTile,
        _ => fallback ?? (throw ArgumentError.value(name)),
      };
}

enum CampaignVariant with PresentumVisualVariant {
  fullscreenDialog,
  dialog,
  banner,
  inline;

  static CampaignVariant fromName(String name, {CampaignVariant? fallback}) =>
      switch (name) {
        'fullscreenDialog' => CampaignVariant.fullscreenDialog,
        'dialog' => CampaignVariant.dialog,
        'banner' => CampaignVariant.banner,
        'inline' => CampaignVariant.inline,
        _ => fallback ?? (throw ArgumentError.value(name)),
      };
}
