# Presentum

<!-- [![Pub][pub_badge]][pub_link] -->
<!-- [![CI][ci_badge]][ci_link] -->

[![License: MIT][pub_badge]][license_link]
[![Linter][linter_badge]][linter_link]
[![GitHub stars](https://img.shields.io/github/stars/itsezlife/presentum?style=social)](https://github.com/itsezlife/presentum/)

A declarative cross-platform Flutter engine with focus on state to display presentations, such as campaigns, banners, notifications, etc., anywhere, anytime.

Presentum is a strongly typed presentation engine inspired by Octopus router. It lets you describe what should be shown on each presentation surface as immutable state, while a pure engine, guards, storage and outlets take care of:

- resolving which payloads are eligible
- deciding how and where they appear
- tracking impressions, dismissals and conversions
- rendering them in the UI without business logic in widgets

Presentum is **not** a router, **not** a layout system and **not** a generic rules engine. It focuses on one thing: orchestrating presentations such as campaigns, banners, tips, and system messages across your app.

## Installation

In order to use Presentum you must have the [Flutter SDK][flutter_install_link] installed.

Add the package to your `pubspec.yaml`:

```sh
dart pub add presentum
```

## Core concepts

### Surfaces

A **surface** is a concrete place in your UI where presentations can appear, for example:

- `homeTopBanner`
- `watchlistHeader`
- `tickerPageInlineTip`

Surfaces implement `PresentumSurface`, usually via enums:

```dart
enum AppSurface with PresentumSurface {
  homeTopBanner,
  watchlistHeader;
}
```

All engine generics use `S extends PresentumSurface`, not raw `Enum`. Surfaces describe **where** something is presented, independent of which domain owns it.

### Payloads and options

A **payload** is the domain object you want to show: a campaign, a tip, a system message, and so on. It has:

- an id and priority
- metadata for your domain
- a list of options describing how it may appear on different surfaces

```dart
enum CampaignVisual { banner, inline, dialog }

class CampaignPayload extends PresentumPayload<AppSurface, CampaignVisual> {
  CampaignPayload({
    required this.id,
    required this.priority,
    required this.metadata,
    required this.options,
  });

  @override
  final String id;

  @override
  final int priority;

  @override
  final Map<String, Object?> metadata;

  @override
  final List<PresentumOption<AppSurface, CampaignVisual>> options;
}
```

Each option ties a payload to a surface and a visual style:

```dart
const homeBanner = PresentumOption<AppSurface, CampaignVisual>(
  surface: AppSurface.homeTopBanner,
  visual: CampaignVisual.banner,
  stage: 0,
  maxImpressions: 5,
  cooldownMinutes: 60,
  alwaysOnIfEligible: false,
  isDismissible: true,
);
```

### Presentation items

A **presentation item** is a concrete decision: "show payload P with option V on surface S now".

```dart
typedef CampaignItem = PresentumItem<
  CampaignPayload,
  AppSurface,
  CampaignVisual
>;
```

This is the type that flows through state, guards and outlets. It gives you:

- the domain payload (`payload`),
- the presentation option (`option`),
- the derived `surface`, `visual`, `priority`, `metadata` and `stage`.

### Slots and state

State is modelled as **slots** per surface plus an **intention**:

- one `active` item per surface
- an ordered `queue` of additional items per surface

```dart
final slot = PresentumSlot<CampaignItem, AppSurface>(
  surface: AppSurface.homeTopBanner,
  active: campaignItem,
  queue: <CampaignItem>[],
);
```

`PresentumState<TItem, S>` is a sealed root with immutable and mutable implementations:

- `PresentumState$Immutable` is the snapshot exposed to widgets and observers,
- `PresentumState$Mutable` is used inside the engine and guards to mutate slots.

The `PresentumStateIntention` controls history and semantics:

- `auto`: default; history is updated when values change,
- `replace`: overwrite the last history entry,
- `append`: explicitly push a new history entry,
- `cancel`: abort transition, do not change state.

### Storage

`PresentumStorage` is the persistence contract for impressions, dismissals and conversions. You provide an implementation that fits your stack (shared preferences, SQLite, REST backend, analytics pipeline, and so on).

```dart
class InMemoryPresentumStorage implements PresentumStorage {
  @override
  Future<void> init() async {}

  @override
  Future<void> clear() async {}

  @override
  FutureOr<void> recordShown(
    String itemId, {
    required Enum surface,
    required Enum visual,
    required DateTime at,
  }) {
    // Track impressions.
  }

  // Implement getLastShown, getShownCount, recordDismissed,
  // getDismissedUntil, recordConverted...
}
```

Guards and commands use storage; the engine treats it as an abstraction.

### Guards

Guards are the behaviour layer. Here is what they do:

- inspect history, storage, current mutable state and the current candidates
- apply eligibility and sequencing rules
- mutate the passed state (add/remove/replace items in slots)
- optionally cancel transitions

```dart
class CampaignGuard
    extends PresentumGuard<CampaignItem, AppSurface> {
  CampaignGuard({super.refresh});

  @override
  FutureOr<PresentumState<CampaignItem, AppSurface>> call(
    PresentumStorage storage,
    List<PresentumHistoryEntry<CampaignItem, AppSurface>> history,
    PresentumState$Mutable<CampaignItem, AppSurface> state,
    List<CampaignItem> candidates,
    Map<String, Object?> context,
  ) {
    // Example: only allow the highest priority campaign per surface.
    for (final candidate in candidates) {
      final surface = candidate.surface;
      final existing = state.slots[surface]?.active;
      if (existing == null || candidate.priority > existing.priority) {
        state.setActive(surface, candidate);
        // maybe queue others...
      }
    }

    return state;
  }
}
```

Guards can subscribe to external changes using the optional `refresh` `Listenable`; when `notifyListeners` is called, the engine re‑runs all guards against the current state.

### Architecture overview

Presentum is split into:

- **`Presentum<TItem, S>`** - the main controller API:
  - exposes `state`, `observer`, `history`
  - provides `transaction`, `pushSlot`, `markShown`, `markDismissed`, `markConverted`, `removeById`, `setState` and others
  - owns a `PresentumConfig` instance
- **`PresentumEngine<TItem, S>`** - pure core engine that:
  - holds the current immutable state and history (via the observer)
  - processes transitions through a queue
  - runs guards in order
  - commits new state to the observer
- **`PresentumStateObserver<TItem, S>`** - wraps the latest immutable state and a history list

You only implement this logic: collect candidates from providers and events, apply diffing algorithm to identify inserts/updates/removes, and update state with new candidates in the engine via `setCandidates`. This separation keeps the engine generic and testable while leaving integrations up to you.

### Outlets

Outlets are simple widgets that render whatever the state implies for a surface. There is no business logic in the widgets themselves.

- `PresentumOutlet<TItem, S>` renders at most one item (the active one)
- `PresentumOutlet$Composition<TItem, S>` resolved active + queue from a surface slot and passes them to the builder
- `PresentumOutlet$Composition2` and `PresentumOutlet$Composition3` can merge items across two or three different presentums

```dart
class HomeTopBannerOutlet
    extends PresentumOutlet<CampaignItem, AppSurface> {
  const HomeTopBannerOutlet({super.key})
      : super(surface: AppSurface.homeTopBanner);

  @override
  PresentumBuilder<CampaignItem> get builder =>
      (context, item) {
        final payload = item.payload;
        return BannerWidget(
          title: payload.metadata['title'] as String? ?? '',
          onClose: () =>
              context
                  .presentum<CampaignItem, AppSurface>()
                  .markDismissed(item),
        );
      };
}
```

If no item is active for the surface, outlets render `SizedBox.shrink()`.

## Quick start

### 1. Define surfaces and visual styles

```dart
enum AppSurface with PresentumSurface {
  homeTopBanner,
  watchlistHeader;
}

enum CampaignVisual with PresentumVisualVariant {
  banner,
  inline,
  dialog;
}
```

### 2. Define payload and item types

```dart
class CampaignPayload extends PresentumPayload<AppSurface, CampaignVisual> {
  CampaignPayload({
    required this.id,
    required this.priority,
    required this.metadata,
    required this.options,
  });

  @override
  final String id;

  @override
  final int priority;

  @override
  final Map<String, Object?> metadata;

  @override
  final List<PresentumOption<AppSurface, CampaignVisual>> options;
}

typedef CampaignItem = PresentumItem<
  CampaignPayload,
  AppSurface,
  CampaignVisual
>;
```

### 3. Provide storage and guards

```dart
final storage = PersistentStorage();

final guards = <IPresentumGuard<CampaignItem, AppSurface>>[
  CampaignGuard(),
];
```

### 4. Create a Presentum instance

```dart
final presentum = Presentum<CampaignItem, AppSurface>(
  storage: storage,
  bindings: PresentumBindings<CampaignItem, AppSurface>(
    surfaceOf: (item) => item.surface,
    visualOf: (item) => item.visual,
  ),
  guards: guards,
);
```

### 5. Wire the engine into the widget tree

Use the engine to inject an `InheritedPresentum` into your app subtree:

```dart
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return presentum.config.engine.build(
      context,
      MaterialApp(
        home: HomeScreen(),
      ),
    );
  }
}
```

You can later access the same `presentum` instance with:

```dart
final presentum = context
    .presentum<CampaignItem, AppSurface>();
```

or:

```dart
final presentum = Presentum.of<CampaignItem, AppSurface>(context);
```

### 6. Feed candidates into the engine

You collect candidates (for example from the Firebase Remote config), process diff against already existing candidates, and passes updated candidates to the engine. A typical pattern is to do this from a `Bloc`, `ChangeNotifier` or custom service:

```dart
Future<void> updateCampaigns(
  List<CampaignItem> next,
) async {
  await presentum.config.engine.setCandidates(
    (state, current) {
      // your logic here ...
    },
  );
}
```

Guards now receive the updated `candidates` list and can decide which ones should become active or queued in each slot.

### 7. Render surfaces with outlets

In your widgets, use outlets to render current state:

```dart
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const HomeTopBannerOutlet(),
        Expanded(
          child: ListView(
            children: const [
              // Other content...
            ],
          ),
        ),
      ],
    );
  }
}
```

For more complex layouts, use `PresentumOutlet$Composition` to combine active and queued items or merge multiple different surfaces by type.

## Changelog

Refer to the [Changelog](https://github.com/itsezlife/presentum/blob/master/CHANGELOG.md) to get all release notes.

## Maintainers

- [Emil Zulufov aka ezIT](https://ezit.vercel.app)

<!-- ## Funding

If you want to support the development of our library, there are several ways you can do it:

- [Buy me a coffee](https://www.buymeacoffee.com/plugfox)
- [Support on Patreon](https://www.patreon.com/plugfox)
- [Subscribe through Boosty](https://boosty.to/plugfox) -->

<!-- We appreciate any form of support, whether it's a financial donation or just a star on GitHub. It helps us to continue developing and improving our library. Thank you for your support! -->

## License

Presentum is available under the [MIT License][license_link].

[pub_badge]: https://img.shields.io/pub/v/presentum.svg
[pub_link]: https://pub.dev/packages/presentum
[ci_badge]: https://github.com/itsezlife/presentum/actions/workflows/main.yaml/badge.svg?branch=master
[ci_link]: https://github.com/itsezlife/presentum/actions/workflows/main.yaml
[coverage_badge]: coverage_badge.svg
[coverage_link]: coverage/index.html
[flutter_install_link]: https://docs.flutter.dev/get-started/install
[github_actions_link]: https://docs.github.com/en/actions/learn-github-actions
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[linter_badge]: https://img.shields.io/badge/style-linter-40c4ff.svg
[linter_link]: https://pub.dev/packages/flutter_lints
