import 'package:example/src/campaigns/camapigns.dart';
import 'package:example/src/common/presentum/sync_state_with_candidates_guard.dart';

/// {@template sync_campaigns_state_with_candidates_guard}
/// Syncs the current state slots with the latest candidates.
///
/// - See [SyncStateWithCandidatesGuard] for more details.
/// {@endtemplate}
final class SyncCampaignsStateWithCandidatesGuard
    extends
        SyncStateWithCandidatesGuard<
          CampaignPresentumItem,
          CampaignSurface,
          CampaignVariant
        > {
  /// {@macro sync_campaigns_state_with_candidates_guard}
  SyncCampaignsStateWithCandidatesGuard({super.refresh});
}
