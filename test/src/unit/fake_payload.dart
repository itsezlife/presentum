// Test types for the transition system
import 'package:presentum/presentum.dart';

enum FakeSurface with PresentumSurface { banner, modal, tooltip }

enum FakeVariant with PresentumVisualVariant { variantA, variantB }

class FakeOption extends PresentumOption<FakeSurface, FakeVariant> {
  const FakeOption({
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
  final FakeVariant variant;

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

class FakePayload extends PresentumPayload<FakeSurface, FakeVariant> {
  const FakePayload({
    required this.id,
    required this.metadata,
    required this.priority,
    required this.options,
  });

  @override
  final String id;

  @override
  final Map<String, Object?> metadata;

  @override
  final int priority;

  @override
  final List<PresentumOption<FakeSurface, FakeVariant>> options;
}

class FakeItem extends PresentumItem<FakePayload, FakeSurface, FakeVariant> {
  const FakeItem({required this.payload, required this.option});

  @override
  final FakePayload payload;

  @override
  final FakeOption option;
}

FakeItem createFakeItem(String id, FakeSurface surface, FakeVariant variant) =>
    FakeItem(
      payload: FakePayload(
        id: id,
        metadata: {},
        priority: 0,
        options: [FakeOption(surface: surface, variant: variant)],
      ),
      option: FakeOption(surface: surface, variant: variant),
    );
