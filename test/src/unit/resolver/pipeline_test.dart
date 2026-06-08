import 'package:flutter_test/flutter_test.dart';
import 'package:presentum/src/resolver/pipeline.dart';
import 'package:presentum/src/resolver/presentum_resolver.dart';
import 'package:presentum/src/resolver/presentum_resolver_step.dart';
import 'package:presentum/src/resolver/step_input.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/slot_state.dart';
import 'package:presentum/src/state/surface.dart';
import 'package:presentum/src/storage/storage.dart';
import 'package:presentum/src/transitions/slots_transition.dart';

import '../fake_payload.dart';

typedef _SlotState = PresentumSlotState<FakeItem, FakeSurface, FakeVariant>;
typedef _Transition =
    PresentumSlotsTransition<FakeItem, FakeSurface, FakeVariant>;
typedef _Pipeline = PresentumStepsPipeline<FakeItem, FakeSurface, FakeVariant>;

final class _FnStep<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    implements PresentumResolverStep<TItem, S, V> {
  const _FnStep(this.run);

  final Future<PresentumSlotState<TItem, S, V>> Function(
    PresentumStepInput<TItem, S, V> input,
  )
  run;

  @override
  Future<PresentumSlotState<TItem, S, V>> call(
    PresentumStepInput<TItem, S, V> input,
  ) => run(input);
}

void main() {
  group('PresentumStepsPipeline', () {
    const storage = NoOpPresentumStorage<FakeSurface, FakeVariant>();

    FakeItem item(String id, FakeSurface surface) =>
        createFakeItem(id, surface, FakeVariant.variantA);

    test('threads current through two steps', () async {
      final bannerItem = item('banner', FakeSurface.banner);
      final modalItem = item('modal', FakeSurface.modal);

      final pipeline = _Pipeline(
        storage: storage,
        steps: [
          _FnStep(
            (input) async =>
                input.current.withActive(FakeSurface.banner, bannerItem),
          ),
          _FnStep(
            (input) async =>
                input.current.withActive(FakeSurface.modal, modalItem),
          ),
        ],
      );

      final result = await pipeline.call(
        candidates: [bannerItem, modalItem],
        context: const {},
      );

      expect(result.activeFor(FakeSurface.banner), bannerItem);
      expect(result.activeFor(FakeSurface.modal), modalItem);
    });

    test('failing step rethrows without applying partial result', () async {
      final bannerItem = item('banner', FakeSurface.banner);
      var step1Ran = false;
      _Transition? transition;

      final pipeline = _Pipeline(
        storage: storage,
        steps: [
          _FnStep((input) async {
            step1Ran = true;
            return input.current.withActive(FakeSurface.banner, bannerItem);
          }),
          _FnStep((_) async => throw StateError('step failed')),
        ],
      );

      await expectLater(
        pipeline.call(
          candidates: const [],
          context: const {},
          onTransition: (t) => transition = t,
        ),
        throwsStateError,
      );

      expect(step1Ran, isTrue);
      expect(transition, isNull);
    });

    test('invokes onTransition after success', () async {
      final bannerItem = item('banner', FakeSurface.banner);
      final fixedNow = DateTime.utc(2026, 1, 15);
      _Transition? captured;

      final pipeline = _Pipeline(
        storage: storage,
        steps: [
          _FnStep(
            (input) async =>
                input.current.withActive(FakeSurface.banner, bannerItem),
          ),
        ],
      );

      const initial = _SlotState.empty();

      await pipeline.call(
        candidates: [bannerItem],
        context: const {},
        current: initial,
        now: fixedNow,
        onTransition: (transition) => captured = transition,
      );

      final transition = captured;
      expect(transition, isNotNull);
      expect(transition!.oldSlots, initial);
      expect(transition.newSlots.activeFor(FakeSurface.banner), bannerItem);
      expect(transition.timestamp, fixedNow);
    });

    test('passes storage via step input', () async {
      PresentumStorage<FakeSurface, FakeVariant>? seenStorage;

      final pipeline = _Pipeline(
        storage: storage,
        steps: [
          _FnStep((input) async {
            seenStorage = input.storage;
            return input.current;
          }),
        ],
      );

      await pipeline.call(candidates: const [], context: const {});

      expect(seenStorage, storage);
    });
  });

  group('PresentumResolver', () {
    const storage = NoOpPresentumStorage<FakeSurface, FakeVariant>();

    test('delegates call to pipeline', () async {
      final bannerItem = createFakeItem(
        'banner',
        FakeSurface.banner,
        FakeVariant.variantA,
      );

      final resolver = PresentumResolver<FakeItem, FakeSurface, FakeVariant>(
        storage: storage,
        steps: [
          _FnStep(
            (input) async =>
                input.current.withActive(FakeSurface.banner, bannerItem),
          ),
        ],
      );

      final viaResolver = await resolver.call(
        candidates: [bannerItem],
        context: const {},
      );
      final viaPipeline = await resolver.pipeline.call(
        candidates: [bannerItem],
        context: const {},
      );

      expect(viaResolver, viaPipeline);
      expect(viaResolver.activeFor(FakeSurface.banner), bannerItem);
    });
  });
}
