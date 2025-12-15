import 'package:flutter_test/flutter_test.dart';
import 'package:presentum/presentum.dart';

import 'fake_payload.dart';

void main() {
  group('PresentumStateTransition', () {
    test('creates transition with correct properties', () {
      final oldState =
          PresentumState$Immutable<
            FakeResolved,
            FakeSurface,
            FakeVisualVariant
          >(slots: const {}, intention: PresentumStateIntention.auto);

      final newState =
          PresentumState$Immutable<
            FakeResolved,
            FakeSurface,
            FakeVisualVariant
          >(
            slots: {
              FakeSurface.banner: PresentumSlot(
                surface: FakeSurface.banner,
                active: createFakeResolved(
                  'c1',
                  FakeSurface.banner,
                  FakeVisualVariant.variantA,
                ),
                queue: const [],
              ),
            },
            intention: PresentumStateIntention.auto,
          );

      final timestamp = DateTime.now();
      final transition = PresentumStateTransition(
        oldState: oldState,
        newState: newState,
        timestamp: timestamp,
      );

      expect(transition.oldState, equals(oldState));
      expect(transition.newState, equals(newState));
      expect(transition.timestamp, equals(timestamp));
    });

    test('equality', () {
      final oldState =
          PresentumState$Immutable<
            FakeResolved,
            FakeSurface,
            FakeVisualVariant
          >(slots: const {}, intention: PresentumStateIntention.auto);
      final newState =
          PresentumState$Immutable<
            FakeResolved,
            FakeSurface,
            FakeVisualVariant
          >(slots: const {}, intention: PresentumStateIntention.replace);
      final timestamp = DateTime.now();

      final t1 = PresentumStateTransition(
        oldState: oldState,
        newState: newState,
        timestamp: timestamp,
      );
      final t2 = PresentumStateTransition(
        oldState: oldState,
        newState: newState,
        timestamp: timestamp,
      );

      expect(t1, equals(t2));
      expect(t1.hashCode, equals(t2.hashCode));
    });
  });

  test('detects variant activation', () {
    final oldState =
        PresentumState$Immutable<FakeResolved, FakeSurface, FakeVisualVariant>(
          slots: const {
            FakeSurface.banner: PresentumSlot.empty(FakeSurface.banner),
          },
          intention: PresentumStateIntention.auto,
        );

    final item = createFakeResolved(
      'c1',
      FakeSurface.banner,
      FakeVisualVariant.variantA,
    );
    final newState =
        PresentumState$Immutable<FakeResolved, FakeSurface, FakeVisualVariant>(
          slots: {
            FakeSurface.banner: PresentumSlot(
              surface: FakeSurface.banner,
              active: item,
              queue: const [],
            ),
          },
          intention: PresentumStateIntention.auto,
        );

    final diff = PresentumStateDiff.compute(oldState, newState);

    expect(diff.isEmpty, isFalse);
    expect(diff.isNotEmpty, isTrue);
    expect(diff.variantsActivated, hasLength(1));
    expect(diff.variantsActivated.first, equals(item));
    expect(diff.variantsDeactivated, isEmpty);
    expect(diff.variantsQueued, isEmpty);
    expect(diff.variantsDequeued, isEmpty);
  });

  test('detects variant deactivation', () {
    final item = createFakeResolved(
      'c1',
      FakeSurface.banner,
      FakeVisualVariant.variantA,
    );
    final oldState =
        PresentumState$Immutable<FakeResolved, FakeSurface, FakeVisualVariant>(
          slots: {
            FakeSurface.banner: PresentumSlot(
              surface: FakeSurface.banner,
              active: item,
              queue: const [],
            ),
          },
          intention: PresentumStateIntention.auto,
        );

    final newState =
        PresentumState$Immutable<FakeResolved, FakeSurface, FakeVisualVariant>(
          slots: const {
            FakeSurface.banner: PresentumSlot.empty(FakeSurface.banner),
          },
          intention: PresentumStateIntention.auto,
        );

    final diff = PresentumStateDiff.compute(oldState, newState);

    expect(diff.variantsActivated, isEmpty);
    expect(diff.variantsDeactivated, hasLength(1));
    expect(diff.variantsDeactivated.first, equals(item));
  });

  test('detects variant queued', () {
    final active = createFakeResolved(
      'c1',
      FakeSurface.banner,
      FakeVisualVariant.variantA,
    );
    final queued = createFakeResolved(
      'c2',
      FakeSurface.banner,
      FakeVisualVariant.variantB,
    );

    final oldState =
        PresentumState$Immutable<FakeResolved, FakeSurface, FakeVisualVariant>(
          slots: {
            FakeSurface.banner: PresentumSlot(
              surface: FakeSurface.banner,
              active: active,
              queue: const [],
            ),
          },
          intention: PresentumStateIntention.auto,
        );

    final newState =
        PresentumState$Immutable<FakeResolved, FakeSurface, FakeVisualVariant>(
          slots: {
            FakeSurface.banner: PresentumSlot(
              surface: FakeSurface.banner,
              active: active,
              queue: [queued],
            ),
          },
          intention: PresentumStateIntention.auto,
        );

    final diff = PresentumStateDiff.compute(oldState, newState);

    expect(diff.variantsQueued, hasLength(1));
    expect(diff.variantsQueued.first, equals(queued));
    expect(diff.variantsActivated, isEmpty);
    expect(diff.variantsDeactivated, isEmpty);
  });

  test('detects variant dequeued', () {
    final active = createFakeResolved(
      'c1',
      FakeSurface.banner,
      FakeVisualVariant.variantA,
    );
    final queued = createFakeResolved(
      'c2',
      FakeSurface.banner,
      FakeVisualVariant.variantB,
    );

    final oldState =
        PresentumState$Immutable<FakeResolved, FakeSurface, FakeVisualVariant>(
          slots: {
            FakeSurface.banner: PresentumSlot(
              surface: FakeSurface.banner,
              active: active,
              queue: [queued],
            ),
          },
          intention: PresentumStateIntention.auto,
        );

    final newState =
        PresentumState$Immutable<FakeResolved, FakeSurface, FakeVisualVariant>(
          slots: {
            FakeSurface.banner: PresentumSlot(
              surface: FakeSurface.banner,
              active: active,
              queue: const [],
            ),
          },
          intention: PresentumStateIntention.auto,
        );

    final diff = PresentumStateDiff.compute(oldState, newState);

    expect(diff.variantsDequeued, hasLength(1));
    expect(diff.variantsDequeued.first, equals(queued));
  });

  test('detects no changes when states are identical', () {
    final state =
        PresentumState$Immutable<FakeResolved, FakeSurface, FakeVisualVariant>(
          slots: const {
            FakeSurface.banner: PresentumSlot.empty(FakeSurface.banner),
          },
          intention: PresentumStateIntention.auto,
        );

    final diff = PresentumStateDiff.compute(state, state);

    expect(diff.isEmpty, isTrue);
    expect(diff.isNotEmpty, isFalse);
    expect(diff.changes, isEmpty);
    expect(diff.variantsActivated, isEmpty);
    expect(diff.variantsDeactivated, isEmpty);
    expect(diff.variantsQueued, isEmpty);
    expect(diff.variantsDequeued, isEmpty);
  });

  test('detects active swap (deactivate + activate)', () {
    final item1 = createFakeResolved(
      'c1',
      FakeSurface.banner,
      FakeVisualVariant.variantA,
    );
    final item2 = createFakeResolved(
      'c2',
      FakeSurface.banner,
      FakeVisualVariant.variantB,
    );

    final oldState =
        PresentumState$Immutable<FakeResolved, FakeSurface, FakeVisualVariant>(
          slots: {
            FakeSurface.banner: PresentumSlot(
              surface: FakeSurface.banner,
              active: item1,
              queue: const [],
            ),
          },
          intention: PresentumStateIntention.auto,
        );

    final newState =
        PresentumState$Immutable<FakeResolved, FakeSurface, FakeVisualVariant>(
          slots: {
            FakeSurface.banner: PresentumSlot(
              surface: FakeSurface.banner,
              active: item2,
              queue: const [],
            ),
          },
          intention: PresentumStateIntention.auto,
        );

    final diff = PresentumStateDiff.compute(oldState, newState);

    expect(diff.variantsDeactivated, hasLength(1));
    expect(diff.variantsDeactivated.first, equals(item1));
    expect(diff.variantsActivated, hasLength(1));
    expect(diff.variantsActivated.first, equals(item2));
  });

  test('detects promotion from queue to active', () {
    final item1 = createFakeResolved(
      'c1',
      FakeSurface.banner,
      FakeVisualVariant.variantA,
    );
    final item2 = createFakeResolved(
      'c2',
      FakeSurface.banner,
      FakeVisualVariant.variantB,
    );

    final oldState =
        PresentumState$Immutable<FakeResolved, FakeSurface, FakeVisualVariant>(
          slots: {
            FakeSurface.banner: PresentumSlot(
              surface: FakeSurface.banner,
              active: item1,
              queue: [item2],
            ),
          },
          intention: PresentumStateIntention.auto,
        );

    final newState =
        PresentumState$Immutable<FakeResolved, FakeSurface, FakeVisualVariant>(
          slots: {
            FakeSurface.banner: PresentumSlot(
              surface: FakeSurface.banner,
              active: item2,
              queue: const [],
            ),
          },
          intention: PresentumStateIntention.auto,
        );

    final diff = PresentumStateDiff.compute(oldState, newState);

    expect(diff.variantsDeactivated, contains(item1));
    expect(diff.variantsActivated, contains(item2));
    expect(diff.variantsDequeued, contains(item2));
  });

  test('detects changes across multiple surfaces', () {
    final banner1 = createFakeResolved(
      'b1',
      FakeSurface.banner,
      FakeVisualVariant.variantA,
    );
    final modal1 = createFakeResolved(
      'm1',
      FakeSurface.modal,
      FakeVisualVariant.variantA,
    );

    final oldState =
        PresentumState$Immutable<FakeResolved, FakeSurface, FakeVisualVariant>(
          slots: const {
            FakeSurface.banner: PresentumSlot.empty(FakeSurface.banner),
            FakeSurface.modal: PresentumSlot.empty(FakeSurface.modal),
          },
          intention: PresentumStateIntention.auto,
        );

    final newState =
        PresentumState$Immutable<FakeResolved, FakeSurface, FakeVisualVariant>(
          slots: {
            FakeSurface.banner: PresentumSlot(
              surface: FakeSurface.banner,
              active: banner1,
              queue: const [],
            ),
            FakeSurface.modal: PresentumSlot(
              surface: FakeSurface.modal,
              active: modal1,
              queue: const [],
            ),
          },
          intention: PresentumStateIntention.auto,
        );

    final diff = PresentumStateDiff.compute(oldState, newState);

    expect(diff.variantsActivated, hasLength(2));
    expect(diff.variantsActivated, contains(banner1));
    expect(diff.variantsActivated, contains(modal1));
    expect(diff.slotDiffs, hasLength(2));
  });

  test('detects surface addition', () {
    final item = createFakeResolved(
      'c1',
      FakeSurface.banner,
      FakeVisualVariant.variantA,
    );

    final oldState =
        PresentumState$Immutable<FakeResolved, FakeSurface, FakeVisualVariant>(
          slots: const {},
          intention: PresentumStateIntention.auto,
        );

    final newState =
        PresentumState$Immutable<FakeResolved, FakeSurface, FakeVisualVariant>(
          slots: {
            FakeSurface.banner: PresentumSlot(
              surface: FakeSurface.banner,
              active: item,
              queue: const [],
            ),
          },
          intention: PresentumStateIntention.auto,
        );

    final diff = PresentumStateDiff.compute(oldState, newState);

    expect(diff.surfacesAdded, contains(FakeSurface.banner));
    expect(diff.surfacesRemoved, isEmpty);
    expect(diff.surfacesModified, isEmpty);
  });

  test('detects surface removal', () {
    final item = createFakeResolved(
      'c1',
      FakeSurface.banner,
      FakeVisualVariant.variantA,
    );
    final oldState =
        PresentumState$Immutable<FakeResolved, FakeSurface, FakeVisualVariant>(
          slots: {
            FakeSurface.banner: PresentumSlot(
              surface: FakeSurface.banner,
              active: item,
              queue: const [],
            ),
          },
          intention: PresentumStateIntention.auto,
        );

    final newState =
        PresentumState$Immutable<FakeResolved, FakeSurface, FakeVisualVariant>(
          slots: const {},
          intention: PresentumStateIntention.auto,
        );

    final diff = PresentumStateDiff.compute(oldState, newState);

    expect(diff.surfacesRemoved, contains(FakeSurface.banner));
    expect(diff.surfacesAdded, isEmpty);
    expect(diff.variantsDeactivated, contains(item));
  });

  test('detects surface modification', () {
    final item1 = createFakeResolved(
      'c1',
      FakeSurface.banner,
      FakeVisualVariant.variantA,
    );
    final item2 = createFakeResolved(
      'c2',
      FakeSurface.banner,
      FakeVisualVariant.variantB,
    );

    final oldState =
        PresentumState$Immutable<FakeResolved, FakeSurface, FakeVisualVariant>(
          slots: {
            FakeSurface.banner: PresentumSlot(
              surface: FakeSurface.banner,
              active: item1,
              queue: const [],
            ),
          },
          intention: PresentumStateIntention.auto,
        );

    final newState =
        PresentumState$Immutable<FakeResolved, FakeSurface, FakeVisualVariant>(
          slots: {
            FakeSurface.banner: PresentumSlot(
              surface: FakeSurface.banner,
              active: item2,
              queue: const [],
            ),
          },
          intention: PresentumStateIntention.auto,
        );

    final diff = PresentumStateDiff.compute(oldState, newState);

    expect(diff.surfacesModified, contains(FakeSurface.banner));
    expect(diff.surfacesAdded, isEmpty);
    expect(diff.surfacesRemoved, isEmpty);
  });

  group('SlotDiff', () {
    test('computes empty diff for identical slots', () {
      const slot =
          PresentumSlot<FakeResolved, FakeSurface, FakeVisualVariant>.empty(
            FakeSurface.banner,
          );

      final diff = SlotDiff.compute(
        surface: FakeSurface.banner,
        oldSlot: slot,
        newSlot: slot,
      );

      expect(diff.isEmpty, isTrue);
      expect(diff.activeChanged, isFalse);
      expect(diff.queueChanged, isFalse);
      expect(diff.changes, isEmpty);
    });

    test('detects active change', () {
      final item1 = createFakeResolved(
        'c1',
        FakeSurface.banner,
        FakeVisualVariant.variantA,
      );
      final item2 = createFakeResolved(
        'c2',
        FakeSurface.banner,
        FakeVisualVariant.variantB,
      );

      final oldSlot = PresentumSlot(
        surface: FakeSurface.banner,
        active: item1,
        queue: const <FakeResolved>[],
      );

      final newSlot = PresentumSlot(
        surface: FakeSurface.banner,
        active: item2,
        queue: const <FakeResolved>[],
      );

      final diff = SlotDiff.compute(
        surface: FakeSurface.banner,
        oldSlot: oldSlot,
        newSlot: newSlot,
      );

      expect(diff.activeChanged, isTrue);
      expect(diff.queueChanged, isFalse);
      expect(diff.changes, hasLength(2)); // deactivate + activate
    });

    test('detects queue change', () {
      final active = createFakeResolved(
        'c1',
        FakeSurface.banner,
        FakeVisualVariant.variantA,
      );
      final queued = createFakeResolved(
        'c2',
        FakeSurface.banner,
        FakeVisualVariant.variantB,
      );

      final oldSlot = PresentumSlot(
        surface: FakeSurface.banner,
        active: active,
        queue: const <FakeResolved>[],
      );

      final newSlot = PresentumSlot(
        surface: FakeSurface.banner,
        active: active,
        queue: <FakeResolved>[queued],
      );

      final diff = SlotDiff.compute(
        surface: FakeSurface.banner,
        oldSlot: oldSlot,
        newSlot: newSlot,
      );

      expect(diff.activeChanged, isFalse);
      expect(diff.queueChanged, isTrue);
      expect(diff.changes, hasLength(1));
    });

    test('handles null old slot (slot creation)', () {
      final item = createFakeResolved(
        'c1',
        FakeSurface.banner,
        FakeVisualVariant.variantA,
      );
      final queued = createFakeResolved(
        'c2',
        FakeSurface.banner,
        FakeVisualVariant.variantB,
      );

      final newSlot = PresentumSlot(
        surface: FakeSurface.banner,
        active: item,
        queue: [queued],
      );

      final diff = SlotDiff.compute(
        surface: FakeSurface.banner,
        oldSlot: null,
        newSlot: newSlot,
      );

      expect(diff.changes, hasLength(2)); // 1 activation + 1 queued
      expect(diff.changes.whereType<VariantActivatedChange>(), hasLength(1));
      expect(diff.changes.whereType<VariantQueuedChange>(), hasLength(1));
    });

    test('handles null new slot (slot deletion)', () {
      final item = createFakeResolved(
        'c1',
        FakeSurface.banner,
        FakeVisualVariant.variantA,
      );
      final queued = createFakeResolved(
        'c2',
        FakeSurface.banner,
        FakeVisualVariant.variantB,
      );

      final oldSlot = PresentumSlot(
        surface: FakeSurface.banner,
        active: item,
        queue: [queued],
      );

      final diff = SlotDiff.compute(
        surface: FakeSurface.banner,
        oldSlot: oldSlot,
        newSlot: null,
      );

      expect(diff.changes, hasLength(2)); // 1 deactivation + 1 dequeued
      expect(diff.changes.whereType<VariantDeactivatedChange>(), hasLength(1));
      expect(diff.changes.whereType<VariantDequeuedChange>(), hasLength(1));
    });

    test('handles both null slots', () {
      final diff =
          SlotDiff<FakeResolved, FakeSurface, FakeVisualVariant>.compute(
            surface: FakeSurface.banner,
            oldSlot: null,
            newSlot: null,
          );

      expect(diff.isEmpty, isTrue);
      expect(diff.changes, isEmpty);
    });
  });

  group('SlotChange Types', () {
    test('VariantActivatedChange contains correct data', () {
      final item = createFakeResolved(
        'c1',
        FakeSurface.banner,
        FakeVisualVariant.variantA,
      );
      final previous = createFakeResolved(
        'c0',
        FakeSurface.banner,
        FakeVisualVariant.variantA,
      );

      final change =
          VariantActivatedChange<FakeResolved, FakeSurface, FakeVisualVariant>(
            surface: FakeSurface.banner,
            item: item,
            previousActive: previous,
          );

      expect(change.surface, equals(FakeSurface.banner));
      expect(change.item, equals(item));
      expect(change.previousActive, equals(previous));
      expect(change.toString(), contains('SlotChange'));
    });

    test('VariantDeactivatedChange contains correct data', () {
      final item = createFakeResolved(
        'c1',
        FakeSurface.banner,
        FakeVisualVariant.variantA,
      );
      final next = createFakeResolved(
        'c2',
        FakeSurface.banner,
        FakeVisualVariant.variantB,
      );

      final change =
          VariantDeactivatedChange<
            FakeResolved,
            FakeSurface,
            FakeVisualVariant
          >(surface: FakeSurface.banner, item: item, newActive: next);

      expect(change.surface, equals(FakeSurface.banner));
      expect(change.item, equals(item));
      expect(change.newActive, equals(next));
    });

    test('VariantQueuedChange equality works', () {
      final item = createFakeResolved(
        'c1',
        FakeSurface.banner,
        FakeVisualVariant.variantA,
      );

      final c1 =
          VariantQueuedChange<FakeResolved, FakeSurface, FakeVisualVariant>(
            surface: FakeSurface.banner,
            item: item,
          );
      final c2 =
          VariantQueuedChange<FakeResolved, FakeSurface, FakeVisualVariant>(
            surface: FakeSurface.banner,
            item: item,
          );

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
    });

    test('VariantDequeuedChange equality works', () {
      final item = createFakeResolved(
        'c1',
        FakeSurface.banner,
        FakeVisualVariant.variantA,
      );

      final c1 =
          VariantDequeuedChange<FakeResolved, FakeSurface, FakeVisualVariant>(
            surface: FakeSurface.banner,
            item: item,
          );
      final c2 =
          VariantDequeuedChange<FakeResolved, FakeSurface, FakeVisualVariant>(
            surface: FakeSurface.banner,
            item: item,
          );

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
    });
  });

  group('PresentumStateDiff - Edge Cases', () {
    test('handles multiple items in queue', () {
      final active = createFakeResolved(
        'c1',
        FakeSurface.banner,
        FakeVisualVariant.variantA,
      );
      final q1 = createFakeResolved(
        'q1',
        FakeSurface.banner,
        FakeVisualVariant.variantB,
      );
      final q2 = createFakeResolved(
        'q2',
        FakeSurface.banner,
        FakeVisualVariant.variantA,
      );
      final q3 = createFakeResolved(
        'q3',
        FakeSurface.banner,
        FakeVisualVariant.variantB,
      );

      final oldState =
          PresentumState$Immutable<
            FakeResolved,
            FakeSurface,
            FakeVisualVariant
          >(
            slots: {
              FakeSurface.banner: PresentumSlot(
                surface: FakeSurface.banner,
                active: active,
                queue: [q1],
              ),
            },
            intention: PresentumStateIntention.auto,
          );

      final newState =
          PresentumState$Immutable<
            FakeResolved,
            FakeSurface,
            FakeVisualVariant
          >(
            slots: {
              FakeSurface.banner: PresentumSlot(
                surface: FakeSurface.banner,
                active: active,
                queue: [q2, q3],
              ),
            },
            intention: PresentumStateIntention.auto,
          );

      final diff = PresentumStateDiff.compute(oldState, newState);

      expect(diff.variantsDequeued, contains(q1));
      expect(diff.variantsQueued, contains(q2));
      expect(diff.variantsQueued, contains(q3));
    });

    test('diffForSurface returns correct slot diff', () {
      final item = createFakeResolved(
        'c1',
        FakeSurface.banner,
        FakeVisualVariant.variantA,
      );

      final oldState =
          PresentumState$Immutable<
            FakeResolved,
            FakeSurface,
            FakeVisualVariant
          >(
            slots: const {
              FakeSurface.banner: PresentumSlot.empty(FakeSurface.banner),
            },
            intention: PresentumStateIntention.auto,
          );

      final newState =
          PresentumState$Immutable<
            FakeResolved,
            FakeSurface,
            FakeVisualVariant
          >(
            slots: {
              FakeSurface.banner: PresentumSlot(
                surface: FakeSurface.banner,
                active: item,
                queue: const [],
              ),
            },
            intention: PresentumStateIntention.auto,
          );

      final diff = PresentumStateDiff.compute(oldState, newState);
      final slotDiff = diff.diffForSurface(FakeSurface.banner);

      expect(slotDiff, isNotNull);
      expect(slotDiff!.surface, equals(FakeSurface.banner));
      expect(slotDiff.activeChanged, isTrue);

      // Non-existent surface returns null
      expect(diff.diffForSurface(FakeSurface.modal), isNull);
    });
  });
}
