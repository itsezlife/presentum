import 'dart:async';

import 'package:example/src/campaigns/camapigns.dart';
import 'package:presentum/presentum.dart';

/// Filters eligible campaigns and selects per-surface presentations.
final class CampaignSchedulingGuard extends CampaignGuard {
  CampaignSchedulingGuard({required this.eligibility});

  final EligibilityResolver<HasMetadata> eligibility;

  @override
  FutureOr<CampaignPresentumState> call(
    PresentumStorage storage,
    List<CampaignPresentumHistoryEntry> history,
    CampaignPresentumState$Mutable state,
    List<CampaignPresentumItem> candidates,
    Map<String, Object?> context,
  ) async {
    // 1) eligibility filter per campaign id.
    final eligibleEntries = <CampaignPresentumItem>[];
    for (final entry in candidates) {
      final isEligible = await eligibility.isEligible(entry.payload, context);
      if (isEligible) eligibleEntries.add(entry);
    }

    if (eligibleEntries.isEmpty) return state;

    // Highest priority first (per campaign), then by stage.
    eligibleEntries.sort((a, b) {
      final p = b.priority.compareTo(a.priority);
      if (p != 0) return p;
      final sa = a.stage ?? 0;
      final sb = b.stage ?? 0;
      return sa.compareTo(sb);
    });

    // Compute header-dismissed flag per campaign for sequencing logic.
    var hasHeader = true;
    var headerDismissed = false;
    if (eligibleEntries.any(
      (entry) => entry.surface == CampaignSurface.homeTopBanner,
    )) {
      for (final entry in eligibleEntries) {
        if (entry.surface != CampaignSurface.homeTopBanner) continue;
        final dismissedAt = await storage.getDismissedAt(
          entry.id,
          surface: entry.surface,
          variant: entry.variant,
        );
        if (dismissedAt != null && entry.option.isDismissible) {
          headerDismissed = true;
          break;
        }

        final cooldownMinutes = entry.option.cooldownMinutes;
        final until = dismissedAt != null && cooldownMinutes != null
            ? dismissedAt.add(Duration(minutes: cooldownMinutes))
            : null;
        headerDismissed = until != null && until.isAfter(DateTime.now());
      }
    } else {
      hasHeader = false;
    }

    // 2) always-on inline/banner per surface with header/footer sequencing.
    for (final entry in eligibleEntries) {
      final p = entry.option;
      if (!p.alwaysOnIfEligible) continue;

      final isHeaderDismissed = headerDismissed;

      // Header: show only until dismissed.
      if (entry.surface == CampaignSurface.homeTopBanner &&
          hasHeader &&
          isHeaderDismissed) {
        continue;
      }

      // Footer: enable only after header has been dismissed.
      if (entry.surface == CampaignSurface.homeFooterBanner &&
          !isHeaderDismissed &&
          hasHeader) {
        continue;
      }

      // Do not override higher-priority already set item.
      final slot = state.slots[entry.surface];
      if (slot?.active != null) continue;
      state.setActive(entry.surface, entry);
    }

    // If we had an active watchlist header in the history, don't show a popup.
    final hadAnActiveHomeTopBanner =
        history.isNotEmpty &&
        history.any(
          (entry) => entry.state.slots.values.any(
            (value) =>
                value.active?.option.surface == CampaignSurface.homeTopBanner,
          ),
        );
    if (hadAnActiveHomeTopBanner) return state;

    // 3) popup scheduling: determine order and set active + queue.
    final popupCandidates = await _popupCandidates(
      storage,
      eligibleEntries,
      state,
      context,
      headerDismissed || !hasHeader,
    );
    if (popupCandidates.isEmpty) return state;

    // First candidate becomes active, rest form the queue.
    final active = popupCandidates.first;

    state.setActive(CampaignSurface.popup, active);
    if (popupCandidates.length > 1) {
      state.setQueue(CampaignSurface.popup, popupCandidates.sublist(1));
    }

    return state;
  }

  /// Returns popup-eligible entries in display order.
  Future<List<CampaignPresentumItem>> _popupCandidates(
    PresentumStorage storage,
    List<CampaignPresentumItem> items,
    PresentumState$Mutable<
      CampaignPresentumItem,
      CampaignSurface,
      CampaignVariant
    >
    state,
    Map<String, Object?> context,
    bool headerDismissed,
  ) async {
    final result = <CampaignPresentumItem>[];
    final now = DateTime.now();
    final appOpenedCount = context['appOpenedCount'] as int? ?? 0;

    CampaignPresentumItem? fullscreenDialogEntry;
    for (final entry in items) {
      if (entry.surface != CampaignSurface.popup) continue;

      // Do not show popups before header is dismissed (when applicable).
      if (!headerDismissed) continue;

      final p = entry;
      // final isCyberMonday = entry.id == CampaignId.cyberMonday2025;
      final isFullscreen = p.variant == CampaignVariant.fullscreenDialog;
      if (isFullscreen) {
        fullscreenDialogEntry = entry;
      }
      final isDialog = p.variant == CampaignVariant.dialog;

      // Basic dismissal gating for all popup variants.
      final dismissedAt = await storage.getDismissedAt(
        entry.id,
        surface: p.surface,
        variant: p.variant,
      );
      final cooldownMinutes = p.option.cooldownMinutes;
      final until = dismissedAt != null && cooldownMinutes != null
          ? dismissedAt.add(Duration(minutes: cooldownMinutes))
          : null;
      if (until != null && until.isAfter(now)) {
        continue;
      }

      // Cyber Monday fullscreen popup:
      // - Only after app has been opened at least once.
      // - Not dismissed (handled above).
      // if (isCyberMonday && isFullscreen) {
      //   if (appOpenedCount < 1) continue;
      // }
      if (isFullscreen) {
        if (appOpenedCount < 1) continue;
      }

      DateTime? last;

      // Check if the dialog popup should be shown based on the fullscreen
      // popup.
      if (fullscreenDialogEntry case final fullscreenDialogEntry?
          when isDialog) {
        // Cyber Monday dialog popup:
        // - Only after fullscreen popup has been shown at least once.
        // - Cooldown counted from the last fullscreen show time.
        final fullscreenShown = await storage.getShownCount(
          fullscreenDialogEntry.id,
          period: const Duration(days: 3650),
          surface: CampaignSurface.popup,
          variant: CampaignVariant.fullscreenDialog,
        );
        if (fullscreenShown <= 0) continue;

        final dialogLastShown = await storage.getLastShown(
          entry.id,
          surface: CampaignSurface.popup,
          variant: CampaignVariant.dialog,
        );

        last =
            dialogLastShown ??
            await storage.getLastShown(
              fullscreenDialogEntry.id,
              surface: CampaignSurface.popup,
              variant: CampaignVariant.fullscreenDialog,
            );
      } else if (isDialog) {
        // If the fullscreen dialog popup does not exist, show the dialog popup
        // based on this variant itself.
        last = await storage.getLastShown(
          entry.id,
          surface: p.surface,
          variant: p.variant,
        );
      }

      final cool = p.option.cooldownMinutes ?? 0;
      final canShow =
          last == null || now.isAfter(last.add(Duration(minutes: cool)));
      if (!canShow) continue;

      // Impression cap (per surface+variant).
      final cap = p.option.maxImpressions;
      if (cap case final cap? when cap >= 0) {
        final count = await storage.getShownCount(
          entry.id,
          period: const Duration(days: 3650),
          surface: p.surface,
          variant: p.variant,
        );
        if (count >= cap) continue;
      }

      result.add(entry);
    }
    return result;
  }
}
