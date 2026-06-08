import 'package:example/src/campaigns/camapigns.dart';
import 'package:presentum/eligibility.dart';
import 'package:presentum/presentum.dart';

/// Filters eligible campaigns and selects per-surface presentations.
final class CampaignSchedulingStep
    implements
        PresentumResolverStep<
          CampaignPresentumItem,
          CampaignSurface,
          CampaignVariant
        > {
  const CampaignSchedulingStep({required this.eligibility});

  final EligibilityResolver<HasMetadata> eligibility;

  @override
  Future<
    PresentumSlotState<CampaignPresentumItem, CampaignSurface, CampaignVariant>
  >
  call(
    PresentumStepInput<CampaignPresentumItem, CampaignSurface, CampaignVariant>
    input,
  ) async {
    final eligibleEntries = <CampaignPresentumItem>[];
    for (final entry in input.candidates) {
      final isEligible = await eligibility.isEligible(
        entry.payload,
        input.context,
      );
      if (isEligible) eligibleEntries.add(entry);
    }

    if (eligibleEntries.isEmpty) return input.current;

    eligibleEntries.sort((a, b) {
      final p = b.priority.compareTo(a.priority);
      if (p != 0) return p;
      final sa = a.stage ?? 0;
      final sb = b.stage ?? 0;
      return sa.compareTo(sb);
    });

    var hasHeader = true;
    var headerDismissed = false;
    if (eligibleEntries.any(
      (entry) => entry.surface == CampaignSurface.homeTopBanner,
    )) {
      for (final entry in eligibleEntries) {
        if (entry.surface != CampaignSurface.homeTopBanner) continue;
        final dismissedAt = await input.storage.getDismissedAt(
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
        headerDismissed = until != null && until.isAfter(input.now);
      }
    } else {
      hasHeader = false;
    }

    var slots = input.current;

    for (final entry in eligibleEntries) {
      final p = entry.option;
      if (!p.alwaysOnIfEligible) continue;

      final isHeaderDismissed = headerDismissed;

      if (entry.surface == CampaignSurface.homeTopBanner &&
          hasHeader &&
          isHeaderDismissed) {
        continue;
      }

      if (entry.surface == CampaignSurface.homeFooterBanner &&
          !isHeaderDismissed &&
          hasHeader) {
        continue;
      }

      if (slots.activeFor(entry.surface) != null) continue;
      slots = slots.withActive(entry.surface, entry);
    }

    final hadAnActiveHomeTopBanner =
        input.history.entries.isNotEmpty &&
        input.history.entries.any(
          (entry) => entry.slots.activeItems.any(
            (item) => item.surface == CampaignSurface.homeTopBanner,
          ),
        );
    if (hadAnActiveHomeTopBanner) return slots;

    final popupCandidates = await _popupCandidates(
      input,
      eligibleEntries,
      headerDismissed || !hasHeader,
    );
    if (popupCandidates.isEmpty) return slots;

    slots = slots.withActive(CampaignSurface.popup, popupCandidates.first);
    if (popupCandidates.length > 1) {
      slots = slots.withReorderedQueue(
        CampaignSurface.popup,
        popupCandidates.sublist(1),
      );
    }

    return slots;
  }

  Future<List<CampaignPresentumItem>> _popupCandidates(
    PresentumStepInput<CampaignPresentumItem, CampaignSurface, CampaignVariant>
    input,
    List<CampaignPresentumItem> items,
    bool headerDismissed,
  ) async {
    final result = <CampaignPresentumItem>[];
    final now = input.now;
    final appOpenedCount = input.context['appOpenedCount'] as int? ?? 0;

    CampaignPresentumItem? fullscreenDialogEntry;
    for (final entry in items) {
      if (entry.surface != CampaignSurface.popup) continue;
      if (!headerDismissed) continue;

      final p = entry;
      final isFullscreen = p.variant == CampaignVariant.fullscreenDialog;
      if (isFullscreen) {
        fullscreenDialogEntry = entry;
      }
      final isDialog = p.variant == CampaignVariant.dialog;

      final dismissedAt = await input.storage.getDismissedAt(
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

      if (isFullscreen) {
        if (appOpenedCount < 1) continue;
      }

      DateTime? last;

      if (fullscreenDialogEntry case final fullscreenDialogEntry?
          when isDialog) {
        final fullscreenShown = await input.storage.getShownCount(
          fullscreenDialogEntry.id,
          period: const Duration(days: 3650),
          surface: CampaignSurface.popup,
          variant: CampaignVariant.fullscreenDialog,
        );
        if (fullscreenShown <= 0) continue;

        final dialogLastShown = await input.storage.getLastShown(
          entry.id,
          surface: CampaignSurface.popup,
          variant: CampaignVariant.dialog,
        );

        last =
            dialogLastShown ??
            await input.storage.getLastShown(
              fullscreenDialogEntry.id,
              surface: CampaignSurface.popup,
              variant: CampaignVariant.fullscreenDialog,
            );
      } else if (isDialog) {
        last = await input.storage.getLastShown(
          entry.id,
          surface: p.surface,
          variant: p.variant,
        );
      }

      final cool = p.option.cooldownMinutes ?? 0;
      final canShow =
          last == null || now.isAfter(last.add(Duration(minutes: cool)));
      if (!canShow) continue;

      final cap = p.option.maxImpressions;
      if (cap case final cap? when cap >= 0) {
        final count = await input.storage.getShownCount(
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
