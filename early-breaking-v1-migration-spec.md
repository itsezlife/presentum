# Presentum v1.0.0 — Breaking Migration Specification (Source of Truth)

**Current release:** v0.3.6  
**Target breaking release:** v1.0.0  

This document supersedes the speculative API sketched in `raw-unverified-breaking-changes.md`. It is grounded in the **actual v0.3.6 codebase** and records architectural decisions, rejected alternatives, scope, widget migration strategy, and resolved/open questions.

---

## 1. Executive Summary

### What stays the same (the package's value)

Presentum remains a **domain layer for conditional UI presentations** — campaigns, maintenance, app updates, banners, popups — with:

- Rich domain model: `PresentumPayload`, `PresentumOption`, `PresentumItem`
- Multi-surface slot coordination: active + queue per surface, promotion on dismiss
- Composable eligibility: `EligibilityResolver` (factory constructor), extractors, rules
- Impression/dismissal/conversion persistence: **`PresentumStorage`**
- Lifecycle events + composable event handlers (storage, analytics, etc.)
- Transition diff system: `PresentumStateTransition`, `PresentumStateDiff` (decoupled from engine)

### What breaks (the architectural sin being removed)

v0.3.6 built an **internal state machine** (Octopus-inspired) that reimplements reactive infrastructure:

| Remove | Reason |
|---|---|
| **`lib/src/state/state.dart` entirely** | Replaced by new `PresentumSlotState` |
| `PresentumState`, `PresentumState$Mutable`, `PresentumState$Immutable` | Host SM owns state |
| `PresentumStateIntention` | Host SM owns transition semantics |
| `Presentum` controller / engine | Host SM owns reactivity |
| `PresentumGuard` / `IPresentumGuard` | Replaced by resolvers + steps |
| Widget `State` mixin + `delegate.build` | Wrong mental model; boilerplate |
| `PresentumStateObserver` (engine-bound) | Host SM triggers rebuilds |
| `InheritedPresentum`, `context.presentum()` | No internal presentum instance |
| Guard `Listenable refresh` → global re-run | Host SM decides when to revalidate |
| Engine-bound transition observers | Diff utilities kept; engine hook removed |
| `PresentumActiveSurfaceItemObserverMixin` | Replaced by `PresentumSlotListener` widget |
| `PresentumPopupSurfaceStateMixin` | Replaced by `PresentumPopupHost` widget |
| `PresentumBlocSlot` | Unnecessary — `BlocSelector` + `PresentumOutlet` |

**Note:** `PresentumSurface`, `PresentumVisualVariant`, and `PresentumSlot` move out of deleted `state.dart` into appropriate new files (`slot.dart`, `surface.dart`, or alongside `PresentumSlotState`).

### What v1.0.0 adds

- **`PresentumSlotState<TItem, S, V>`** — immutable slot container with `withDismissed`, `withActive`, etc.
- **`PresentumStateMixin`** on the consumer's state class — exposes `PresentumSlotState get slots`
- **`PresentumResolver`** — pure `call(...)` → `PresentumSlotState`
- **`PresentumResolver` factory constructor** — default implementation (no public `Default*` types)
- **`PresentumResolverStep`** + **`PresentumStepsPipeline`** — composable pipeline (replaces guards)
- **`PresentumEventDispatcher`** — fan-out lifecycle events to handler list
- **`PresentumSlotListener`** + **`PresentumPopupHost`** — slot-driven widgets (replace observer/popup mixins)

### Integration contract

```
Host event handler
  → build PresentumContext from host state
  → await resolver(...) or await pipeline(...)
  → emit(state.copyWith(slots: newSlots))

Lifecycle (shown / dismissed / converted)
  → host decides: storage directly OR PresentumEventDispatcher.dispatch(...)

UI
  → BlocSelector(state => state.slots) → PresentumOutlet(slots: ...)
  → PresentumTrackedWidget (uses mixin internally)
```

---

## 2. Versioning & Naming Corrections

| Earlier draft (wrong) | v1.0.0 (correct) |
|---|---|
| "v2" breaking release | **v1.0.0** breaking release (current is v0.3.6) |
| Raw `Map<S, PresentumSlot>` on mixin | **`PresentumSlotState<TItem, S, V>`** |
| `EligibilityResolver$Impl` in consumer code | **`EligibilityResolver(...)` factory** |
| `PresentumResolver$Impl` in consumer code | **`PresentumResolver(...)` factory** |
| `PresentumHistoryRepository` | **`PresentumStorage<S, V>`** (keep existing API) |
| `PresentumCandidateEntry` | **`List<TItem> candidates`** |
| `execute(...)` on steps | **`call(...)`** on steps |
| `PresentumBlocSlot` | **Dropped** — `PresentumOutlet` + `BlocSelector` wiring |
| `PresentumPipeline` | **`PresentumStepsPipeline`** |

### Factory constructor pattern (no public `*$Impl` usage)

Consumers never reference concrete `*$Impl` classes. Interfaces expose factory constructors that redirect to default implementations (same pattern as `EligibilityResolver` today):

```dart
// eligibility/resolver.dart — already exists
abstract interface class EligibilityResolver<S> {
  factory EligibilityResolver({
    required List<EligibilityExtractor<S>> extractors,
    List<EligibilityRule>? rules,
  }) {
    final $rules = [...createStandardRules(), ...?rules];
    return EligibilityResolver$Impl(rules: $rules, extractors: extractors);
  }
  ...
}

// resolver/presentum_resolver.dart — v1.0.0
abstract interface class PresentumResolver<TItem, S, V> {
  factory PresentumResolver({
    required PresentumStorage<S, V> storage,
    required EligibilityResolver<HasMetadata> eligibility,
  }) = PresentumResolver$Impl<TItem, S, V>;  // implementation class is @internal / not exported
  ...
}
```

`EligibilityResolver$Impl`, `PresentumResolver$Impl` remain implementation details — not part of the documented public API. Internal rename convention: all former `DefaultX` classes → `X$Impl`.

---

## 3. Domain Model — Preserve As-Is

These types from v0.3.6 are **unchanged** in v1.0.0:

### Core generics

```dart
TItem extends PresentumItem<PresentumPayload<S, V>, S, V>
S extends PresentumSurface
V extends PresentumVisualVariant
```

### Types (keep)

| Type | Notes |
|---|---|
| `PresentumSurface` | Marker mixin on enum — moves to new file |
| `PresentumVisualVariant` | Marker mixin on enum — moves to new file |
| `PresentumOption<S, V>` | `state/payload.dart` — unchanged |
| `PresentumPayload<S, V>` | `state/payload.dart` — unchanged |
| `PresentumItem<TPayload,S,V>` | `state/payload.dart` — unchanged |
| `PresentumSlot<TItem,S,V>` | Per-surface: surface, active, queue — moves to new file |
| `PresentumStorage<S,V>` | `controller/storage.dart` — unchanged |
| `InMemoryPresentumStorage` | Test helper — unchanged |
| `EligibilityResolver`, rules, extractors | `eligibility/` — fully carried forward |
| `PresentumEvent*` | `controller/events.dart` — kept, see §6 |

### Context type

```dart
typedef PresentumContext = Map<String, Object?>;
```

### `alwaysOnIfEligible`

Skips both impression cap and cooldown checks (same as v0.3.6).

---

## 4. PresentumSlotState — Core New Type

### Decision: named immutable type, not raw `Map`

**Use `PresentumSlotState<TItem, S, V>`** — not a raw `Map<S, PresentumSlot>` on the host state mixin.

Rationale:
- Clear API surface: `activeFor(S)`, `queueFor(S)`, `hasActive(S)`, `activeSurfaces`
- Immutable transforms: `withActive`, `withEnqueued`, `withDismissed`, `withCleared`, `withReorderedQueue`
- `copyWith`, equality, `hashCode` for `BlocSelector` / Equatable
- Prevents accidental map mutation in host code
- Resolvers/steps/pipeline all speak `PresentumSlotState` in and out

Replaces the entire deleted `lib/src/state/state.dart`. Slot mutation helpers from `PresentumState$Mutable` become immutable methods on `PresentumSlotState`.

### Slot keying — RESOLVED (Q4)

**One active + queue per surface** (`Map<S, PresentumSlot>` internally, accessed via `PresentumSlotState` API).

- **Surface** = where UI renders (`AppSurface.banner`, `AppSurface.dialog`, etc.)
- **Variant** = how it renders on that surface (`CampaignVariant.inline`, `CampaignVariant.fullscreen`) — metadata on `PresentumItem`
- Banner + dialog concurrently = **different surfaces**, not different variants. Already supported.
- Per-surface+variant keying (multiple actives on one surface for different variants) is **out of scope** — would require a different slot map shape. Not needed for v1.0.0.

Storage keys remain `(itemId, surface, variant)` via `PresentumStorage`.

### PresentumStateMixin

Use when host state carries **one** presentum domain (single `<TItem, S, V>`). For heterogeneous multi-domain state (Pattern E), use explicit typed fields — no mixin on the aggregate state.

```dart
mixin PresentumStateMixin<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant,
> {
  PresentumSlotState<TItem, S, V> get slots;
}
```

Consumer state (single domain):

```dart
class CampaignsState with PresentumStateMixin<CampaignPresentumItem, CampaignSurface, CampaignVariant> {
  @override
  final PresentumSlotState<CampaignPresentumItem, CampaignSurface, CampaignVariant> slots;

  const CampaignsState({this.slots = const PresentumSlotState.empty()});
  CampaignsState copyWith({PresentumSlotState<...>? slots, ...}) => ...;
}
```

### PresentumSlotState API (v1.0.0)

```dart
@immutable
final class PresentumSlotState<TItem, S, V> {
  const PresentumSlotState.empty();
  const PresentumSlotState._(Map<S, PresentumSlot<TItem, S, V>> slots);

  // ── Read ──────────────────────────────────────────────────────────
  PresentumSlot<TItem, S, V>? slotFor(S surface);
  TItem? activeFor(S surface);
  List<TItem> queueFor(S surface);
  bool hasActive(S surface);
  Iterable<S> get activeSurfaces;
  List<TItem> get activeItems;

  // ── Immutable transforms ──────────────────────────────────────────
  PresentumSlotState<TItem, S, V> withActive(S surface, TItem item);
  PresentumSlotState<TItem, S, V> withEnqueued(S surface, TItem item);
  PresentumSlotState<TItem, S, V> withDismissed(S surface);  // promotes queue
  PresentumSlotState<TItem, S, V> withCleared(S surface);
  PresentumSlotState<TItem, S, V> withReorderedQueue(S surface, List<TItem> queue);

  /// Merge slots for [surfaces] from [other]; all other surfaces unchanged.
  PresentumSlotState<TItem, S, V> mergeFrom(
    PresentumSlotState<TItem, S, V> other, {
    required Set<S> surfaces,
  });
}
```

`mergeFrom` supports partial revalidation in a single bloc (see §4.1).

---

## 4.1 One Bloc, Heterogeneous Presentum Domains

The example app today uses **separate Presentum instances per domain**, each with its own item/surface/variant types:

| Domain | Item | Surface | Variant |
|---|---|---|---|
| Campaigns | `CampaignPresentumItem` | `CampaignSurface` | `CampaignVariant` |
| Maintenance | `MaintenanceItem` | `AppSurface` | `AppVariant` |
| Feature | `FeatureItem` | `AppSurface` | `AppVariant` |
| Updates | `AppUpdatesItem` | `AppSurface` | `AppVariant` |
| Shop | `RecommendationItem` | `AppSurface` | `AppVariant` |

This is intentional — each domain owns its payload shape, surface enum, and variant enum. **You do not need to unify these into a single `AppPresentumItem` / `AppSurface` / `AppVariant` to use one bloc.**

### Pattern E — multiple typed slot fields on one bloc state (heterogeneous answer)

One bloc holds **one `PresentumSlotState` per presentum domain**, each fully typed:

```dart
class AppState {
  final PresentumSlotState<CampaignPresentumItem, CampaignSurface, CampaignVariant> campaignSlots;
  final PresentumSlotState<MaintenanceItem, AppSurface, AppVariant> maintenanceSlots;
  final PresentumSlotState<FeatureItem, AppSurface, AppVariant> featureSlots;
}
```

Each domain keeps its own resolver/pipeline, storage (or shared `PresentumStorage<AppSurface, AppVariant>` where surface types match), and eligibility config:

```dart
Future<void> _onRevalidateAll(_, Emitter<AppState> emit) async {
  final context = _buildContext(state);

  final campaignSlots = await _campaignPipeline(
    candidates: _campaignProvider.buildCandidates(),
    context: context,
    initial: state.campaignSlots,
    storage: _storage,
  );

  final maintenanceSlots = await _maintenanceResolver(
    candidates: _maintenanceProvider.buildCandidates(),
    context: context,
    current: state.maintenanceSlots,
  );

  emit(state.copyWith(
    campaignSlots: campaignSlots,
    maintenanceSlots: maintenanceSlots,
  ));
}
```

Partial revalidation — only re-run the domain that changed:

```dart
Future<void> _onCampaignsUpdated(_, Emitter<AppState> emit) async {
  emit(state.copyWith(campaignSlots: await _campaignPipeline(...)));
  // maintenanceSlots, featureSlots untouched
}
```

**No type erasure, no forced unification, no `mergeFrom` across different generic instantiations.**

### Pattern F — unified AppSurface/Variant (optional)

One `PresentumSlotState<AppPresentumItem, AppSurface, AppVariant>` for everything requires unifying payloads under shared types. Valid when domains share surface semantics; **not required for one-bloc architecture.**

### Patterns A–D — single typed presentum (same `<TItem, S, V>`)

When one bloc manages **one** presentum type, these apply within that typed slot state:

- **A:** merged candidates, one pipeline
- **B:** domain-specific steps (each step owns its surfaces within that type)
- **C:** `mergeFrom` for partial surface revalidation within the same `PresentumSlotState`
- **D:** separate blocs — optional; compose UI via `PresentumOutlet$Composition*`

### Dedicated blocs vs one bloc

| Approach | When |
|---|---|
| **One bloc, multiple slot fields (E)** | Shared lifecycle, coordinated revalidation, single `AppState` snapshot |
| **Separate blocs per domain (D)** | Independent lifecycles; matches current example app closely |
| **Unified generic presentum (F)** | Domains share `AppSurface`/`AppVariant` by design |

No "last emit wins" when using Pattern E — each field is independent.

---

## 5. Resolvers & Pipeline

### Coexistence — confirmed

| API | When to use |
|---|---|
| `PresentumResolver(...)` factory | Single call; eligibility + storage + assignment |
| `PresentumStepsPipeline` + steps | Separation of concerns; reusable steps |

Default resolver ≈ inlined `[EligibilityAndSchedulingStep]`.

### Resolver interface

```dart
abstract interface class PresentumResolver<TItem, S, V> {
  factory PresentumResolver({
    required PresentumStorage<S, V> storage,
    required EligibilityResolver<HasMetadata> eligibility,
  }) = PresentumResolver$Impl<TItem, S, V>;

  Future<PresentumSlotState<TItem, S, V>> call({
    required List<TItem> candidates,
    required PresentumContext context,
    PresentumSlotState<TItem, S, V> current = const PresentumSlotState.empty(),
    DateTime? now,
  });
}
```

Usage: `await _resolver(candidates: ..., context: ..., current: state.slots)`

### Step interface

```dart
abstract interface class PresentumResolverStep<TItem, S, V> {
  Future<PresentumSlotState<TItem, S, V>> call({
    required List<TItem> candidates,
    required PresentumContext context,
    required PresentumSlotState<TItem, S, V> current,
    required DateTime now,
    required PresentumStorage<S, V> storage,
  });
}
```

Steps are **`PresentumSlotState → PresentumSlotState`**. Eligibility filtering is internal to scheduling steps.

### PresentumStepsPipeline

```dart
class PresentumStepsPipeline<TItem, S, V> {
  const PresentumStepsPipeline(this.steps);
  final List<PresentumResolverStep<TItem, S, V>> steps;

  Future<PresentumSlotState<TItem, S, V>> call({
    required List<TItem> candidates,
    required PresentumContext context,
    PresentumSlotState<TItem, S, V> initial = const PresentumSlotState.empty(),
    required PresentumStorage<S, V> storage,
    PresentumContext? mutableContext,  // optional shared bag; see below
    DateTime? now,
  }) async { ... }
}
```

Pipeline threads `current` through each step's `call(...)`.

### Mutable pipeline context

Optional. Pipeline accepts a shared `PresentumContext` that steps may mutate (guard-style: `context['update_status'] = ...`). Document as opt-in. If not passed, steps receive the read-only context built by the host.

### Built-in steps

| Step | Responsibility |
|---|---|
| `EligibilityAndSchedulingStep` | Eligibility + storage checks + assign active/queue |
| `EvictionStep` | Remove stale actives; promote queue |
| `PriorityReorderStep` | Re-sort queues by comparator |

Pipeline order is **not canonical** — built-in steps are helpers; compose per domain. Transition analytics via pipeline `onTransition` post-hook (§9), not a step.

### History lag in pipelines (document)

Items assigned in step N are **not** in storage until tracked widget fires `onShown`. Steps see committed storage only.

---

## 6. Lifecycle Events & Handlers

### Keep events — add dispatcher

Events and handlers remain valuable for **declarative, reusable, composable** lifecycle side effects. Without them, every bloc handler imperatively calls storage + analytics + logging.

### Architecture

```dart
abstract interface class PresentumEventHandler<TItem, S, V> {
  FutureOr<void> call(PresentumEvent<TItem, S, V> event);
}

/// Fan-out to all registered handlers in order.
final class PresentumEventDispatcher<TItem, S, V> {
  const PresentumEventDispatcher(this.handlers);
  final List<PresentumEventHandler<TItem, S, V>> handlers;

  Future<void> dispatch(PresentumEvent<TItem, S, V> event) async {
    for (final handler in handlers) {
      await handler(event);
    }
  }
}
```

### Built-in handlers (library-provided)

| Handler | Does |
|---|---|
| `PresentumStorageEventHandler` | `recordShown` / `recordDismissed` / `recordConverted` → storage |
| `PresentumAnalyticsEventHandler` | **Built-in convenience** — accepts per-event callbacks |

```dart
PresentumAnalyticsEventHandler<CampaignPresentumItem, CampaignSurface, CampaignVariant>(
  onShown: (event) => analytics.logShown(event.item),
  onDismissed: (event) => analytics.logDismissed(event.item),
  onConverted: (event, metadata) => analytics.logConverted(event.item, metadata),
)
```

Register alongside storage handler in `PresentumEventDispatcher`. Developers can omit it or replace with custom handlers.

Consumers compose once:

```dart
final _presentumEvents = PresentumEventDispatcher([
  PresentumStorageEventHandler(storage: _storage),
  PresentumAnalyticsEventHandler(analytics: _analytics),
]);
```

### Host decides wiring (Q7 — confirmed)

The **bloc event handler** chooses dispatch vs direct storage — the library provides both paths:

```dart
// Declarative — preferred when multiple handlers exist
await _presentumEvents.dispatch(
  PresentumDismissedEvent(item: item, timestamp: DateTime.now()),
);
emit(state.copyWith(slots: state.slots.withDismissed(surface)));

// Imperative — fine for simple cases
await _storage.recordDismissed(item.id, surface: item.surface, variant: item.variant, at: now);
emit(state.copyWith(slots: state.slots.withDismissed(surface)));
```

Slot state update always happens in the host. Handlers own **persistence and side effects only** — never mutate slot state.

### Dismissal — two concerns (Q6 — confirmed)

| Action | Purpose |
|---|---|
| `slots.withDismissed(surface)` | UI: remove active, promote queue |
| `recordDismissed` / `PresentumDismissedEvent` | Persistence: user explicitly dismissed; affects future eligibility |

Removing from slot state alone does **not** persist dismissal. Both are required for user-initiated dismiss.

---

## 7. Tracked Item Mixins & Widget (implemented as-is)

Three-type mixin stack. Widget + State delegate to mixins — **no duplicated PageStorage logic** in `_PresentumTrackedWidgetState`.

### Layer 1 — `ITrackedItemSourceMixin` (contract)

Abstract mixin class on the **widget** side. Defines `item`, `onShown`, `trackVisibility` as `abstract final` fields.

### Layer 2 — `TrackedItemHostMixin` (widget host)

```dart
mixin TrackedItemHostMixin<TItem, S, V> on StatefulWidget
    implements ITrackedItemSourceMixin<TItem, S, V> {
  String get pageStorageKey => 'presentum_tracked_item:${item.id}';
}
```

Custom widgets: `extends StatefulWidget with TrackedItemHostMixin<...>` and declare `@override final` fields.

### Layer 3 — `TrackedItemStateMixin` (State + PageStorage)

```dart
mixin TrackedItemStateMixin<TItem, S, V, W extends TrackedItemHostMixin<TItem, S, V>>
    on State<W> {
  @override
  void initState() { ... }  // post-frame → widget.onShown(widget.item)
}
```

Reads/writes PageStorage via `widget.pageStorageKey`. **State subclass must not override `initState` without `super.initState()`.**

### `PresentumTrackedWidget`

```dart
class PresentumTrackedWidget<TItem, S, V> extends StatefulWidget
    with TrackedItemHostMixin<TItem, S, V> {
  const PresentumTrackedWidget({
    required this.item,
    required this.onShown,
    required this.builder,
    this.trackVisibility = true,
    super.key,
  });

  @override final TItem item;
  @override final void Function(TItem item) onShown;
  @override final bool trackVisibility;
  final Widget Function(BuildContext context, TItem item) builder;
}

class _PresentumTrackedWidgetState<...> extends State<PresentumTrackedWidget<...>>
    with TrackedItemStateMixin<..., PresentumTrackedWidget<...>> {
  @override
  Widget build(BuildContext context) => widget.builder(context, widget.item);
}
```

### Wiring (v1.0.0)

Host owns persistence — mixins only call `onShown`:

```dart
PresentumTrackedWidget(
  item: item,
  onShown: (item) => _events.dispatch(
    PresentumShownEvent(item: item, timestamp: DateTime.now()),
  ),
  builder: (context, item) => CampaignBanner(item: item),
)
```

**Files:** `lib/src/widgets/tracked_item_state_mixin.dart`, `lib/src/widgets/tracked_widget.dart` — exported from `presentum.dart`.

**Removes:** `context.presentum().markShown()`.

---

## 8. Widget Migration Strategy

**Principle:** widgets accept `PresentumSlotState` (or derive it via host SM). Slot observation logic lives in the outlet — not duplicated per SM (Bloc, CN, Riverpod).

### 8.1 Remove entirely

| Widget/API | Reason |
|---|---|
| `InheritedPresentum` | No internal presentum instance |
| `build_context_extension.presentum()` | No internal presentum instance |
| `PresentumBlocSlot` | `BlocSelector` + `PresentumOutlet` is sufficient |
| `PresentumActiveSurfaceItemObserverMixin` | **Removed** — replaced by `PresentumSlotListener` widget |
| `PresentumPopupSurfaceStateMixin` | **Removed** — replaced by `PresentumPopupHost` widget |

### 8.2 `PresentumOutlet` — adapt (confirmed strategy)

Keep `PresentumOutlet` name. Require `PresentumSlotState` (or `PresentumSlotState?`) as input. React in `didUpdateWidget` when slots reference changes.

```dart
class PresentumOutlet<TItem, S, V> extends StatefulWidget {
  const PresentumOutlet({
    required this.slots,
    required this.surface,
    required this.builder,
    this.placeholderBuilder,
    super.key,
  });

  final PresentumSlotState<TItem, S, V> slots;
  final S surface;
  final PresentumOutletBuilder<TItem> builder;
  final PresentumOutletPlaceholderBuilder? placeholderBuilder;
}
```

Domain app wiring with BLoC:

```dart
BlocSelector<AppBloc, AppState, PresentumSlotState<CampaignItem, AppSurface, CampaignVariant>>(
  selector: (state) => state.slots,
  builder: (context, slots) => PresentumOutlet(
    slots: slots,
    surface: AppSurface.banner,
    builder: (context, item) => CampaignBanner(item: item),
  ),
)
```

Domain app wiring with BLoC (heterogeneous — select the domain's slot field):

```dart
BlocSelector<AppBloc, AppState, PresentumSlotState<CampaignPresentumItem, CampaignSurface, CampaignVariant>>(
  selector: (state) => state.campaignSlots,
  builder: (context, slots) => PresentumOutlet(
    slots: slots,
    surface: CampaignSurface.homeTopBanner,
    builder: (context, item) => CampaignBanner(item: item),
  ),
)
```

Same outlet works with any slot source — only how `slots` is provided differs.

`PresentumOutlet$Composition*` adapts similarly: accept multiple `PresentumSlotState` instances (e.g. `campaignSlots` + `maintenanceSlots` from one or multiple blocs).

### 8.3 `PresentumSlotListener` — replaces observer mixin

**Widget, not mixin** — analogous to `BlocListener`. Accepts `PresentumSlotState`, compares active item for a surface in `didUpdateWidget`, fires listener with `(previous, current)`.

```dart
typedef PresentumSlotListenerCallback<TItem, S, V> = void Function(
  TItem? previous,
  TItem? current,
);

class PresentumSlotListener<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant,
> extends StatefulWidget {
  const PresentumSlotListener({
    required this.slots,
    required this.surface,
    required this.listener,
    this.listenWhen,
    required this.child,
    super.key,
  });

  final PresentumSlotState<TItem, S, V> slots;
  final S surface;
  final PresentumSlotListenerCallback<TItem, S, V> listener;
  final bool Function(TItem? previous, TItem? current)? listenWhen;
  final Widget child;
}
```

With BLoC — wire slots from `BlocListener` or nest inside `BlocBuilder`:

```dart
BlocBuilder<AppBloc, AppState>(
  buildWhen: (p, c) => p.campaignSlots != c.campaignSlots,
  builder: (context, state) => PresentumSlotListener(
    slots: state.campaignSlots,
    surface: CampaignSurface.popup,
    listener: (previous, current) { /* react to active change */ },
    child: child,
  ),
)
```

Or use raw `BlocListener` with manual slot comparison — equivalent, more verbose.

### 8.4 `PresentumPopupHost` — replaces popup mixin

StatefulWidget encapsulating popup presentation logic from v0.3.6 `PresentumPopupSurfaceStateMixin` + observer. Uses `PresentumSlotListener` internally (or inline `didUpdateWidget` slot diff).

```dart
class PresentumPopupHost<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant,
> extends StatefulWidget {
  const PresentumPopupHost({
    required this.slots,
    required this.surface,
    required this.present,
    this.onShown,
    this.onMarkDismissed,
    this.ignoreDuplicates = false,
    this.duplicateThreshold = const Duration(seconds: 3),
    this.conflictStrategy = PopupConflictStrategy.ignore,
    required this.child,
    super.key,
  });

  final PresentumSlotState<TItem, S, V> slots;
  final S surface;
  final Future<PopupPresentResult> Function(TItem item) present;
  final FutureOr<void> Function(TItem item)? onShown;
  final FutureOr<void> Function(TItem item)? onMarkDismissed;
  final bool ignoreDuplicates;
  final Duration? duplicateThreshold;
  final PopupConflictStrategy conflictStrategy;
  final Widget child;
}
```

**v1.0.0 `CampaignPopupHost` equivalent — minimal boilerplate:**

```dart
BlocBuilder<CampaignsBloc, CampaignsState>(
  buildWhen: (p, c) => p.slots != c.slots,
  builder: (context, state) => PresentumPopupHost(
    slots: state.slots,
    surface: CampaignSurface.popup,
    onShown: (item) => context.read<CampaignsBloc>().add(CampaignShown(item)),
    onMarkDismissed: (item) => context.read<CampaignsBloc>().add(CampaignDismissed(item)),
    present: (item) => _showCampaignDialog(context, item),
    child: widget.child,
  ),
)
```

Bloc events handle storage/dispatcher. No mixins, no `InheritedPresentum`, no `context.presentum()`.

Preserves: duplicate detection, conflict strategies, internal queue, `PopupPresentResult` semantics.

---

## 9. Transitions & Analytics

### Adapt diff to `PresentumSlotState`

**Keep:** `PresentumStateTransition`, `PresentumStateDiff`, `SlotDiff`, `SlotChange`

**Change:** Transition wraps `PresentumSlotState` (not deleted `PresentumState`). Remove `intention` field.

```dart
final class PresentumStateTransition<TItem, S, V> {
  const PresentumStateTransition({
    required this.oldSlots,
    required this.newSlots,
    required this.timestamp,
  });

  final PresentumSlotState<TItem, S, V> oldSlots;
  final PresentumSlotState<TItem, S, V> newSlots;
  final DateTime timestamp;

  PresentumStateDiff<TItem, S, V> get diff =>
      PresentumStateDiff.compute(oldSlots, newSlots);
}
```

Remove `IPresentumTransitionObserver` engine hook.

### Pipeline transition analytics — post-hook (recommended)

**Decision:** `PresentumStepsPipeline.call(...)` accepts optional `onTransition` callback. Pipeline captures `initial` at start, runs steps, builds one `PresentumStateTransition`, invokes callback. **Not a pipeline step.**

| Approach | Pros | Cons |
|---|---|---|
| **Post-hook on pipeline** (`onTransition` param) | One transition per invocation (`initial → final`); can't forget; steps stay pure; correct diff semantics | Can't analytics mid-pipeline (rare need) |
| **Last pipeline step** (`TransitionAnalyticsStep`) | Opt-in per pipeline composition; can insert mid-chain | Easy to forget; mid-chain only sees partial diff; redundant if post-hook exists |

```dart
final newSlots = await _pipeline(
  candidates: candidates,
  context: context,
  initial: state.campaignSlots,
  storage: _storage,
  onTransition: (PresentumStateTransition<CampaignPresentumItem, CampaignSurface, CampaignVariant> transition) {
    _analytics.track(transition.diff);  // diff via transition.diff
  },
);
```

`PresentumResolver.call(...)` gets the same optional `onTransition` for symmetry.

No `TransitionAnalyticsStep` in v1.0.0 unless a concrete mid-pipeline use case emerges later.

---

## 10. What NOT to Build (v1.0.0)

| Item | Status |
|---|---|
| Guards | **Removed** — no shim |
| `lib/src/state/state.dart` / `PresentumState` | **Removed** |
| Engine / controller / delegate | **Removed** |
| `PresentumBlocSlot` | **Removed** |
| Public `Default*` / `*$Impl` in consumer code | **Removed** — factory constructors only |
| Raw `Map<S, PresentumSlot>` on mixin | **Removed** — use `PresentumSlotState` |
| `PresentumCandidateEntry` / `eligibilityPayload` | **Rejected** |
| `resolveSequentially` | **Rejected** |
| CN/Provider adapters | **Deferred** — milestone 2 |

---

## 11. Milestones

### Milestone 1 — v1.0.0

1. New `lib/src/state/` module — `surface.dart`, `slot.dart`, `slot_state.dart`, `payload.dart`
2. Delete `lib/src/state/state.dart`
3. `PresentumStateMixin`
4. `PresentumResolver` factory → `PresentumResolver$Impl`
5. `PresentumResolverStep` + built-in steps + `PresentumStepsPipeline` (with `onTransition` post-hook)
6. `PresentumEventDispatcher` + `PresentumStorageEventHandler` + `PresentumAnalyticsEventHandler`
7. Adapt `PresentumOutlet` + composition variants
8. `ITrackedItemSourceMixin` + `TrackedItemHostMixin` + `TrackedItemStateMixin` + `PresentumTrackedWidget`
9. `PresentumSlotListener` + `PresentumPopupHost` (replace observer/popup mixins)
10. Adapt transitions to `PresentumSlotState`
11. Remove engine, guards, controller, inherited presentum, observer/popup mixins
12. Migrate example app
13. Migration guide v0.3.6 → v1.0.0

### Proposed file layout

```
lib/src/
  state/
    surface.dart       # PresentumSurface, PresentumVisualVariant
    slot.dart          # PresentumSlot
    slot_state.dart    # PresentumSlotState
    payload.dart       # PresentumPayload, PresentumOption, PresentumItem (moved)
    state_mixin.dart   # PresentumStateMixin
  resolver/
    presentum_resolver.dart
    presentum_resolver_impl.dart
    presentum_resolver_step.dart
    steps/             # EvictionStep, EligibilityAndSchedulingStep, ...
    pipeline.dart      # PresentumStepsPipeline
  storage/
    storage.dart
  eligibility/         # unchanged structure
  events/
    events.dart
    dispatcher.dart
    handlers.dart      # Storage, Analytics handlers
  transitions/
    transitions.dart   # PresentumStateTransition, PresentumStateDiff
  widgets/
    outlet.dart
    slot_listener.dart
    popup_host.dart
    tracked_item_state_mixin.dart  # ITrackedItemSourceMixin, TrackedItemHostMixin, TrackedItemStateMixin
    tracked_widget.dart            # PresentumTrackedWidget
```

### Milestone 2 — later

- ChangeNotifier / Provider patterns (same mixin + outlet wiring)
- Riverpod guidance
- `PresentumResolversPipeline` if needed
- Guard → step porting guide

---

## 12. Resolved Questions

| # | Question | Answer |
|---|---|---|
| Q1 | Resolver + pipeline coexist? | **Yes** |
| Q2 | `resolveSequentially`? | **No** |
| Q3 | Keep payload/item/option? | **Yes** |
| Q4 | Slot keying | **One active + queue per surface** |
| Q5 | Keep `PresentumOption`? | **Yes** |
| Q6 | Dismissal wiring | **Both slot update + storage/dispatch** |
| Q7 | Storage vs dispatch | **Host bloc event decides** |
| Q8 | Eligibility system | **Fully carried; `EligibilityResolver(...)` factory** |
| Q9 | Analytics | **Pipeline `onTransition` post-hook → `PresentumStateTransition`** |
| Q4-heterogeneous | Multi-type one bloc | **Pattern E — multiple typed slot fields** |
| Observer/popup mixins | Adapt vs widget | **`PresentumSlotListener` + `PresentumPopupHost` widgets** |
| Q13 | Bloc-specific widget | **No — `PresentumOutlet` + `BlocSelector`** |
| Factory pattern | Public `Default*` | **`X$Impl` via factory constructors** |
| Analytics handler | Built-in? | **Yes — `PresentumAnalyticsEventHandler`** |
| Transition analytics | Step vs post-hook | **Post-hook on pipeline/resolver** |

---

## 13. Open Questions

| Topic | Status |
|---|---|
| Guard → step porting guide | Documentation task |
| `PresentumPopupHost` queue/conflict API surface | Finalize during implementation |

---

## 14. Pitfalls

1. **Stale context in async handlers** — build context from current `state` inside handler
2. **Storage lag in pipelines** — in-flight assignments invisible to subsequent steps
3. **Dismiss without recordDismissed** — item reappears on revalidation
4. **recordDismissed without slot update** — storage says dismissed, UI still shows active
5. **Same field, two writers** — one resolver/pipeline per slot field; partial updates touch only that field
6. **`PresentumPopupHost`** — must receive updated `slots` prop when bloc emits
7. **Equatable** — add each slot field to props (e.g. `campaignSlots`, `maintenanceSlots`)

---

## 15. Canonical Usage

### Heterogeneous state (Pattern E)

```dart
class AppState {
  final PresentumSlotState<CampaignPresentumItem, CampaignSurface, CampaignVariant> campaignSlots;
  final PresentumSlotState<MaintenanceItem, AppSurface, AppVariant> maintenanceSlots;
  const AppState({
    this.campaignSlots = const PresentumSlotState.empty(),
    this.maintenanceSlots = const PresentumSlotState.empty(),
  });
}
```

### Single-domain state

```dart
class CampaignsState with PresentumStateMixin<CampaignPresentumItem, CampaignSurface, CampaignVariant> {
  @override
  final PresentumSlotState<CampaignPresentumItem, CampaignSurface, CampaignVariant> slots;
  const CampaignsState({this.slots = const PresentumSlotState.empty()});
}
```

### Pipeline with transition analytics

```dart
final newSlots = await _campaignPipeline(
  candidates: candidates,
  context: context,
  initial: state.campaignSlots,
  storage: _storage,
  onTransition: (transition) => _analytics.track(transition.diff),
);
emit(state.copyWith(campaignSlots: newSlots));
```

### UI — outlet + popup host

```dart
BlocBuilder<CampaignsBloc, CampaignsState>(
  buildWhen: (p, c) => p.slots != c.slots,
  builder: (context, state) => PresentumPopupHost(
    slots: state.slots,
    surface: CampaignSurface.popup,
    onShown: (item) => bloc.add(CampaignShown(item)),
    onMarkDismissed: (item) => bloc.add(CampaignDismissed(item)),
    present: (item) => _showDialog(context, item),
    child: PresentumOutlet(
      slots: state.slots,
      surface: CampaignSurface.homeTopBanner,
      builder: (context, item) => PresentumTrackedWidget(
        item: item,
        onShown: (item) => bloc.add(CampaignShown(item)),
        builder: (_, item) => CampaignBanner(item: item),
      ),
    ),
  ),
)
```

---

## 16. Ownership Map

```
┌──────────────────────────────────────────────────────────────┐
│                     presentum v1.0.0                          │
│                                                               │
│  PRESERVED                 NEW CORE              ADAPTED UI    │
│  ─────────                 ────────              ───────────   │
│  PresentumItem/Payload/    PresentumSlotState    PresentumOutlet│
│  PresentumOption           PresentumStateMixin   TrackedWidget  │
│  PresentumSlot             PresentumResolver(*)  SlotListener    │
│  PresentumStorage          PresentumResolverStep PopupHost       │
│  EligibilityResolver(*)    PresentumStepsPipeline                │
│  PresentumEvent*           PresentumEventDispatcher              │
│  PresentumStateTransition  Built-in steps                        │
│  Trackable/Tracked mixins → ITrackedItemSource / TrackedItem*     │
│                                                               │
│  (*) factory → X$Impl, not public                                │
└──────────────────────────────────────────────────────────────┘
         ▲                              ▲
         │ implements                   │ owns slot fields + revalidation
┌────────────────────┐      ┌──────────────────────────────┐
│   Your app         │      │   Your BLoC / host SM         │
│  PresentumStorage  │      │  campaignSlots, maintenance…  │
│  event handlers    │      │  await resolver/pipeline(...) │
└────────────────────┘      └──────────────────────────────┘

REMOVED: state/state.dart, engine, guards, controller, delegate,
         InheritedPresentum, PresentumStateObserver,
         ActiveSurfaceItemObserverMixin, PopupSurfaceStateMixin
```

---

*Last updated: heterogeneous multi-domain (Pattern E), slot listener/popup host widgets, tracked mixin hierarchy, pipeline onTransition post-hook.*
