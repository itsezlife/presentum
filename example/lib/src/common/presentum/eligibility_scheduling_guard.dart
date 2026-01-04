import 'package:presentum/presentum.dart';

/// {@template eligibility_scheduling_guard}
/// Very basic and simple generic scheduling guard that filters items based on
/// eligibility and adds them as active.
///
/// Use this guard just when you only need to add all eligible items as active
/// without any additional complex scheduling, sequencing, priority, etc.
///
/// - See [PresentumGuard] for more details.
/// {@endtemplate}
abstract base class IEligibilitySchedulingGuard<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends PresentumGuard<TItem, S, V> {
  /// {@macro eligibility_scheduling_guard}
  IEligibilitySchedulingGuard({
    required this.eligibilityResolver,
    super.refresh,
  });

  /// The eligibility resolver to use for filtering items.
  final EligibilityResolver<TItem> eligibilityResolver;

  @override
  Future<PresentumState<TItem, S, V>> call(
    PresentumStorage<S, V> storage,
    List<PresentumHistoryEntry<TItem, S, V>> history,
    PresentumState$Mutable<TItem, S, V> state,
    List<TItem> candidates,
    Map<String, Object?> context,
  ) async {
    final filtered = <TItem>[];

    for (final item in candidates) {
      // Check eligibility
      final isEligible = await eligibilityResolver.isEligible(item, context);
      if (!isEligible) continue;

      filtered.add(item);
    }

    // Set active items for their respective surfaces
    for (final item in filtered) {
      state.setActive(item.surface, item);
    }

    return state;
  }
}

/// Guard that schedules items based on eligibility.
///
/// - See [IEligibilitySchedulingGuard] for more details.
/// {@macro eligibility_scheduling_guard}
final class EligibilitySchedulingGuard<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends IEligibilitySchedulingGuard<TItem, S, V> {
  /// {@macro eligibility_scheduling_guard}
  EligibilitySchedulingGuard({
    required super.eligibilityResolver,
    super.refresh,
  });
}
