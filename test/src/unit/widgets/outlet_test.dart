import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presentum/src/state/slot_state.dart';
import 'package:presentum/src/widgets/outlet.dart';
import 'package:presentum/src/widgets/slot_listener.dart';

import '../fake_payload.dart';

typedef _SlotState = PresentumSlotState<FakeItem, FakeSurface, FakeVariant>;

void main() {
  group('PresentumSlotItemsCollector', () {
    FakeItem item(String id) =>
        createFakeItem(id, FakeSurface.banner, FakeVariant.variantA);

    test('single returns active only when queue exists', () {
      final active = item('active');
      final queued = item('queued');
      final slots = const _SlotState.empty()
          .withActive(FakeSurface.banner, active)
          .withEnqueued(FakeSurface.banner, queued);

      const collector =
          PresentumSlotItemsCollector<
            FakeItem,
            FakeSurface,
            FakeVariant
          >.single();

      expect(collector.collect(slots, FakeSurface.banner), [active]);
    });

    test('all returns active and queue', () {
      final active = item('active');
      final queued = item('queued');
      final slots = const _SlotState.empty()
          .withActive(FakeSurface.banner, active)
          .withEnqueued(FakeSurface.banner, queued);

      const collector =
          PresentumSlotItemsCollector<FakeItem, FakeSurface, FakeVariant>.all();

      expect(collector.collect(slots, FakeSurface.banner), [active, queued]);
    });

    test('custom applies selection logic', () {
      final active = item('active');
      final queued = item('queued');
      final slots = const _SlotState.empty()
          .withActive(FakeSurface.banner, active)
          .withEnqueued(FakeSurface.banner, queued);

      final collector =
          PresentumSlotItemsCollector<
            FakeItem,
            FakeSurface,
            FakeVariant
          >.custom((items) => items.reversed.toList());

      expect(collector.collect(slots, FakeSurface.banner), [queued, active]);
    });
  });

  group('PresentumOutlet', () {
    testWidgets('renders active item from slots', (tester) async {
      final active = createFakeItem(
        'banner',
        FakeSurface.banner,
        FakeVariant.variantA,
      );
      var slots = const _SlotState.empty().withActive(
        FakeSurface.banner,
        active,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) =>
                PresentumOutlet<FakeItem, FakeSurface, FakeVariant>(
                  slots: slots,
                  surface: FakeSurface.banner,
                  builder: (context, item) => Text('item:${item.payload.id}'),
                ),
          ),
        ),
      );

      expect(find.text('item:banner'), findsOneWidget);

      slots = const _SlotState.empty();
      await tester.pumpWidget(
        MaterialApp(
          home: PresentumOutlet<FakeItem, FakeSurface, FakeVariant>(
            slots: slots,
            surface: FakeSurface.banner,
            builder: (context, item) => Text('item:${item.payload.id}'),
          ),
        ),
      );

      expect(find.text('item:banner'), findsNothing);
    });
  });

  group('PresentumSlotListener', () {
    testWidgets('fires listener when active changes', (tester) async {
      final first = createFakeItem(
        'first',
        FakeSurface.modal,
        FakeVariant.variantA,
      );
      final second = createFakeItem(
        'second',
        FakeSurface.modal,
        FakeVariant.variantA,
      );
      var slots = const _SlotState.empty().withActive(FakeSurface.modal, first);
      final events = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: PresentumSlotListener<FakeItem, FakeSurface, FakeVariant>(
            slots: slots,
            surface: FakeSurface.modal,
            listener: (previous, current) =>
                events.add('${previous?.payload.id}->${current?.payload.id}'),
            child: const SizedBox(),
          ),
        ),
      );

      expect(events, isEmpty);

      slots = slots.withActive(FakeSurface.modal, second);
      await tester.pumpWidget(
        MaterialApp(
          home: PresentumSlotListener<FakeItem, FakeSurface, FakeVariant>(
            slots: slots,
            surface: FakeSurface.modal,
            listener: (previous, current) =>
                events.add('${previous?.payload.id}->${current?.payload.id}'),
            child: const SizedBox(),
          ),
        ),
      );

      expect(events, ['first->second']);
    });
  });

  group('Outlet rebuild effectiveness', () {
    testWidgets('PresentumOutlet skips setState when only queue changes', (
      tester,
    ) async {
      final active = createFakeItem(
        'active',
        FakeSurface.banner,
        FakeVariant.variantA,
      );
      final queued = createFakeItem(
        'queued',
        FakeSurface.banner,
        FakeVariant.variantA,
      );
      final hostKey = GlobalKey<_OutletTestHostState>();
      var builderCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: _OutletTestHost(
            key: hostKey,
            initialSlots: const _SlotState.empty().withActive(
              FakeSurface.banner,
              active,
            ),
            child: (slots) =>
                PresentumOutlet<FakeItem, FakeSurface, FakeVariant>(
                  slots: slots,
                  surface: FakeSurface.banner,
                  builder: (context, item) {
                    builderCount++;
                    return Text('item:${item.payload.id}');
                  },
                ),
          ),
        ),
      );

      expect(builderCount, 1);
      expect(find.text('item:active'), findsOneWidget);

      hostKey.currentState!.updateSlots(
        hostKey.currentState!.slots.withEnqueued(FakeSurface.banner, queued),
      );
      await tester.pump();

      expect(builderCount, 2);
      expect(find.text('item:active'), findsOneWidget);
    });

    testWidgets('PresentumOutlet rebuilds when active id changes', (
      tester,
    ) async {
      final first = createFakeItem(
        'first',
        FakeSurface.banner,
        FakeVariant.variantA,
      );
      final second = createFakeItem(
        'second',
        FakeSurface.banner,
        FakeVariant.variantA,
      );
      final hostKey = GlobalKey<_OutletTestHostState>();

      await tester.pumpWidget(
        MaterialApp(
          home: _OutletTestHost(
            key: hostKey,
            initialSlots: const _SlotState.empty().withActive(
              FakeSurface.banner,
              first,
            ),
            child: (slots) =>
                PresentumOutlet<FakeItem, FakeSurface, FakeVariant>(
                  slots: slots,
                  surface: FakeSurface.banner,
                  builder: (context, item) => Text('item:${item.payload.id}'),
                ),
          ),
        ),
      );

      hostKey.currentState!.updateSlots(
        hostKey.currentState!.slots.withActive(FakeSurface.banner, second),
      );
      await tester.pump();

      expect(find.text('item:second'), findsOneWidget);
      expect(find.text('item:first'), findsNothing);
    });

    testWidgets(r'PresentumOutlet$Composition skips setState for queue-only', (
      tester,
    ) async {
      final active = createFakeItem(
        'active',
        FakeSurface.banner,
        FakeVariant.variantA,
      );
      final queued = createFakeItem(
        'queued',
        FakeSurface.banner,
        FakeVariant.variantA,
      );
      final hostKey = GlobalKey<_OutletTestHostState>();
      var builderCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: _OutletTestHost(
            key: hostKey,
            initialSlots: const _SlotState.empty().withActive(
              FakeSurface.banner,
              active,
            ),
            child: (slots) =>
                PresentumOutlet$Composition<FakeItem, FakeSurface, FakeVariant>(
                  slots: slots,
                  surface: FakeSurface.banner,
                  builder: (context, items) {
                    builderCount++;
                    return Text('count:${items.length}');
                  },
                ),
          ),
        ),
      );

      expect(builderCount, 1);
      expect(find.text('count:1'), findsOneWidget);

      hostKey.currentState!.updateSlots(
        hostKey.currentState!.slots.withEnqueued(FakeSurface.banner, queued),
      );
      await tester.pump();

      expect(builderCount, 2);
      expect(find.text('count:1'), findsOneWidget);
    });

    testWidgets(r'PresentumOutlet$Composition rebuilds when collector is all', (
      tester,
    ) async {
      final active = createFakeItem(
        'active',
        FakeSurface.banner,
        FakeVariant.variantA,
      );
      final queued = createFakeItem(
        'queued',
        FakeSurface.banner,
        FakeVariant.variantA,
      );
      final hostKey = GlobalKey<_OutletTestHostState>();
      const collector =
          PresentumSlotItemsCollector<FakeItem, FakeSurface, FakeVariant>.all();

      await tester.pumpWidget(
        MaterialApp(
          home: _OutletTestHost(
            key: hostKey,
            initialSlots: const _SlotState.empty().withActive(
              FakeSurface.banner,
              active,
            ),
            child: (slots) =>
                PresentumOutlet$Composition<FakeItem, FakeSurface, FakeVariant>(
                  slots: slots,
                  surface: FakeSurface.banner,
                  collector: collector,
                  builder: (context, items) => Text('count:${items.length}'),
                ),
          ),
        ),
      );

      expect(find.text('count:1'), findsOneWidget);

      hostKey.currentState!.updateSlots(
        hostKey.currentState!.slots.withEnqueued(FakeSurface.banner, queued),
      );
      await tester.pump();

      expect(find.text('count:2'), findsOneWidget);
    });

    testWidgets(r'PresentumOutlet$Composition respects buildWhen', (
      tester,
    ) async {
      final first = createFakeItem(
        'first',
        FakeSurface.banner,
        FakeVariant.variantA,
      );
      final second = createFakeItem(
        'second',
        FakeSurface.banner,
        FakeVariant.variantA,
      );
      final hostKey = GlobalKey<_OutletTestHostState>();

      await tester.pumpWidget(
        MaterialApp(
          home: _OutletTestHost(
            key: hostKey,
            initialSlots: const _SlotState.empty().withActive(
              FakeSurface.banner,
              first,
            ),
            child: (slots) =>
                PresentumOutlet$Composition<FakeItem, FakeSurface, FakeVariant>(
                  slots: slots,
                  surface: FakeSurface.banner,
                  buildWhen: (previous, current) => false,
                  builder: (context, items) =>
                      Text('item:${items.first.payload.id}'),
                ),
          ),
        ),
      );

      hostKey.currentState!.updateSlots(
        hostKey.currentState!.slots.withActive(FakeSurface.banner, second),
      );
      await tester.pump();

      expect(find.text('item:first'), findsOneWidget);
      expect(find.text('item:second'), findsNothing);
    });

    testWidgets(r'PresentumOutlet$Composition2 debounces rapid slot updates', (
      tester,
    ) async {
      final banner = createFakeItem(
        'banner',
        FakeSurface.banner,
        FakeVariant.variantA,
      );
      final modalA = createFakeItem(
        'modal-a',
        FakeSurface.modal,
        FakeVariant.variantA,
      );
      final modalB = createFakeItem(
        'modal-b',
        FakeSurface.modal,
        FakeVariant.variantA,
      );
      final hostKey = GlobalKey<_DualOutletTestHostState>();

      await tester.pumpWidget(
        MaterialApp(
          home: _DualOutletTestHost(
            key: hostKey,
            initialSlots1: const _SlotState.empty().withActive(
              FakeSurface.banner,
              banner,
            ),
            initialSlots2: const _SlotState.empty().withActive(
              FakeSurface.modal,
              modalA,
            ),
            child: (slots1, slots2) =>
                PresentumOutlet$Composition2<
                  FakeItem,
                  FakeItem,
                  FakeSurface,
                  FakeVariant,
                  FakeSurface,
                  FakeVariant
                >(
                  slots1: slots1,
                  slots2: slots2,
                  surface1: FakeSurface.banner,
                  surface2: FakeSurface.modal,
                  combiner:
                      const PresentumCompositionItemsCombiner2<
                        FakeItem,
                        FakeItem
                      >.all(),
                  debounceDuration: const Duration(milliseconds: 16),
                  builder: (context, items) =>
                      Text('ids:${items.map((i) => i.payload.id).join(',')}'),
                ),
          ),
        ),
      );

      expect(find.text('ids:banner,modal-a'), findsOneWidget);

      hostKey.currentState!.updateSlots2(
        hostKey.currentState!.slots2.withActive(FakeSurface.modal, modalB),
      );
      await tester.pump(const Duration(milliseconds: 8));
      expect(find.text('ids:banner,modal-a'), findsOneWidget);

      hostKey.currentState!.updateSlots2(
        hostKey.currentState!.slots2.withActive(FakeSurface.modal, modalA),
      );
      await tester.pump(const Duration(milliseconds: 8));
      expect(find.text('ids:banner,modal-a'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('ids:banner,modal-a'), findsOneWidget);
    });

    testWidgets(
      r'PresentumOutlet$Composition2 applies slot change after debounce',
      (tester) async {
        final banner = createFakeItem(
          'banner',
          FakeSurface.banner,
          FakeVariant.variantA,
        );
        final modalA = createFakeItem(
          'modal-a',
          FakeSurface.modal,
          FakeVariant.variantA,
        );
        final modalB = createFakeItem(
          'modal-b',
          FakeSurface.modal,
          FakeVariant.variantA,
        );
        final hostKey = GlobalKey<_DualOutletTestHostState>();

        await tester.pumpWidget(
          MaterialApp(
            home: _DualOutletTestHost(
              key: hostKey,
              initialSlots1: const _SlotState.empty().withActive(
                FakeSurface.banner,
                banner,
              ),
              initialSlots2: const _SlotState.empty().withActive(
                FakeSurface.modal,
                modalA,
              ),
              child: (slots1, slots2) =>
                  PresentumOutlet$Composition2<
                    FakeItem,
                    FakeItem,
                    FakeSurface,
                    FakeVariant,
                    FakeSurface,
                    FakeVariant
                  >(
                    slots1: slots1,
                    slots2: slots2,
                    surface1: FakeSurface.banner,
                    surface2: FakeSurface.modal,
                    combiner:
                        const PresentumCompositionItemsCombiner2<
                          FakeItem,
                          FakeItem
                        >.all(),
                    debounceDuration: const Duration(milliseconds: 16),
                    builder: (context, items) =>
                        Text('ids:${items.map((i) => i.payload.id).join(',')}'),
                  ),
            ),
          ),
        );

        hostKey.currentState!.updateSlots2(
          hostKey.currentState!.slots2.withActive(FakeSurface.modal, modalB),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump();

        expect(find.text('ids:banner,modal-b'), findsOneWidget);
      },
    );
  });
}

class _OutletTestHost extends StatefulWidget {
  const _OutletTestHost({
    required this.initialSlots,
    required this.child,
    super.key,
  });

  final _SlotState initialSlots;
  final Widget Function(_SlotState slots) child;

  @override
  State<_OutletTestHost> createState() => _OutletTestHostState();
}

class _OutletTestHostState extends State<_OutletTestHost> {
  late _SlotState slots;

  @override
  void initState() {
    super.initState();
    slots = widget.initialSlots;
  }

  void updateSlots(_SlotState next) => setState(() => slots = next);

  @override
  Widget build(BuildContext context) => widget.child(slots);
}

class _DualOutletTestHost extends StatefulWidget {
  const _DualOutletTestHost({
    required this.initialSlots1,
    required this.initialSlots2,
    required this.child,
    super.key,
  });

  final _SlotState initialSlots1;
  final _SlotState initialSlots2;
  final Widget Function(_SlotState slots1, _SlotState slots2) child;

  @override
  State<_DualOutletTestHost> createState() => _DualOutletTestHostState();
}

class _DualOutletTestHostState extends State<_DualOutletTestHost> {
  late _SlotState slots1;
  late _SlotState slots2;

  @override
  void initState() {
    super.initState();
    slots1 = widget.initialSlots1;
    slots2 = widget.initialSlots2;
  }

  void updateSlots1(_SlotState next) => setState(() => slots1 = next);

  void updateSlots2(_SlotState next) => setState(() => slots2 = next);

  @override
  Widget build(BuildContext context) => widget.child(slots1, slots2);
}
