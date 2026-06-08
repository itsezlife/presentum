import 'package:flutter_test/flutter_test.dart';
import 'package:presentum/src/state/slot_state.dart';
import 'package:presentum/src/state/slots_history.dart';

import '../fake_payload.dart';

void main() {
  group('PresentumSlotsHistory', () {
    FakeItem item(String id, FakeSurface surface) =>
        createFakeItem(id, surface, FakeVariant.variantA);

    const empty =
        PresentumSlotState<FakeItem, FakeSurface, FakeVariant>.empty();
    const history = PresentumSlotsHistory<FakeItem, FakeSurface, FakeVariant>();

    test('append intention adds entry', () {
      final slots = empty.withActive(
        FakeSurface.banner,
        item('a', FakeSurface.banner),
      );
      final next = history.record(
        slots: slots,
        intention: PresentumSlotsStateIntention.append,
        timestamp: DateTime(2025, 1, 1),
      );

      expect(next.entries, hasLength(1));
      expect(next.entries.single.slots, slots);
      expect(identical(history, next), isFalse);
    });

    test('auto intention appends like engine', () {
      final first = empty.withActive(
        FakeSurface.banner,
        item('a', FakeSurface.banner),
      );
      final h1 = history.record(slots: first, timestamp: DateTime(2025, 1, 1));
      final second = first.withActive(
        FakeSurface.modal,
        item('b', FakeSurface.modal),
      );
      final h2 = h1.record(
        slots: second,
        intention: PresentumSlotsStateIntention.auto,
        timestamp: DateTime(2025, 1, 2),
      );

      expect(h2.entries, hasLength(2));
      expect(h2.entries.last.slots, second);
    });

    test('replace updates last entry when history is non-empty', () {
      final first = empty.withActive(
        FakeSurface.banner,
        item('a', FakeSurface.banner),
      );
      final h1 = history.record(slots: first, timestamp: DateTime(2025, 1, 1));
      final replaced = first.withActive(
        FakeSurface.banner,
        item('b', FakeSurface.banner),
      );
      final h2 = h1.record(
        slots: replaced,
        intention: PresentumSlotsStateIntention.replace,
        timestamp: DateTime(2025, 1, 2),
      );

      expect(h2.entries, hasLength(1));
      expect(h2.entries.single.slots, replaced);
      expect(h2.entries.single.timestamp, DateTime(2025, 1, 2));
    });

    test('replace appends when history is empty', () {
      final slots = empty.withActive(
        FakeSurface.banner,
        item('a', FakeSurface.banner),
      );
      final next = history.record(
        slots: slots,
        intention: PresentumSlotsStateIntention.replace,
        timestamp: DateTime(2025, 1, 1),
      );

      expect(next.entries, hasLength(1));
      expect(next.entries.single.slots, slots);
    });

    test('cancel returns same instance', () {
      final slots = empty.withActive(
        FakeSurface.banner,
        item('a', FakeSurface.banner),
      );
      final h1 = history.record(slots: slots);
      final h2 = h1.record(
        slots: empty.withActive(
          FakeSurface.modal,
          item('x', FakeSurface.modal),
        ),
        intention: PresentumSlotsStateIntention.cancel,
      );

      expect(identical(h1, h2), isTrue);
      expect(h2.entries, hasLength(1));
    });

    test('empty and empty slot maps is no-op', () {
      final next = history.record(slots: empty);

      expect(identical(history, next), isTrue);
      expect(next.entries, isEmpty);
    });

    test('unchanged slots is no-op', () {
      final slots = empty.withActive(
        FakeSurface.banner,
        item('a', FakeSurface.banner),
      );
      final h1 = history.record(slots: slots);
      final h2 = h1.record(slots: slots);

      expect(identical(h1, h2), isTrue);
    });

    test('maxLength evicts oldest entry', () {
      var h = const PresentumSlotsHistory<FakeItem, FakeSurface, FakeVariant>();
      final base = DateTime(2025, 1, 1);

      for (var i = 0; i < PresentumSlotsHistory.maxLength + 3; i++) {
        final slots = empty.withActive(
          FakeSurface.banner,
          item('item-$i', FakeSurface.banner),
        );
        h = h.record(
          slots: slots,
          timestamp: base.add(Duration(minutes: i)),
        );
      }

      expect(h.entries, hasLength(PresentumSlotsHistory.maxLength));
      expect(
        h.entries.first.slots.activeFor(FakeSurface.banner)?.payload.id,
        'item-3',
      );
      expect(
        h.entries.last.slots.activeFor(FakeSurface.banner)?.payload.id,
        'item-${PresentumSlotsHistory.maxLength + 2}',
      );
    });

    test('current overrides last entry for equality check', () {
      final slots = empty.withActive(
        FakeSurface.banner,
        item('a', FakeSurface.banner),
      );
      final h1 = history.record(slots: slots);
      final h2 = h1.record(
        slots: slots,
        current: empty.withActive(
          FakeSurface.modal,
          item('other', FakeSurface.modal),
        ),
      );

      expect(identical(h1, h2), isFalse);
      expect(h2.entries, hasLength(2));
    });

    test('PresentumSlotsHistoryEntry orders by timestamp', () {
      final slots = empty.withActive(
        FakeSurface.banner,
        item('a', FakeSurface.banner),
      );
      final early = PresentumSlotsHistoryEntry(
        slots: slots,
        timestamp: DateTime(2025, 1, 1),
      );
      final late = PresentumSlotsHistoryEntry(
        slots: slots,
        timestamp: DateTime(2025, 6, 1),
      );

      expect(early.compareTo(late), lessThan(0));
    });
  });
}
