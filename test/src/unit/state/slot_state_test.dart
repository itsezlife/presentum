import 'package:flutter_test/flutter_test.dart';
import 'package:presentum/src/state/slot_state.dart';

import '../fake_payload.dart';

void main() {
  group('PresentumSlotState', () {
    FakeItem item(String id, FakeSurface surface) =>
        createFakeItem(id, surface, FakeVariant.variantA);

    test('empty has no slots', () {
      const state =
          PresentumSlotState<FakeItem, FakeSurface, FakeVariant>.empty();

      expect(state.slotFor(FakeSurface.banner), isNull);
      expect(state.activeFor(FakeSurface.banner), isNull);
      expect(state.queueFor(FakeSurface.banner), isEmpty);
      expect(state.hasActive(FakeSurface.banner), isFalse);
      expect(state.activeSurfaces, isEmpty);
      expect(state.activeItems, isEmpty);
    });

    group('withActive', () {
      test('sets active and clears queue', () {
        final a = item('a', FakeSurface.banner);
        final b = item('b', FakeSurface.banner);
        final initial =
            const PresentumSlotState<FakeItem, FakeSurface, FakeVariant>.empty()
                .withEnqueued(FakeSurface.banner, a)
                .withEnqueued(FakeSurface.banner, b);

        expect(initial.queueFor(FakeSurface.banner), [b]);

        final next = initial.withActive(FakeSurface.banner, a);

        expect(next.activeFor(FakeSurface.banner), a);
        expect(next.queueFor(FakeSurface.banner), isEmpty);
      });
    });

    group('withEnqueued', () {
      test('sets active when surface is empty', () {
        final a = item('a', FakeSurface.banner);
        final next =
            const PresentumSlotState<FakeItem, FakeSurface, FakeVariant>.empty()
                .withEnqueued(FakeSurface.banner, a);

        expect(next.activeFor(FakeSurface.banner), a);
        expect(next.queueFor(FakeSurface.banner), isEmpty);
      });

      test('appends to queue when active exists', () {
        final a = item('a', FakeSurface.banner);
        final b = item('b', FakeSurface.banner);
        final next =
            const PresentumSlotState<FakeItem, FakeSurface, FakeVariant>.empty()
                .withActive(FakeSurface.banner, a)
                .withEnqueued(FakeSurface.banner, b);

        expect(next.activeFor(FakeSurface.banner), a);
        expect(next.queueFor(FakeSurface.banner), [b]);
      });
    });

    group('withDismissed', () {
      test('clears active when queue is empty', () {
        final a = item('a', FakeSurface.banner);
        final initial =
            const PresentumSlotState<FakeItem, FakeSurface, FakeVariant>.empty()
                .withActive(FakeSurface.banner, a);

        final next = initial.withDismissed(FakeSurface.banner);

        expect(next.activeFor(FakeSurface.banner), isNull);
        expect(next.slotFor(FakeSurface.banner), isNotNull);
      });

      test('promotes queue head when queue is non-empty', () {
        final a = item('a', FakeSurface.banner);
        final b = item('b', FakeSurface.banner);
        final c = item('c', FakeSurface.banner);
        final initial =
            const PresentumSlotState<FakeItem, FakeSurface, FakeVariant>.empty()
                .withActive(FakeSurface.banner, a)
                .withEnqueued(FakeSurface.banner, b)
                .withEnqueued(FakeSurface.banner, c);

        final next = initial.withDismissed(FakeSurface.banner);

        expect(next.activeFor(FakeSurface.banner), b);
        expect(next.queueFor(FakeSurface.banner), [c]);
      });

      test('no-op when surface is missing', () {
        const state =
            PresentumSlotState<FakeItem, FakeSurface, FakeVariant>.empty();
        expect(
          identical(state, state.withDismissed(FakeSurface.banner)),
          isTrue,
        );
      });
    });

    group('withCleared vs withClearedSlot', () {
      test('withCleared removes map key', () {
        final a = item('a', FakeSurface.banner);
        final initial =
            const PresentumSlotState<FakeItem, FakeSurface, FakeVariant>.empty()
                .withActive(FakeSurface.banner, a);

        final next = initial.withCleared(FakeSurface.banner);

        expect(next.slotFor(FakeSurface.banner), isNull);
      });

      test('withClearedSlot keeps empty slot entry', () {
        final a = item('a', FakeSurface.banner);
        final initial =
            const PresentumSlotState<FakeItem, FakeSurface, FakeVariant>.empty()
                .withActive(FakeSurface.banner, a);

        final next = initial.withClearedSlot(FakeSurface.banner);

        expect(next.slotFor(FakeSurface.banner), isNotNull);
        expect(next.activeFor(FakeSurface.banner), isNull);
        expect(next.queueFor(FakeSurface.banner), isEmpty);
      });
    });

    group('withReorderedQueue', () {
      test('replaces queue without changing active', () {
        final a = item('a', FakeSurface.banner);
        final b = item('b', FakeSurface.banner);
        final c = item('c', FakeSurface.banner);
        final initial =
            const PresentumSlotState<FakeItem, FakeSurface, FakeVariant>.empty()
                .withActive(FakeSurface.banner, a)
                .withEnqueued(FakeSurface.banner, b);

        final next = initial.withReorderedQueue(FakeSurface.banner, [c, b]);

        expect(next.activeFor(FakeSurface.banner), a);
        expect(next.queueFor(FakeSurface.banner), [c, b]);
      });
    });

    group('mergeFrom', () {
      test('copies listed surfaces only', () {
        final banner = item('banner', FakeSurface.banner);
        final modal = item('modal', FakeSurface.modal);
        final left =
            const PresentumSlotState<FakeItem, FakeSurface, FakeVariant>.empty()
                .withActive(FakeSurface.banner, banner);
        final right =
            const PresentumSlotState<FakeItem, FakeSurface, FakeVariant>.empty()
                .withActive(FakeSurface.modal, modal);

        final merged = left.mergeFrom(right, surfaces: {FakeSurface.modal});

        expect(merged.activeFor(FakeSurface.banner), banner);
        expect(merged.activeFor(FakeSurface.modal), modal);
      });

      test('removes surface when absent in other', () {
        final banner = item('banner', FakeSurface.banner);
        final left =
            const PresentumSlotState<FakeItem, FakeSurface, FakeVariant>.empty()
                .withActive(FakeSurface.banner, banner);
        const right =
            PresentumSlotState<FakeItem, FakeSurface, FakeVariant>.empty();

        final merged = left.mergeFrom(right, surfaces: {FakeSurface.banner});

        expect(merged.slotFor(FakeSurface.banner), isNull);
      });
    });

    group('read accessors', () {
      test('activeSurfaces and activeItems', () {
        final banner = item('banner', FakeSurface.banner);
        final modal = item('modal', FakeSurface.modal);
        final state =
            const PresentumSlotState<FakeItem, FakeSurface, FakeVariant>.empty()
                .withActive(FakeSurface.banner, banner)
                .withActive(FakeSurface.modal, modal);

        expect(state.activeSurfaces.toSet(), {
          FakeSurface.banner,
          FakeSurface.modal,
        });
        expect(state.activeItems.length, 2);
      });

      test('queueFor returns unmodifiable empty list', () {
        const state =
            PresentumSlotState<FakeItem, FakeSurface, FakeVariant>.empty();
        expect(
          () => state
              .queueFor(FakeSurface.banner)
              .add(item('x', FakeSurface.banner)),
          throwsUnsupportedError,
        );
      });
    });

    group('equality', () {
      test('equal slot maps compare equal', () {
        final a = item('a', FakeSurface.banner);
        final left =
            const PresentumSlotState<FakeItem, FakeSurface, FakeVariant>.empty()
                .withActive(FakeSurface.banner, a);
        final right =
            const PresentumSlotState<FakeItem, FakeSurface, FakeVariant>.empty()
                .withActive(FakeSurface.banner, a);

        expect(left, equals(right));
        expect(left.hashCode, equals(right.hashCode));
      });

      test('different actives compare unequal', () {
        final left =
            const PresentumSlotState<FakeItem, FakeSurface, FakeVariant>.empty()
                .withActive(FakeSurface.banner, item('a', FakeSurface.banner));
        final right =
            const PresentumSlotState<FakeItem, FakeSurface, FakeVariant>.empty()
                .withActive(FakeSurface.banner, item('b', FakeSurface.banner));

        expect(left == right, isFalse);
      });
    });
  });
}
