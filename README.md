# [Presentum: Conditional UI for Flutter](https://docs.presentum.dev)

[![License: MIT][license_badge]][license_link]
[![Linter][linter_badge]][linter_link]
[![GitHub stars](https://img.shields.io/github/stars/itsezlife/presentum?style=social)](https://github.com/itsezlife/presentum/)

**Presentum** is a Flutter **domain library** for building dynamic, conditional UI at scale — campaigns, app updates, maintenance, banners, popups, and more. It provides typed payloads, slot state, eligibility, storage contracts, pipeline steps, and slot-driven widgets.

**Your controller owns reactive state.** Presentum does not ship a runtime engine, global instance, or `context.presentum()`. You hold `PresentumSlotState` and `PresentumSlotsHistory`, run a `PresentumStepsPipeline` when inputs change, and bind slots to `PresentumOutlet` / `PresentumPopupHost`.

> **v1 migration:** The repo targets **v1.0.0** (breaking). Published docs at [docs.presentum.dev](https://docs.presentum.dev) still describe v0.3.6.
**📚 [Published docs (v0.3.6)](https://docs.presentum.dev)** · **🚀 [Example app (v1)](example/)**

## The problem

Managing presentations imperatively with repetitive show/hide logic creates boilerplate and doesn't scale:

```dart
// ❌ Imperative approach: scattered logic, repetitive patterns, hard to test
class PresentationService {
  Campaign? _activeCampaign;
  AppUpdate? _activeUpdate;

  Future<Campaign?> checkCampaign() async {
    final count = await prefs.getInt('campaign_count') ?? 0;
    final lastShown = await prefs.getInt('campaign_last_shown');

    if (count < 3 && (lastShown == null ||
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastShown)).inHours > 24)) {
      final campaign = await fetchCampaign();
      if (campaign != null && campaign.isActive && !userIsPremium) {
        _activeCampaign = campaign;
        await prefs.setInt('campaign_count', count + 1);
        return campaign;
      }
    }
    return null;
  }

  Future<AppUpdate?> checkUpdate() async {
    final dismissed = await prefs.getBool('update_dismissed') ?? false;
    if (!dismissed) {
      final update = await fetchUpdate();
      if (update != null && update.isRequired) {
        _activeUpdate = update;
        return update;
      }
    }
    return null;
  }

  // What shows first? How do we prioritize?
  // This logic gets duplicated across every screen...
}
```

**The imperative approach creates systemic issues:** eligibility checks scattered across widgets, impression tracking duplicated everywhere, testing requires mocking widget lifecycle for each case, and coordinating multiple competing presentations becomes a maintenance burden. With multiple presentation types, surfaces, eligibility rules, and A/B tests, this complexity compounds rapidly.

## The solution

Presentum separates **what** (payloads), **when** (pipeline steps), **where** (surfaces), and **how** (outlets):

```dart
// ✅ Domain library + host controller (v1)

// 1. Domain data
class CampaignPayload extends PresentumPayload<AppSurface, CampaignVariant> { … }

// 2. Scheduling in a pipeline step (replaces guards)
class CampaignSchedulingStep extends PresentumResolverStep<CampaignItem, …> {
  @override
  Future<PresentumSlotState<…>> call(PresentumStepInput<…> input) async {
    var slots = input.current;
    for (final candidate in input.candidates) {
      if (!await _isEligible(candidate, input)) continue;
      slots = slots.withActive(candidate.surface, candidate);
    }
    return slots;
  }
}

// 3. Controller owns slots; outlet receives them
class CampaignOutlet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.controllerOf<CampaignsController>();
    return ValueListenableBuilder(
      valueListenable: controller.select((s) => s.slots),
      builder: (context, slots, _) => PresentumOutlet(
        slots: slots,
        surface: AppSurface.homeTopBanner,
        builder: (context, item) => BannerWidget(
          campaign: item.payload,
          onClose: () => controller.markDismissed(item),
        ),
      ),
    );
  }
}
```

**Business rules live in steps and eligibility.** Slots are immutable snapshots. The host decides when to revalidate.

## How it works

1. **Fetch candidates** from remote config, APIs, or local sources
2. **Listen** to lifecycle, config, or user streams → `controller.revalidate()`
3. **Pipeline** runs custom steps → returns new `PresentumSlotState`
4. **History** records each commit for step gates and debugging
5. **Outlets / popup host** render active items from `slots`
6. **Lifecycle** (`PresentumLifecycle.shown` / `.dismiss`) updates storage and handlers

## What you can build

This, and so much more:

<table>
<tr>
<td width="50%">

**App updates & maintenance**

- Force update dialogs (Shorebird, CodePush)
- Optional update prompts
- Maintenance mode notices
- Changelog announcements

</td>
<td width="50%">

**Marketing & promotions**

- Special offers with discount codes
- Limited-time sales
- Seasonal campaigns
- Multi-variant A/B tests

</td>
</tr>
<tr>
<td>

**User onboarding**

- Feature discovery tips
- Contextual tutorials
- Progressive disclosure
- Completion tracking

</td>
<td>

**In-app messaging**

- User-specific promotions
- Survey requests
- Upgrade prompts for premium features
- Time-sensitive alerts

</td>
</tr>
</table>

Presentum handles ANY condition you need:

- User segments (premium, free, trial)
- Geographic location (country, region, city)
- App version (force update for old versions)
- Device type (phone, tablet, platform)
- OS type (iPhone, Android, Web)
- User behavior (purchase history, usage patterns)
- Time-based rules (holidays, business hours)
- A/B test groups
- Feature flags (is_active)
- Custom business logic

The library is flexible and composable — if you can express a rule in a step or eligibility condition, Presentum can support it.

## [Installation](https://docs.presentum.dev/installation)

Add Presentum to your `pubspec.yaml`:

```sh
dart pub add presentum
```

## [Core concepts](https://docs.presentum.dev/core-concepts/overview)

### [Surfaces](https://docs.presentum.dev/core-concepts/surfaces)

**Where** presentations appear. Named locations in your UI:

```dart
enum AppSurface with PresentumSurface {
  homeTopBanner,      // Top of home screen
  watchlistHeader,    // Watchlist header area
  profileAlert,       // Profile page alert
  popup,              // Modal overlay dialogs
}
```

### [Payloads](https://docs.presentum.dev/core-concepts/payloads-options-items)

**What** you want to show. Your domain objects:

```dart
class CampaignPayload extends PresentumPayload<AppSurface, CampaignVariant> {
  final String id;
  final int priority;
  final Map<String, Object?> metadata;
  final List<PresentumOption<AppSurface, CampaignVariant>> options;
}
```

[Example: Production campaign payload with JSON serialization](https://github.com/itsezlife/presentum/blob/master/example/lib/src/campaigns/presentum/payload.dart)

### [Options](https://docs.presentum.dev/core-concepts/payloads-options-items)

**How** payloads appear, with constraints:

```dart
class CampaignPresentumOption
    extends PresentumOption<CampaignSurface, CampaignVariant> {
  final CampaignSurface surface;
  final CampaignVariant variant;
  final bool isDismissible;
  final int? stage;
  final int? maxImpressions;
  final int? cooldownMinutes;
  final bool alwaysOnIfEligible;
}

CampaignPresentumOption(
  surface: AppSurface.homeTopBanner,
  variant: CampaignVariant.banner,
  maxImpressions: 3,       // Show at most 3 times
  cooldownMinutes: 1440,   // Wait 24h between shows
  isDismissible: true,     // User can close it
)
```

### [Outlets](https://docs.presentum.dev/core-concepts/outlets)

**Rendering** widgets. Just UI code:

```dart
class MyOutlet extends StatelessWidget {
  const MyOutlet({
    required this.surface,
    super.key,
  });

  final MySurface surface;

  @override
  Widget build(BuildContext context) {
    return PresentumOutlet<MyItem, MySurface>(
      slots: mySlots, // from your controller state
      surface: surface,
      builder: (context, item) => MyWidget(item),
    );
  }
}
```

[Example: Campaign popup host](https://github.com/itsezlife/presentum/blob/master/example/lib/src/campaigns/widgets/campaign_popup_host.dart)

## Pipeline steps (replaces guards)

Port guard logic into `PresentumResolverStep` implementations and register them on a `PresentumStepsPipeline`. The host calls the pipeline on revalidation:

```dart
final newSlots = await _pipeline(
  candidates: state.candidates,
  context: await _buildContext(),
  current: state.slots,
  history: state.history,
);
setState(state.copyWith(
  slots: newSlots,
  history: state.history.record(slots: newSlots, current: state.slots),
));
```

**Example steps:**

1. [Campaign scheduling](https://github.com/itsezlife/presentum/blob/master/example/lib/src/campaigns/presentum/steps/campaign_scheduling_step.dart)
2. [Remove ineligible campaigns](https://github.com/itsezlife/presentum/blob/master/example/lib/src/campaigns/presentum/steps/remove_ineligible_campaigns_step.dart)
3. [Sync slots with candidates](https://github.com/itsezlife/presentum/blob/master/example/lib/src/campaigns/presentum/steps/sync_campaigns_slots_step.dart)

## [Eligibility system](https://docs.presentum.dev/features/eligibility-system)

Build complex eligibility checks using conditions, rules, and extractors:

```dart
// Define eligibility conditions
final eligibility = AllOfEligibility(conditions: [
  TimeRangeEligibility(
    start: DateTime(2025, 1, 1),
    end: DateTime(2025, 12, 31),
  ),
  AnySegmentEligibility(
    contextKey: 'user_segments',
    requiredSegments: {'premium', 'verified'},
  ),
  NumericComparisonEligibility(
    contextKey: 'app_version',
    comparison: NumericComparison.greaterThanOrEqual,
    threshold: 2.0,
  ),
]);

// Create resolver with standard rules
final resolver = DefaultEligibilityResolver(
  rules: createStandardRules(),
  extractors: [
    TimeRangeExtractor(),
    AnySegmentExtractor(),
    NumericComparisonExtractor(),
  ],
);

// Evaluate in your guard
final context = {
  'user_segments': {'premium', 'trial'},
  'app_version': 2.1,
};

final isEligible = await resolver.isEligible(candidate.payload, context);
if (isEligible) {
  state.setActive(candidate.surface, candidate);
}
```

## Transition diffs

Compare slot snapshots with `PresentumSlotsTransition` / `PresentumSlotsDiff` after a pipeline commit — useful for analytics or cross-domain coordination:

```dart
final transition = PresentumSlotsTransition(
  before: previousSlots,
  after: newSlots,
);
for (final change in transition.diff.activated) {
  analytics.logActivated(change.item.id, change.surface);
}
```

## [Event system](https://docs.presentum.dev/features/events)

Capture user interactions with a flexible event system:

```dart
// Built-in events: PresentumShownEvent, PresentumDismissedEvent, PresentumConvertedEvent

// Create custom event handlers
class AnalyticsEventHandler implements IPresentumEventHandler<Item, Surface, Variant> {
  AnalyticsEventHandler(this.analytics);

  final AnalyticsService analytics;

  @override
  FutureOr<void> call(PresentumEvent<Item, Surface, Variant> event) {
    switch (event) {
      case PresentumShownEvent(:final item, :final timestamp):
        analytics.logImpression(item.id, timestamp);
      case PresentumDismissedEvent(:final item, :final timestamp):
        analytics.logDismissal(item.id, timestamp);
      case PresentumConvertedEvent(:final item, :final timestamp, :final conversionMetadata):
        analytics.logConversion(item.id, timestamp, conversionMetadata);
    }
  }
}

// Wire handlers into PresentumLifecycle
final lifecycle = PresentumLifecycle(
  storage: storage,
  handlers: [
    PresentumStorageEventHandler(storage: storage),
    PresentumAnalyticsEventHandler(analytics: analyticsService),
  ],
);

await lifecycle.dismiss(slots: slots, item: item, updateSlots: controller.markDismissed);
```

## [Auto-tracking widgets](https://docs.presentum.dev/features/auto-tracking)

Widgets that automatically call `markShown` when widget renders and persists
`showed` value in `PageStorage` to prevent any redundant calls:

```dart
PresentumTrackedWidget(
  item: campaignItem,
  onShown: () => controller.markShown(campaignItem),
  builder: (context) => MyCampaignWidget(),
)
```

## [State structure](https://docs.presentum.dev/core-concepts/slots-state)

Under the hood, Presentum manages state as a map of **slots**, where each slot represents one surface in your app.

Imagine you have three surfaces in your app showing different presentations:

```
homeTopBanner
├─ active: Campaign "Black Friday Sale" (priority: 100)
└─ queue: [
     Campaign "New Year Promo" (priority: 80),
     Tip "Swipe to refresh" (priority: 50)
   ]

profileAlert
├─ active: AppUpdate "Version 2.0 Available" (priority: 200)
└─ queue: []

settingsNotice
├─ active: null
└─ queue: [
     Tip "Enable notifications" (priority: 60)
   ]
```

Let's create the following state to represent our expectations:

```dart
final state = PresentumState$Immutable<CampaignItem, AppSurface, CampaignVariant>(
  intention: PresentumStateIntention.auto,
  slots: {
    AppSurface.homeTopBanner: PresentumSlot(
      surface: AppSurface.homeTopBanner,
      active: CampaignItem(
        payload: CampaignPayload(
          id: 'black-friday-2025',
          priority: 100,
          metadata: {
            'title': 'Black Friday Sale',
            'discount': '50%',
            'expiresAt': '2025-11-30T23:59:59Z',
          },
          options: [
            CampaignOption(
              surface: AppSurface.homeTopBanner,
              variant: CampaignVariant.banner,
              maxImpressions: 5,
              cooldownMinutes: 1440,
              isDismissible: true,
            ),
          ],
        ),
        option: CampaignOption(/* ... */),
      ),
      queue: [
        CampaignItem(
          payload: CampaignPayload(
            id: 'new-year-promo-2026',
            priority: 80,
            metadata: {
              'title': 'New Year Promo',
              'discount': '30%',
            },
            options: [/* ... */],
          ),
          option: CampaignOption(/* ... */),
        ),
        TipItem(
          payload: TipPayload(
            id: 'tip-swipe-refresh',
            priority: 50,
            metadata: {
              'title': 'Swipe to refresh',
              'description': 'Pull down to see latest updates',
            },
            options: [/* ... */],
          ),
          option: TipOption(/* ... */),
        ),
      ],
    ),
    AppSurface.profileAlert: PresentumSlot(
      surface: AppSurface.profileAlert,
      active: AppUpdateItem(
        payload: AppUpdatePayload(
          id: 'app-update-2.0',
          priority: 200,
          metadata: {
            'version': '2.0.0',
            'isForced': false,
            'releaseNotes': 'New features and improvements',
          },
          options: [/* ... */],
        ),
        option: AppUpdateOption(/* ... */),
      ),
      queue: [],
    ),
    AppSurface.settingsNotice: PresentumSlot(
      surface: AppSurface.settingsNotice,
      active: null,  // Nothing currently shown
      queue: [
        TipItem(
          payload: TipPayload(
            id: 'tip-enable-notifications',
            priority: 60,
            metadata: {
              'title': 'Enable notifications',
              'description': 'Stay updated with important alerts',
            },
            options: [/* ... */],
          ),
          option: TipOption(/* ... */),
        ),
      ],
    ),
  },
);
```

Each slot is a container for one surface with:

```dart
PresentumSlot<TItem, S, V> {
  final S surface;           // Where it appears
  final TItem? active;       // What's showing now
  final List<TItem> queue;   // What's waiting
}
```

When you dismiss the active item, the next queued item automatically becomes active:

Before dismissing an item:

```
homeTopBanner
├─ active: "Black Friday Sale"
└─ queue: ["New Year Promo", "Swipe to refresh"]
```

After dismissing or ineligibility removal:

```
homeTopBanner
├─ active: "New Year Promo"  <- Promoted from queue
└─ queue: ["Swipe to refresh"]
```

This happens via `PresentumSlotState.withDismissed` or `PresentumLifecycle.dismiss` from your controller.

## Changelog

See [CHANGELOG.md](https://github.com/itsezlife/presentum/blob/master/CHANGELOG.md) for release notes.

## License

MIT License. See [LICENSE](LICENSE) for details.

## Maintainers

- [Emil Zulufov](https://ezit.vercel.app) ([@itsezlife](https://github.com/itsezlife))

---

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[linter_badge]: https://img.shields.io/badge/style-linter-40c4ff.svg
[linter_link]: https://pub.dev/packages/flutter_lints
