import 'package:example/src/common/presentum/sync_state_with_candidates_guard.dart';
import 'package:example/src/feature/presentum/payload.dart';
import 'package:shared/shared.dart';

/// {@template sync_feature_state_guard}
/// This guard keeps the feature state in sync with the latest candidates.
///
/// - See [SyncStateWithCandidatesGuard] for more details.
/// {@endtemplate}
final class SyncFeatureStateGuard
    extends SyncStateWithCandidatesGuard<FeatureItem, AppSurface, AppVariant> {
  /// {@macro sync_feature_state_guard}
  SyncFeatureStateGuard({super.refresh});

  @override
  bool areItemsTheSame(FeatureItem oldItem, FeatureItem newItem) {
    if (oldItem.payload.dependsOnFeatureKey !=
        newItem.payload.dependsOnFeatureKey) {
      return false;
    }
    if (oldItem.payload.featureKey != newItem.payload.featureKey) {
      return false;
    }

    final defaultItemsAreTheSame = super.areItemsTheSame(oldItem, newItem);
    return defaultItemsAreTheSame;
  }
}
