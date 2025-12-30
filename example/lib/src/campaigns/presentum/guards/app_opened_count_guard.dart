import 'dart:async';

import 'package:example/src/campaigns/camapigns.dart';
import 'package:presentum/presentum.dart';

final class AppOpenedCountGuard
    extends
        PresentumGuard<
          CampaignPresentumItem,
          CampaignSurface,
          CampaignVariant
        > {
  AppOpenedCountGuard({required this.appOpenedCount, super.refresh});

  final FutureOr<int> Function() appOpenedCount;

  @override
  FutureOr<CampaignPresentumState> call(
    PresentumStorage storage,
    List<CampaignPresentumHistoryEntry> history,
    CampaignPresentumState$Mutable state,
    List<CampaignPresentumItem> candidates,
    Map<String, Object?> context,
  ) async {
    final count = await appOpenedCount();
    context['appOpenedCount'] = count;
    return state;
  }
}
