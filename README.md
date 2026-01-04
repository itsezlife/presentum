# [Presentum: A Declarative Presentation Engine for Flutter](https://docs.presentum.dev)

[![License: MIT][license_badge]][license_link]
[![Linter][linter_badge]][linter_link]
[![GitHub stars](https://img.shields.io/github/stars/itsezlife/presentum?style=social)](https://github.com/itsezlife/presentum/)

**Presentum** is a declarative Flutter engine for building dynamic, conditional UI at scale. It helps you manage campaigns, app updates, special offers, tips, notifications and so much more with clean, testable, type-safe code.

Modern apps need personalized, adaptive experiences: show the right message to the right user at the right time, with impression limits, cooldowns, A/B testing, and analytics. Presentum handles all of that.

Instead of spreading show/hide logic across your widgets, you describe **what** should be shown as data, and Presentum’s engine, guards, and outlets handle **where**, **when**, and **how** it appears.

**📚 [Full Documentation](https://docs.presentum.dev)** · **🚀 [Quick Start](https://docs.presentum.dev/quickstart)**

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

Presentum separates **what** (payloads), **when** (guards), **where** (surfaces), and **how** (outlets):

```dart
// ✅ Declarative, testable, maintainable

// 1. Define domain data
class CampaignPayload extends PresentumPayload<AppSurface, CampaignVariant> {
  final String id;
  final int priority;
  final Map<String, Object?> metadata;
  final List<PresentumOption<AppSurface, CampaignVariant>> options;
  // Extend as needed, add whatever else you might need...
}

// 2. Define logic in guards
class CampaignGuard extends PresentumGuard<CampaignItem, AppSurface> {
  @override
  FutureOr<PresentumState<CampaignItem, AppSurface>> call(
    storage, history, state, candidates, context,
  ) async {
    for (final candidate in candidates) {
      // Check impression count
      final count = await storage.getShownCount(
        candidate.id,
        surface: candidate.surface,
        variant: candidate.variant,
      );
      if (count >= 3) continue;

      // Check cooldown
      final lastShown = await storage.getLastShown(
        candidate.id,
        surface: candidate.surface,
        variant: candidate.variant,
      );
      if (lastShown case final lastShown?) {
        final hoursSince = DateTime.now().difference(lastShown).inHours;
        if (hoursSince < candidate.cooldownHours) continue;
      }

      // Check user eligibility
      if (!await _isEligible(candidate)) continue;

      // All checks passed
      state.setActive(candidate.surface, candidate);
    }
    return state;
  }
}

// 3. Display widget with built-in outlet
class HomeTopBannerOutlet extends StatelessWidget {
  const HomeTopBannerOutlet({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PresentumOutlet<CampaignItem, AppSurface>(
      surface: AppSurface.homeTopBanner,
      builder: (context, item) {
        return BannerWidget(
          campaign: item.payload,
          onClose: () => context
              .presentum<CampaignItem, AppSurface>()
              .markDismissed(item),
        );
      },
    );
  }
}
```

**All eligibility logic is centralized.** The outlet renders. The payload is data. Guards contain business rules. Everything is testable.

## How it works

Presentum coordinates the flow between your data sources, eligibility rules, and UI:

1. **Data Fetching**: Your app fetches candidates from Supabase, Firebase Remote config, APIs, or local sources
2. **Engine Processing**: The Presentum Engine receives candidates and runs eligibility checks through guards
3. **State Management**: Engine updates state, manages slots per surface, and tracks history/transitions
4. **UI Rendering**: Outlets render active items based on current state
5. **User Interaction**: Users interact with presented items (dismiss, convert, etc.)
6. **Event Recording**: Storage layer records all user interactions and state changes
7. **Re-evaluation**: Guards re-evaluate eligibility as needed based on new data or interactions

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

The engine is flexible and scalable - if you can write a rule for it, Presentum can handle it.
The only limit is your imagination.

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
      surface: surface,
      builder: (context, item) {
        return MyWidget(item);
      },
    );
  }
}
```

[Example: Popup host for dialog presentations](https://github.com/itsezlife/presentum/blob/master/example/lib/src/campaigns/presentum/widgets/campaign_popup_host.dart)

## [How to present](https://docs.presentum.dev/guides/state-management)

Use the `context.presentum.setState((state) => ...)` method as a basic presentum method.

And realize any presentum logic inside the callback as you please.

```dart
context.presentum.setState((state) {
  state.setActive(AppSurface.homeTopBanner, campaignItem);
  state.enqueue(AppSurface.profileAlert, alertItem);
  return state;
});
```

You can truly do anything you want.
Just change the state, slots, active items, and queues as you please.
Everything is in your hands and just works fine, that's a declarative approach as it should be.

However, guards should be your primary tool for scheduling presentations, removing ineligible items, periodic refreshes, and complex eligibility rules. Use direct state changes when you need a very explicit controll.

## [Guards](https://docs.presentum.dev/core-concepts/guards)

Guards are a powerful tool for controlling presentations.
They allow you to check the state and mutate/filter items based on eligibility rules.
For example, you can check user preferences, storage, history, impression limits, cooldowns, or A/B test segments to determine what should be shown.

**Examples:**

1. [Scheduling guard with priority and sequencing](https://github.com/itsezlife/presentum/blob/master/example/lib/src/campaigns/presentum/guards/scheduling_guard.dart)
2. [Remove ineligible campaigns guard](https://github.com/itsezlife/presentum/blob/master/example/lib/src/common/presentum/remove_ineligible_candidates_guard.dart)
3. [Sync state with candidates guard](https://github.com/itsezlife/presentum/blob/master/example/lib/src/common/presentum/sync_state_with_candidates_guard.dart)

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

## [Transition observers](https://docs.presentum.dev/features/transition-observers)

React to state changes with comprehensive diff snapshots. Useful for integrating with BLoC, Provider, or other state management:

```dart
class StateChangeObserver implements IPresentumTransitionObserver<Item, Surface, Variant> {
  StateChangeObserver(this.bloc);

  final MyBloc bloc;

  @override
  FutureOr<void> call(PresentumStateTransition<Item, Surface, Variant> transition) {
    final diff = transition.diff;

    // Fire events to your business logic layer
    for (final change in diff.activated) {
      bloc.add(PresentationActivated(change.item, change.surface));
    }

    for (final change in diff.deactivated) {
      bloc.add(PresentationDeactivated(change.item, change.surface));
    }

    for (final change in diff.queued) {
      bloc.add(PresentationQueued(change.item, change.surface));
    }
  }
}

presentum = Presentum(
  storage: storage,
  guards: guards,
  transitionObservers: [StateChangeObserver(myBloc)],
);
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

// Register event handlers
presentum = Presentum(
  storage: storage,
  guards: guards,
  eventHandlers: [
    PresentumStorageEventHandler(storage: storage), // Built-in storage handler
    AnalyticsEventHandler(analyticsService),
    // Add more handlers as needed
  ],
);

// Manually add custom events
await context.presentum.addEvent(MyCustomEvent(item: item, timestamp: DateTime.now()));
```

## [Auto-tracking widgets](https://docs.presentum.dev/features/auto-tracking)

Widgets that automatically call `markShown` when widget renders and persists
`showed` value in `PageStorage` to prevent any redundant calls:

```dart
TrackedWidget(
  presentum: presentum,
  item: campaignItem,
  trackVisibility: true,
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

This happens automatically via `state.clearActive(surface)` or when you call `context.presentum.markDismissed(item)`.

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
