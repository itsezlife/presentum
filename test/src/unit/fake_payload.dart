// Test types for the transition system
import 'package:presentum/presentum.dart';

enum FakeSurface with PresentumSurface { banner, modal, tooltip }

enum FakeVisualVariant with PresentumVisualVariant { variantA, variantB }

class FakeVariant extends PresentumVariant<FakeSurface, FakeVisualVariant> {
  const FakeVariant({
    required this.surface,
    required this.variant,
    this.stage,
    this.maxImpressions,
    this.alwaysOnIfEligible = false,
    this.isDismissible = true,
    this.cooldownMinutes,
  });

  @override
  final FakeSurface surface;

  @override
  final FakeVisualVariant variant;

  @override
  final int? stage;

  @override
  final int? maxImpressions;

  @override
  final bool alwaysOnIfEligible;

  @override
  final bool isDismissible;

  @override
  final int? cooldownMinutes;
}

class FakePayload extends PresentumPayload<FakeSurface, FakeVisualVariant> {
  const FakePayload({
    required this.id,
    required this.metadata,
    required this.priority,
    required this.variants,
  });

  @override
  final String id;

  @override
  final Map<String, Object?> metadata;

  @override
  final int priority;

  @override
  final List<PresentumVariant<FakeSurface, FakeVisualVariant>> variants;
}

class FakeResolved
    extends
        ResolvedPresentumVariant<FakePayload, FakeSurface, FakeVisualVariant> {
  const FakeResolved({required this.payload, required this.variant});

  @override
  final FakePayload payload;

  @override
  final FakeVariant variant;
}

FakeResolved createFakeResolved(
  String id,
  FakeSurface surface,
  FakeVisualVariant variant,
) => FakeResolved(
  payload: FakePayload(
    id: id,
    metadata: {},
    priority: 0,
    variants: [FakeVariant(surface: surface, variant: variant)],
  ),
  variant: FakeVariant(surface: surface, variant: variant),
);
