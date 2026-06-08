import 'package:flutter_test/flutter_test.dart';
import 'package:presentum/src/events/analytics.dart';
import 'package:presentum/src/events/events.dart';
import 'package:presentum/src/events/lifecycle.dart';
import 'package:presentum/src/state/slot_state.dart';
import 'package:presentum/src/storage/storage.dart';

import '../fake_payload.dart';

typedef _SlotState = PresentumSlotState<FakeItem, FakeSurface, FakeVariant>;

final class _RecordingAnalytics
    extends PresentumAnalytics<FakeItem, FakeSurface, FakeVariant> {
  const _RecordingAnalytics(this.sink);

  final List<String> sink;

  @override
  void onShown(PresentumShownEvent<FakeItem, FakeSurface, FakeVariant> event) =>
      sink.add('shown:${event.item.payload.id}');

  @override
  void onDismissed(
    PresentumDismissedEvent<FakeItem, FakeSurface, FakeVariant> event,
  ) => sink.add('dismissed:${event.item.payload.id}');

  @override
  void onConverted(
    PresentumConvertedEvent<FakeItem, FakeSurface, FakeVariant> event,
  ) => sink.add('converted:${event.item.payload.id}');
}

void main() {
  group('PresentumLifecycle', () {
    late InMemoryPresentumStorage<FakeSurface, FakeVariant> storage;
    final fixedAt = DateTime.utc(2026, 3, 1, 12);

    FakeItem item(String id, FakeSurface surface) =>
        createFakeItem(id, surface, FakeVariant.variantA);

    setUp(() => storage = InMemoryPresentumStorage());

    test('shown records storage without changing slots', () async {
      final banner = item('banner', FakeSurface.banner);
      final slots = const _SlotState.empty().withActive(
        FakeSurface.banner,
        banner,
      );
      final analyticsEvents = <String>[];
      final analytics = _RecordingAnalytics(analyticsEvents);

      await PresentumLifecycle.shown(
        item: banner,
        storage: storage,
        at: fixedAt,
        handlers: [PresentumAnalyticsEventHandler(analytics: analytics)],
      );

      expect(
        await storage.getLastShown(
          banner.id,
          surface: FakeSurface.banner,
          variant: FakeVariant.variantA,
        ),
        fixedAt,
      );
      expect(analyticsEvents, ['shown:banner']);
      expect(slots.activeFor(FakeSurface.banner), banner);
    });

    test('dismiss updates slots and records storage', () async {
      final active = item('active', FakeSurface.banner);
      final queued = item('queued', FakeSurface.banner);
      final initial = const _SlotState.empty()
          .withActive(FakeSurface.banner, active)
          .withEnqueued(FakeSurface.banner, queued);

      final analyticsEvents = <String>[];
      final analytics = _RecordingAnalytics(analyticsEvents);

      final next = await PresentumLifecycle.dismiss(
        slots: initial,
        surface: FakeSurface.banner,
        item: active,
        storage: storage,
        at: fixedAt,
        handlers: [PresentumAnalyticsEventHandler(analytics: analytics)],
      );

      expect(next.activeFor(FakeSurface.banner), queued);
      expect(next.queueFor(FakeSurface.banner), isEmpty);
      expect(
        await storage.getDismissedAt(
          active.id,
          surface: FakeSurface.banner,
          variant: FakeVariant.variantA,
        ),
        fixedAt,
      );
      expect(analyticsEvents, ['dismissed:active']);
      expect(initial.activeFor(FakeSurface.banner), active);
    });

    test('dismiss clears active when queue is empty', () async {
      final active = item('solo', FakeSurface.modal);
      final initial = const _SlotState.empty().withActive(
        FakeSurface.modal,
        active,
      );

      final next = await PresentumLifecycle.dismiss(
        slots: initial,
        surface: FakeSurface.modal,
        item: active,
        storage: storage,
        at: fixedAt,
      );

      expect(next.activeFor(FakeSurface.modal), isNull);
      expect(
        await storage.getDismissedAt(
          active.id,
          surface: FakeSurface.modal,
          variant: FakeVariant.variantA,
        ),
        fixedAt,
      );
    });

    test('PresentumAnalytics.fromFunctions wires through handler', () async {
      final banner = item('banner', FakeSurface.banner);
      final events = <String>[];

      final analytics =
          PresentumAnalytics<FakeItem, FakeSurface, FakeVariant>.fromFunctions(
            onShown: (event) => events.add('shown:${event.item.payload.id}'),
            onDismissed: (event) =>
                events.add('dismissed:${event.item.payload.id}'),
            onConverted: (event) =>
                events.add('converted:${event.item.payload.id}'),
          );

      await PresentumLifecycle.shown(
        item: banner,
        storage: storage,
        at: fixedAt,
        handlers: [
          PresentumAnalyticsEventHandler<FakeItem, FakeSurface, FakeVariant>(
            analytics: analytics,
          ),
        ],
      );

      expect(events, ['shown:banner']);
    });
  });
}
