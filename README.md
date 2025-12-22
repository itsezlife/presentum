# Presentum

[![License: MIT][license_badge]][license_link]
[![Linter][linter_badge]][linter_link]
[![GitHub stars](https://img.shields.io/github/stars/itsezlife/presentum?style=social)](https://github.com/itsezlife/presentum/)

**Presentum** is a declarative Flutter engine for building dynamic, conditional UI at scale. It helps you manage campaigns, app updates, special offers, tips, and notifications with clean, testable, type-safe code.

Modern apps need personalized, adaptive experiences: show the right message to the right user at the right time, with impression limits, cooldowns, A/B testing, and analytics. Presentum handles this through declarative guards and rendering outlets.

## The problem

Most apps manage presentations by mixing logic across widgets and state managers:

```dart
// ❌ Logic spread everywhere, hard to test
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showBanner = false;
  Campaign? _campaign;

  @override
  void initState() {
    super.initState();
    _checkEligibility();
  }

  Future<void> _checkEligibility() async {
    final count = await prefs.getInt('banner_count') ?? 0;
    final lastShown = await prefs.getInt('banner_last_shown');

    if (count < 3 &&
        (lastShown == null ||
         DateTime.now().difference(
           DateTime.fromMillisecondsSinceEpoch(lastShown)
         ).inHours > 24)) {
      final campaign = await fetchCampaign();
      if (campaign != null && campaign.isActive && !userIsPremium) {
        setState(() {
          _showBanner = true;
          _campaign = campaign;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_showBanner && _campaign != null)
          BannerWidget(
            campaign: _campaign!,
            onClose: () => _handleDismiss(),
          ),
        // ...
      ],
    );
  }
}
```

This doesn't scale. With multiple presentation types, surfaces, eligibility rules, and A/B tests, complexity grows fast.

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
      if (lastShown != null) {
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

**Presentum handles ANY condition you need:**

- User segments (premium, free, trial)
- Geographic location (country, region, city)
- App version (force update for old versions)
- Device type (phone, tablet, platform)
- User behavior (purchase history, usage patterns)
- Time-based rules (holidays, business hours)
- A/B test groups
- Feature flags
- Custom business logic

The engine is flexible and scalable—if you can write a rule for it, Presentum can handle it.

## Core concepts

### Surfaces

**Where** presentations appear. Named locations in your UI:

```dart
enum AppSurface with PresentumSurface {
  homeTopBanner,      // Top of home screen
  watchlistHeader,    // Watchlist header area
  profileAlert,       // Profile page alert
}
```

### Payloads

**What** you want to show. Your domain objects:

```dart
class CampaignPayload extends PresentumPayload<AppSurface, CampaignVariant> {
  final String id;
  final int priority;
  final Map<String, Object?> metadata;
  final List<PresentumOption<AppSurface, CampaignVariant>> options;
}
```

### Options

**How** payloads appear, with constraints:

```dart
PresentumOption(
  surface: AppSurface.homeTopBanner,
  variant: CampaignVariant.banner,
  maxImpressions: 3,       // Show at most 3 times
  cooldownMinutes: 1440,   // Wait 24h between shows
  isDismissible: true,     // User can close it
)
```

### Guards

**When** to show. Your eligibility rules:

```dart
class CampaignGuard extends PresentumGuard<CampaignItem, AppSurface> {
  @override
  FutureOr<PresentumState<CampaignItem, AppSurface>> call(
    storage, history, state, candidates, context,
  ) async {
    // Apply your business logic here
    // Check user segments, A/B tests, feature flags, etc.
    return state;
  }
}
```

### Outlets

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

## Key features

- **Type-safe**: Generics ensure compile-time correctness
- **Predictable state**: Time-travel debugging and replay
- **Testable**: Mock storage, test guards independently
- **Eligibility engine**: Conditions, rules, metadata extractors
- **Tracking**: Impressions, dismissals, conversions
- **Lifecycle**: Monitor state transitions
- **Multi-surface**: Coordinate across multiple locations
- **Flexible storage**: SharedPreferences, SQLite, backend APIs

## Installation

Add Presentum to your `pubspec.yaml`:

```sh
dart pub add presentum
```

## Quick start

### 1. Define surfaces and variants

```dart
enum AppSurface with PresentumSurface {
  homeTopBanner,
  profileAlert;
}

enum CampaignVariant with PresentumVisualVariant {
  banner,
  dialog;
}
```

### 2. Create your payload

```dart
class CampaignPayload extends PresentumPayload<AppSurface, CampaignVariant> {
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
  final List<PresentumOption<AppSurface, CampaignVariant>> options;
}

typedef CampaignItem = PresentumItem<
  CampaignPayload,
  AppSurface,
  CampaignVariant
>;
```

### 3. Implement storage

```dart
class MyStorage implements PresentumStorage<AppSurface, CampaignVariant> {
  // Implement: recordShown, getShownCount, getLastShown,
  // recordDismissed, getDismissedAt, recordConverted, getConvertedAt
}
```

### 4. Create a guard

```dart
class CampaignGuard extends PresentumGuard<CampaignItem, AppSurface> {
  @override
  FutureOr<PresentumState<CampaignItem, AppSurface>> call(
    storage, history, state, candidates, context,
  ) async {
    for (final candidate in candidates) {
      if (await isEligible(candidate, storage)) {
        state.setActive(candidate.surface, candidate);
      }
    }
    return state;
  }
}
```

### 5. Initialize Presentum

```dart
final presentum = Presentum<CampaignItem, AppSurface>(
  storage: MyStorage(),
  guards: [CampaignGuard()],
);

// Wrap your app
presentum.config.engine.build(
  context,
  MaterialApp(home: HomeScreen()),
);
```

### 6. Create an outlet

```dart
class HomeTopBannerOutlet extends StatelessWidget {
  const HomeTopBannerOutlet({super.key});

  @override
  Widget build(BuildContext context) {
    return PresentumOutlet<CampaignItem, AppSurface>(
      surface: AppSurface.homeTopBanner,
      builder: (context, item) {
        return BannerWidget(
          title: item.metadata['title'],
          onClose: () => context
              .presentum<CampaignItem, AppSurface>()
              .markDismissed(item),
        );
      },
    );
  }
}
```

### 7. Render it

```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const HomeTopBannerOutlet(),
        // Your content...
      ],
    );
  }
}
```

### 8. Feed candidates

```dart
// From Firebase, API, local source, etc.
final campaigns = await fetchCampaigns();
final items = campaigns.map((c) => CampaignItem(
  payload: c,
  option: c.options.first,
)).toList();

// Feed to engine
await presentum.config.engine.setCandidates(
  (state, current) {
    // Use built-in diff helper or custom logic
    return DiffUtil.merge(current, items);
  },
);
```

## Advanced features

### Eligibility system

Build complex rules with conditions and extractors:

```dart
final rule = AndCondition([
  MetadataCondition(
    extractor: PathExtractor('/user/segment'),
    rule: EqualsRule('premium'),
  ),
  MetadataCondition(
    extractor: PathExtractor('/campaign/region'),
    rule: ContainsRule('US'),
  ),
]);

if (await rule.evaluate(item.metadata, storage)) {
  state.setActive(surface, item);
}
```

### Transition observers

Hook into lifecycle events:

```dart
class AnalyticsObserver extends PresentumTransitionObserver<Item, Surface> {
  @override
  Future<void> onAfterShown(item, surface) async {
    analytics.logImpression(item.id);
  }

  @override
  Future<void> onAfterConverted(item, surface) async {
    analytics.logConversion(item.id, item.metadata);
  }
}

presentum = Presentum(
  storage: storage,
  bindings: bindings,
  guards: guards,
  observers: [AnalyticsObserver()],
);
```

### Auto-tracking widgets

Widgets that automatically call `markShown`:

```dart
TrackedWidget(
  presentum: presentum,
  item: campaignItem,
  trackVisibility: true,
  builder: (context) => MyCampaignWidget(),
)
```

### Multi-surface composition

Merge items from multiple surfaces:

```dart
PresentumOutlet$Composition(
  surface: AppSurface.homeTopBanner,
  builder: (context, active, queue) {
    return Column(
      children: [
        if (active != null) ActiveWidget(active),
        ...queue.map((item) => QueuedWidget(item)),
      ],
    );
  },
)
```

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
