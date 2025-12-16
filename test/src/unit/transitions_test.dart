import 'package:flutter_test/flutter_test.dart';
import 'package:presentum/presentum.dart';

import 'fake_payload.dart';

void main() {
  group('PresentumStateTransition', () {
    test('creates transition with correct properties', () {
      final oldState =
          PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
            slots: const {},
            intention: PresentumStateIntention.auto,
          );

      final newState =
          PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
            slots: {
              FakeSurface.banner: PresentumSlot(
                surface: FakeSurface.banner,
                active: createFakeItem(
                  'c1',
                  FakeSurface.banner,
                  FakeVariant.variantA,
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
          PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
            slots: const {},
            intention: PresentumStateIntention.auto,
          );
      final newState =
          PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
            slots: const {},
            intention: PresentumStateIntention.replace,
          );
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
        PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
          slots: const {
            FakeSurface.banner: PresentumSlot.empty(FakeSurface.banner),
          },
          intention: PresentumStateIntention.auto,
        );

    final item = createFakeItem('c1', FakeSurface.banner, FakeVariant.variantA);
    final newState =
        PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
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
    expect(diff.itemsActivated, hasLength(1));
    expect(diff.itemsActivated.first, equals(item));
    expect(diff.itemsDeactivated, isEmpty);
    expect(diff.itemsQueued, isEmpty);
    expect(diff.itemsDequeued, isEmpty);
  });

  test('detects variant deactivation', () {
    final item = createFakeItem('c1', FakeSurface.banner, FakeVariant.variantA);
    final oldState =
        PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
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
        PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
          slots: const {
            FakeSurface.banner: PresentumSlot.empty(FakeSurface.banner),
          },
          intention: PresentumStateIntention.auto,
        );

    final diff = PresentumStateDiff.compute(oldState, newState);

    expect(diff.itemsActivated, isEmpty);
    expect(diff.itemsDeactivated, hasLength(1));
    expect(diff.itemsDeactivated.first, equals(item));
  });

  test('detects variant queued', () {
    final active = createFakeItem(
      'c1',
      FakeSurface.banner,
      FakeVariant.variantA,
    );
    final queued = createFakeItem(
      'c2',
      FakeSurface.banner,
      FakeVariant.variantB,
    );

    final oldState =
        PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
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
        PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
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

    expect(diff.itemsQueued, hasLength(1));
    expect(diff.itemsQueued.first, equals(queued));
    expect(diff.itemsActivated, isEmpty);
    expect(diff.itemsDeactivated, isEmpty);
  });

  test('detects variant dequeued', () {
    final active = createFakeItem(
      'c1',
      FakeSurface.banner,
      FakeVariant.variantA,
    );
    final queued = createFakeItem(
      'c2',
      FakeSurface.banner,
      FakeVariant.variantB,
    );

    final oldState =
        PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
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
        PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
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

    expect(diff.itemsDequeued, hasLength(1));
    expect(diff.itemsDequeued.first, equals(queued));
  });

  test('detects no changes when states are identical', () {
    final state = PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
      slots: const {
        FakeSurface.banner: PresentumSlot.empty(FakeSurface.banner),
      },
      intention: PresentumStateIntention.auto,
    );

    final diff = PresentumStateDiff.compute(state, state);

    expect(diff.isEmpty, isTrue);
    expect(diff.isNotEmpty, isFalse);
    expect(diff.changes, isEmpty);
    expect(diff.itemsActivated, isEmpty);
    expect(diff.itemsDeactivated, isEmpty);
    expect(diff.itemsQueued, isEmpty);
    expect(diff.itemsDequeued, isEmpty);
  });

  test('detects active swap (deactivate + activate)', () {
    final item1 = createFakeItem(
      'c1',
      FakeSurface.banner,
      FakeVariant.variantA,
    );
    final item2 = createFakeItem(
      'c2',
      FakeSurface.banner,
      FakeVariant.variantB,
    );

    final oldState =
        PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
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
        PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
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

    expect(diff.itemsDeactivated, hasLength(1));
    expect(diff.itemsDeactivated.first, equals(item1));
    expect(diff.itemsActivated, hasLength(1));
    expect(diff.itemsActivated.first, equals(item2));
  });

  test('detects promotion from queue to active', () {
    final item1 = createFakeItem(
      'c1',
      FakeSurface.banner,
      FakeVariant.variantA,
    );
    final item2 = createFakeItem(
      'c2',
      FakeSurface.banner,
      FakeVariant.variantB,
    );

    final oldState =
        PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
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
        PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
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

    expect(diff.itemsDeactivated, contains(item1));
    expect(diff.itemsActivated, contains(item2));
    expect(diff.itemsDequeued, contains(item2));
  });

  test('detects changes across multiple surfaces', () {
    final banner1 = createFakeItem(
      'b1',
      FakeSurface.banner,
      FakeVariant.variantA,
    );
    final modal1 = createFakeItem(
      'm1',
      FakeSurface.modal,
      FakeVariant.variantA,
    );

    final oldState =
        PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
          slots: const {
            FakeSurface.banner: PresentumSlot.empty(FakeSurface.banner),
            FakeSurface.modal: PresentumSlot.empty(FakeSurface.modal),
          },
          intention: PresentumStateIntention.auto,
        );

    final newState =
        PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
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

    expect(diff.itemsActivated, hasLength(2));
    expect(diff.itemsActivated, contains(banner1));
    expect(diff.itemsActivated, contains(modal1));
    expect(diff.slotDiffs, hasLength(2));
  });

  test('detects surface addition', () {
    final item = createFakeItem('c1', FakeSurface.banner, FakeVariant.variantA);

    final oldState =
        PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
          slots: const {},
          intention: PresentumStateIntention.auto,
        );

    final newState =
        PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
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
    final item = createFakeItem('c1', FakeSurface.banner, FakeVariant.variantA);
    final oldState =
        PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
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
        PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
          slots: const {},
          intention: PresentumStateIntention.auto,
        );

    final diff = PresentumStateDiff.compute(oldState, newState);

    expect(diff.surfacesRemoved, contains(FakeSurface.banner));
    expect(diff.surfacesAdded, isEmpty);
    expect(diff.itemsDeactivated, contains(item));
  });

  test('detects surface modification', () {
    final item1 = createFakeItem(
      'c1',
      FakeSurface.banner,
      FakeVariant.variantA,
    );
    final item2 = createFakeItem(
      'c2',
      FakeSurface.banner,
      FakeVariant.variantB,
    );

    final oldState =
        PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
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
        PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
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
      const slot = PresentumSlot<FakeItem, FakeSurface, FakeVariant>.empty(
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
      final item1 = createFakeItem(
        'c1',
        FakeSurface.banner,
        FakeVariant.variantA,
      );
      final item2 = createFakeItem(
        'c2',
        FakeSurface.banner,
        FakeVariant.variantB,
      );

      final oldSlot = PresentumSlot(
        surface: FakeSurface.banner,
        active: item1,
        queue: const <FakeItem>[],
      );

      final newSlot = PresentumSlot(
        surface: FakeSurface.banner,
        active: item2,
        queue: const <FakeItem>[],
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
      final active = createFakeItem(
        'c1',
        FakeSurface.banner,
        FakeVariant.variantA,
      );
      final queued = createFakeItem(
        'c2',
        FakeSurface.banner,
        FakeVariant.variantB,
      );

      final oldSlot = PresentumSlot(
        surface: FakeSurface.banner,
        active: active,
        queue: const <FakeItem>[],
      );

      final newSlot = PresentumSlot(
        surface: FakeSurface.banner,
        active: active,
        queue: <FakeItem>[queued],
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
      final item = createFakeItem(
        'c1',
        FakeSurface.banner,
        FakeVariant.variantA,
      );
      final queued = createFakeItem(
        'c2',
        FakeSurface.banner,
        FakeVariant.variantB,
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
      expect(diff.changes.whereType<ItemActivatedChange>(), hasLength(1));
      expect(diff.changes.whereType<ItemQueuedChange>(), hasLength(1));
    });

    test('handles null new slot (slot deletion)', () {
      final item = createFakeItem(
        'c1',
        FakeSurface.banner,
        FakeVariant.variantA,
      );
      final queued = createFakeItem(
        'c2',
        FakeSurface.banner,
        FakeVariant.variantB,
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
      expect(diff.changes.whereType<ItemDeactivatedChange>(), hasLength(1));
      expect(diff.changes.whereType<ItemDequeuedChange>(), hasLength(1));
    });

    test('handles both null slots', () {
      final diff = SlotDiff<FakeItem, FakeSurface, FakeVariant>.compute(
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
      final item = createFakeItem(
        'c1',
        FakeSurface.banner,
        FakeVariant.variantA,
      );
      final previous = createFakeItem(
        'c0',
        FakeSurface.banner,
        FakeVariant.variantA,
      );

      final change = ItemActivatedChange<FakeItem, FakeSurface, FakeVariant>(
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
      final item = createFakeItem(
        'c1',
        FakeSurface.banner,
        FakeVariant.variantA,
      );
      final next = createFakeItem(
        'c2',
        FakeSurface.banner,
        FakeVariant.variantB,
      );

      final change = ItemDeactivatedChange<FakeItem, FakeSurface, FakeVariant>(
        surface: FakeSurface.banner,
        item: item,
        newActive: next,
      );

      expect(change.surface, equals(FakeSurface.banner));
      expect(change.item, equals(item));
      expect(change.newActive, equals(next));
    });

    test('VariantQueuedChange equality works', () {
      final item = createFakeItem(
        'c1',
        FakeSurface.banner,
        FakeVariant.variantA,
      );

      final c1 = ItemQueuedChange<FakeItem, FakeSurface, FakeVariant>(
        surface: FakeSurface.banner,
        item: item,
      );
      final c2 = ItemQueuedChange<FakeItem, FakeSurface, FakeVariant>(
        surface: FakeSurface.banner,
        item: item,
      );

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
    });

    test('VariantDequeuedChange equality works', () {
      final item = createFakeItem(
        'c1',
        FakeSurface.banner,
        FakeVariant.variantA,
      );

      final c1 = ItemDequeuedChange<FakeItem, FakeSurface, FakeVariant>(
        surface: FakeSurface.banner,
        item: item,
      );
      final c2 = ItemDequeuedChange<FakeItem, FakeSurface, FakeVariant>(
        surface: FakeSurface.banner,
        item: item,
      );

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
    });
  });

  group('PresentumStateDiff - Edge Cases', () {
    test('handles multiple items in queue', () {
      final active = createFakeItem(
        'c1',
        FakeSurface.banner,
        FakeVariant.variantA,
      );
      final q1 = createFakeItem('q1', FakeSurface.banner, FakeVariant.variantB);
      final q2 = createFakeItem('q2', FakeSurface.banner, FakeVariant.variantA);
      final q3 = createFakeItem('q3', FakeSurface.banner, FakeVariant.variantB);

      final oldState =
          PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
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
          PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
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

      expect(diff.itemsDequeued, contains(q1));
      expect(diff.itemsQueued, contains(q2));
      expect(diff.itemsQueued, contains(q3));
    });

    test('diffForSurface returns correct slot diff', () {
      final item = createFakeItem(
        'c1',
        FakeSurface.banner,
        FakeVariant.variantA,
      );

      final oldState =
          PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
            slots: const {
              FakeSurface.banner: PresentumSlot.empty(FakeSurface.banner),
            },
            intention: PresentumStateIntention.auto,
          );

      final newState =
          PresentumState$Immutable<FakeItem, FakeSurface, FakeVariant>(
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
