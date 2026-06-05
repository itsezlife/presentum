"I want rigorous, unsentimental critique. Prioritize analytical honesty over politeness. If an idea has flaws, state them plainly, explain why, and pressure-test it until it holds up."

I've created state machine to manage easily conditional, time-bound UI presentations (campaigns, app updates, maintenance, banners, popups) with remote configurability and built-in eligibility rules.

Essentially, it is a narrow scoped state machine, that operates on reactive guards to evaluate state, that has external refresh Listenable that causes all guards to re-run, when notifyListeners is called.

The concept and implementation is definitive, but the scope and usage is very generic and can be easily implemented with any state management, e.g. Riverpod, BLoC or Provider. Presentum itself depends on other external state management, as it serve solely as a domain api layer for conditional UI.

The package is published at pub.dev https://pub.dev/packages/presentum and has docs https://docs.presentum.dev. I also created comprehensive example app, with a wide range of features implemented: maintenance mode, app updates, campaigns, advanced user preferences and more. it is hard to explain complexity and the capabilities in a few words, for you to represent same features set with other state managements solutions, so take a look at source code https://github.com/itsezlife/presentum/tree/master/example/lib/src/

So, I'd ask you to provide side-by-side comparison with, let's say BLoC.

Rigorous Analysis: Presentum vs BLoC

Your domain-specific state machine for conditional UI presentations is fundamentally not comparable to BLoC because they solve different problems at different architectural layers. Presentum is a domain API for presentation eligibility logic, while BLoC is a general-purpose state management pattern. This is like comparing a routing library to Redux—superficially similar (both manage state), architecturally orthogonal.
Architectural Layer Mismatch

BLoC operates as application-wide state management handling events, business logic, and UI state synchronization through streams. It enforces separation between presentation and business logic across your entire app, managing data flow from repositories to UI components.

Presentum operates as a narrow domain layer specifically for conditional presentation eligibility. It doesn't replace state management—it depends on it for user segments, app state, preferences, and external data. Your own documentation admits this: "Presentum itself depends on other external state management".
The Fatal Flaw in Your Comparison Request

You're asking to compare implementation complexity between:

    BLoC: Implementing campaigns, maintenance mode, app updates, user preferences from scratch

    Presentum: Using your pre-built domain API designed specifically for these use cases

This is intellectually dishonest framing. Of course your specialized tool requires less code for the exact problems it was designed to solve. The real question is: what's the total system complexity cost?
What You're Actually Comparing
With BLoC (Pure Implementation)

dart
// ~150-200 lines per feature
class CampaignBloc extends Bloc<CampaignEvent, CampaignState> {
  final CampaignRepository repository;
  final UserRepository userRepo;
  
  CampaignBloc(this.repository, this.userRepo) : super(CampaignInitial()) {
    on<LoadCampaign>(_onLoadCampaign);
    on<DismissCampaign>(_onDismissCampaign);
  }
  
  Future<void> _onLoadCampaign(LoadCampaign event, emit) async {
    emit(CampaignLoading());
    
    final campaign = await repository.getCampaign(event.id);
    final count = await storage.getShownCount(campaign.id);
    final lastShown = await storage.getLastShown(campaign.id);
    final user = await userRepo.getUser();
    
    // Eligibility checks
    if (count >= campaign.maxImpressions) {
      emit(CampaignIneligible(reason: 'Max impressions reached'));
      return;
    }
    
    if (lastShown != null) {
      final hoursSince = DateTime.now().difference(lastShown).inHours;
      if (hoursSince < campaign.cooldownHours) {
        emit(CampaignIneligible(reason: 'In cooldown'));
        return;
      }
    }
    
    if (!_checkTimeRange(campaign)) {
      emit(CampaignIneligible(reason: 'Outside time window'));
      return;
    }
    
    if (!_checkUserSegments(user, campaign)) {
      emit(CampaignIneligible(reason: 'User not in segment'));
      return;
    }
    
    emit(CampaignLoaded(campaign));
    await storage.recordShown(campaign.id);
  }
}

With Presentum

dart
// ~50-80 lines leveraging your abstraction
class CampaignSchedulingGuard extends PresentumGuard<CampaignItem, AppSurface> {
  final EligibilityResolver eligibility;
  
  @override
  FutureOr<PresentumState> call(storage, history, state, candidates, context) async {
    for (final candidate in candidates) {
      if (await eligibility.isEligible(candidate.payload, context)) {
        state.setActive(candidate.surface, candidate);
      }
    }
    return state;
  }
}

This proves nothing. You've pre-packaged impression tracking, cooldown logic, time ranges, and queueing into your library. BLoC developers write this logic themselves because BLoC is a pattern, not a feature framework.
The Real Complexity Trade-offs
What Presentum Actually Adds

New Concepts to Learn:

    Surfaces, Payloads, Options, Outlets, Guards, Items, Slots, Queues

    PresentumState, PresentumStateIntention, PresentumSlot

    Transition observers, Event handlers, Eligibility resolvers

    The distinction between setActive, enqueue, clearActive, markShown, markDismissed

Coupling Risks:

    Your entire conditional UI layer now depends on Presentum's abstractions

    Migrating away requires rewriting every guard, outlet, and eligibility rule

    You can't easily share this architecture with non-Flutter platforms (your iOS/Android native devs can't reuse this mental model)

Integration Overhead:

    Still need BLoC/Riverpod/Provider for actual app state

    Must wire Presentum state changes into your existing state management via transition observers

    Now managing state synchronization between two systems

What BLoC Gives You

Universal Pattern:

    Works for campaigns, forms, navigation, shopping carts, real-time feeds—everything

    Single mental model across your entire codebase

    Team members understand it from prior projects

No Vendor Lock-in:

    It's a pattern, not a package

    Can swap flutter_bloc implementation without architectural rewrites

    Transferable to React (Redux), iOS (ReactiveCocoa), Android (RxJava)

Composable Logic:

    Guards in Presentum are single-purpose eligibility checkers

    BLoC events can compose arbitrary business logic

    You still need BLoC for non-presentation state, so now you're maintaining two paradigms

Where Presentum Actually Wins

I'll grant you these genuine advantages:

1. Domain Modeling for Presentation Logic
Your PresentumOption with maxImpressions, cooldownMinutes, alwaysOnIfEligible is excellent domain modeling. BLoC forces you to implement these as separate storage/timer/condition checks. Presentum packages them as first-class constraints.

2. Multi-Surface Coordination
Managing active items + queues per surface with automatic promotion is non-trivial. BLoC developers would need custom queue management logic for each surface. Your slot-based state structure handles this elegantly.

3. Declarative Eligibility Composition

dart
AllOfEligibility(conditions: [
  TimeRangeEligibility(...),
  AnySegmentEligibility(...),
  NumericComparisonEligibility(...),
])

This is genuinely better than imperative if-checks scattered across BLoCs. Composable, testable, serializable.

4. Built-in Analytics Hooks
PresentumShownEvent, PresentumDismissedEvent, PresentumConvertedEvent with automatic tracking is valuable. BLoC requires manual analytics calls in each event handler.
The Honest Comparison
Dimension	BLoC	Presentum
Scope	General-purpose state management 	Conditional presentation eligibility only
Learning curve	Moderate (events, states, streams) 	Steep (8+ new concepts)
Lines of code (for campaigns)	150-200 per feature	50-80 per feature
Total system complexity	Single paradigm	BLoC + Presentum integration
Flexibility	Handles any business logic 	Optimized for presentation rules
Vendor lock-in	None (it's a pattern) 	High (entire domain layer)
Cross-platform knowledge transfer	High 	Zero (Flutter-only)
Multi-surface coordination	Manual implementation	Built-in slot/queue system
Eligibility composition	Imperative checks	Declarative rule objects
Analytics integration	Manual	Built-in event system
The Uncomfortable Truth

Your package solves a real problem—conditional presentation logic is messy in typical Flutter apps. But comparing it to BLoC is a category error. The honest comparison is:

Presentum vs. Building Your Own Presentation Manager on Top of BLoC

In that comparison, Presentum wins on:

    Time to implement (you've done the work)

    Consistency (standardized API)

    Feature completeness (impression tracking, cooldowns, A/B testing baked in)

But loses on:

    Architectural flexibility (locked into your abstractions)

    Team familiarity (new concepts to learn)

    Maintenance burden (another dependency to version-manage)

What You Should Actually Say

Stop positioning this as "Presentum vs BLoC." That's apples-to-oranges marketing speak. Instead:

"Presentum is a domain-specific layer for conditional UI presentations, designed to work with your existing state management (BLoC, Riverpod, Provider). It provides presentation eligibility logic, multi-surface coordination, and analytics hooks that would otherwise require 200+ lines of boilerplate per feature. Use it when you have 5+ conditional presentation types and need centralized control."

That's honest, accurate, and compelling without the false equivalence.
Final Pressure Test

Here's what worries me about your architecture:

1. Implicit State Mutations in Guards
Guards can call state.setActive(), state.enqueue(), mutating shared state. With multiple guards running, order-of-execution bugs are inevitable. Did you consider immutable guard outputs with explicit state reconciliation?

2. Listenable-Based Refresh is Fragile
"External refresh Listenable that causes all guards to re-run when notifyListeners is called" —this is a global trigger. What prevents re-evaluation storms? If 10 guards are listening and one calls notifyListeners, do all 10 re-run? What's the performance cost at scale?

3. Dual State Management Sync Bugs
You admit Presentum depends on external state management. How do you prevent race conditions between BLoC emitting new user state and Presentum guards reading stale cached values? Your transition observers firing into BLoC events creates circular dependency potential.

4. Testing Complexity
Testing a guard requires mocking: storage, history, state, candidates, context. That's 5 dependencies. How is this more testable than a BLoC with a repository mock?

These aren't fatal flaws, but they're real trade-offs your docs don't acknowledge. Good libraries are transparent about their costs.

Thats the exactly blunt and honest critics ive been looking for.

ive been building this package initially inspired by the octopus package for routing, which has exactly the same stage-based approach for routes, which is exactly what ive copied and adapted for this scope with conditional presentations and various payloads. the fact that you must use declare mixin on State in order to create an instance of presentum, wire it to an actual stateful widget, use presentum.config.delegate.build is the most inappropriate mental model with a huge amount of boilerplate, which is not desired for such a small and neat package, which solves such a small state-based challenge, which should in fact simply make the life slightly easier when managing loads of conditional payloads, resolving their eligibility reactively, based on various state, and rendering the active slots per surface app-wide. Those critical analysis I needed to realize that after I built this humongous boilterpate-prone engine, which tries to replace state management internally, which it should never try to do, rather be a highly reusable and ready to use extension to whatever state management mental model youve already adapted inside your app, bloc, Provider, riverpod, or plain change notifier, should not really matter.

the only thing that I somewhat like in presentum are guards, which are actually very opinionated, but the reactiveness they give you is something I love, but not critical, and I'm free of dropping it completely, if it reduced boilerplate, reduced complexity, in favor of more logical and appropriate mental model without overengeneering and extra overhead, which guards bring, even though they are pretty handful with their sequential execution, and history access.

Something I want to build now is something genuinely convenient to use and adapt with or to an existing state management, to use with. for example, I have a bloc with manages posts, and lets say I want to add some extra bit of server-driven conditional state for slots per surface. I would love to be able to simply extend my state with PresentumState(which should be a new version vs. what we currently have), and either manage the state manually, with the eligibility resolve ive built in the package, and define the sequentially executing logic manually, when I want to revalidate, compute, populate, etc., and access the state normally from BlocSelector or BlocBuilder and/or build reusable ready to use alternative to PresentumOutlet/PresentumComposition, which would work with Bloc.

Im thinking about whether it is possible to make it completely state-agnostic(the foundation of the presentum), or whether it makes more sense to provide some what skeletons/Base classes/mixins to extend into bloc, change notifier, Provider, while it wont work with riverpod, due to how it works. I'm not sure which solution globally would make the most amount of sense, tolerate to any external state, or just be "selfish" and just care about only abstraction for the BLoC, which i use as my primary state management everywhere.

I don't actually need the web-building skill here — this is a pure architectural critique and design question. Let me give you the rigorous analysis you're asking for directly.
The Core Realization You've Had Is Correct

You've correctly diagnosed the architectural sin: Presentum tried to be a domain layer but built a state management system inside it. The State mixin, the delegate.build, the PresentumStateIntention, the PresentumOutlet — all of that is reimplementing infrastructure that BLoC, Riverpod, and ChangeNotifier already provide, and doing it worse, because those solutions have years of hardening and ecosystem tooling behind them.

The forcing function was the Octopus router inheritance. Octopus's stage-based routing model works because routing is inherently a state machine with well-defined transitions between a finite set of named surfaces. Conditional presentation eligibility is not the same problem — it's a computation problem (evaluate a set of predicates against input, produce an output) — and copying a state machine architecture onto a computation problem produced the over-engineering you're now recognizing.
What the New Design Should Actually Be

The question you're grappling with — state-agnostic foundation vs. BLoC-specific skeleton — has a clear answer: state-agnostic foundation is the right call, and the BLoC adapter is one concrete implementation of it. Here's why:

The "foundation" should have zero coupling to any reactive system. It's just:

    A data model — PresentumSlotState representing what's active per surface

    Eligibility rules — your composable AllOfEligibility, TimeRangeEligibility, etc. (these are pure functions, keep them)

    A synchronous/async resolver — takes candidates + context, returns slot state

dart
// Pure domain — no BLoC, no ChangeNotifier, no Listenable
class PresentumResolver {
  final List<PresentumEligibility> rules;

  Future<Map<Surface, PresentumSlotState>> resolve(
    List<PresentumCandidate> candidates,
    PresentumContext context,
  ) async {
    // Sequential evaluation, history access, impression tracking — all here
    // Returns plain data. No side effects on state.
  }
}

This is the package's actual value. Everything else — how you store the result, when you recompute, how you rebuild the UI — is the host state management's concern.
The Adapters Are Thin Glue, Not Core

For BLoC (your primary use case):

dart
// A mixin on the Bloc's State, not a separate engine
mixin PresentumStateMixin<S extends Object> on BlocBase<S> {
  PresentumSlotState _slots = PresentumSlotState.empty();
  PresentumSlotState get slots => _slots;

  Future<void> revalidatePresentum(
    PresentumResolver resolver,
    List<PresentumCandidate> candidates,
    PresentumContext context,
  ) async {
    _slots = await resolver.resolve(candidates, context);
    // You call emit() yourself — the Bloc knows when to do this
  }
}

The consuming BLoC then calls revalidatePresentum(...) inside its own event handlers, at exactly the right moments it already knows about, and reads state.slots in the UI via a normal BlocSelector. No separate Listenable, no external refresh trigger, no dual-system sync bugs.

For ChangeNotifier/Provider: same pattern — a mixin that adds PresentumSlotState as a field and exposes a revalidate() method that calls notifyListeners() after resolving.

Riverpod — you're right that it doesn't fit the mixin pattern cleanly, but an AsyncNotifier extension or a standalone presentumProvider that reads from other providers works. Don't shoehorn it; document "use a provider family that takes your app state as input."
Drop Guards, Keep Eligibility

Guards as a concept conflated two things: eligibility evaluation (good, keep it) and state mutation (bad, that's the host state management's job). Your composable eligibility objects are the genuinely useful part. Replace guards with a simple pipeline:

dart
// Before (guard model — mutates state, order-sensitive, hard to test)
class CampaignGuard extends PresentumGuard<...> {
  FutureOr<PresentumState> call(storage, history, state, candidates, context) {
    state.setActive(...); // mutation buried here
    return state;
  }
}

// After (resolver model — pure function, trivially testable)
class CampaignResolver extends PresentumResolver {
  @override
  Future<Map<Surface, PresentumSlotState>> resolve(candidates, context) async {
    return {
      for (final candidate in candidates)
        candidate.surface: await _evaluateEligibility(candidate, context)
    };
  }
}

Sequential execution and history access were the two things you liked about guards — both survive in the resolver. History is injected as part of PresentumContext. Sequential evaluation is the for loop.
The API Surface of v2

The entire public API becomes:
Class	Role
PresentumSlotState	Plain data: what's active, what's queued, per surface
PresentumCandidate	A payload + surface + options (impressions, cooldown, etc.)
PresentumContext	Injected read-only context for eligibility evaluation
PresentumEligibility	Abstract base for composable rules (AllOf, AnyOf, TimeRange, etc.)
PresentumResolver	Evaluates candidates against context, returns slot state
PresentumBlocMixin	BLoC adapter (thin, optional, in a separate file or sub-package)
PresentumChangeNotifierMixin	ChangeNotifier adapter (same)

No PresentumOutlet. No PresentumComposition. No delegate.build. The UI layer is the host state management's widgets — BlocBuilder, BlocSelector, Consumer, ValueListenableBuilder.
The Real Architecture Decision

Publish as a single package with adapters in separate files, or as a core package + adapter packages (presentum, presentum_bloc, presentum_provider)?

For your scale right now: single package, adapters in src/adapters/. The overhead of maintaining separate pub.dev packages isn't worth it until you have adoption. When you do, splitting presentum_bloc off is one file move.
What This Doesn't Solve

One honest caveat: the resolver's PresentumContext needs to contain whatever eligibility rules need — user segment, app version, current time, feature flags. Populating that context object is still your responsibility, and it will require reading from your BLoC state or repository layer. That's not boilerplate Presentum can eliminate — it's the legitimate cost of flexible eligibility. Document it clearly so users understand what they own vs. what the library owns.

this is perfect.

one small question, do we keep slots as per on BlocBase instance only? which makes it that we can access slots only from bloc.slots, not bloc.state.slots, since slots is not a part of a state model. this is what was my assumption "extend state model, so that state has access to and can operate with slots". what do you think?

This is a genuinely important design decision with real trade-offs. Here's the honest analysis:
bloc.slots vs bloc.state.slots

bloc.slots (slots on the Bloc instance) means slot state lives outside the state model. It mutates independently, which immediately creates two problems:

    BlocBuilder won't rebuild on slot changes — BlocBuilder listens to bloc.stream, which only emits when emit() is called with a new state. If _slots mutates on the Bloc instance directly, the UI is blind to it unless you manually call emit(state) as a no-op just to trigger a rebuild. That's a hack.

    State snapshots are incomplete — if you log, replay, or hydrate your Bloc state (e.g., HydratedBloc), the slot state is invisible. Your debugger shows a state that doesn't reflect what the user actually sees.

bloc.state.slots (slots inside the state model) is architecturally correct for exactly those reasons — state is the single source of truth, and the UI reacts to it uniformly through BlocBuilder/BlocSelector.
The Real Concern — State Coupling

Your hesitation is probably about this: if PresentumSlotState is part of AppState, then every state class in every Bloc that wants presentation slots must carry it as a field. That feels invasive.

The answer is the mixin is on the state class, not the Bloc:

dart
mixin PresentumStateMixin {
  PresentumSlotState get slots;
  
  // Implement copyWith-style update in the concrete state
  // e.g., state.copyWithSlots(newSlots)
}

// Your existing state, untouched except for one field + mixin
class PostsState with PresentumStateMixin {
  final List<Post> posts;
  final bool isLoading;
  final PresentumSlotState slots; // added field

  const PostsState({
    this.posts = const [],
    this.isLoading = false,
    this.slots = const PresentumSlotState.empty(),
  });

  PostsState copyWith({
    List<Post>? posts,
    bool? isLoading,
    PresentumSlotState? slots,
  }) => PostsState(
    posts: posts ?? this.posts,
    isLoading: isLoading ?? this.isLoading,
    slots: slots ?? this.slots,
  );
}

The Bloc then emits a full state update — slots travel with the rest of state, BlocSelector can isolate just the slots for UI, and Equatable handles equality correctly:

dart
// In the Bloc event handler
Future<void> _onRevalidateSlots(event, emit) async {
  final newSlots = await resolver.resolve(candidates, context);
  emit(state.copyWith(slots: newSlots));
}

// In the UI — only rebuilds when slots actually change
BlocSelector<PostsBloc, PostsState, PresentumSlotState>(
  selector: (state) => state.slots,
  builder: (context, slots) => slots.activeFor(Surface.banner) != null
      ? BannerWidget(slots.activeFor(Surface.banner)!)
      : const SizedBox.shrink(),
)

The Verdict

Slots belong on the state model, not the Bloc instance. The mixin goes on the state class. The Bloc just calls emit(state.copyWith(slots: newSlots)) after resolving — which is exactly the pattern your team already uses for every other field. No special cases, no surprise rebuild failures, no invisible state in snapshots. The only cost is one extra field in copyWith, which is the same cost as adding any other piece of state.
Prepared using Claude Sonnet 4.6 Thinking
so no need for the PresentumBlocMixin, right? Can you give me a complete picture

Correct — no PresentumBlocMixin. The Bloc itself needs nothing. The entire integration is: state carries slots, Bloc emits state, UI reads state. That's it.
Complete Picture
1. The Core Package (State-Agnostic)

These classes have zero dependency on BLoC, Provider, or anything reactive:

dart
// The slot state — plain data, immutable, serializable
class PresentumSlotState {
  final Map<Surface, PresentumSlot> _active;
  final Map<Surface, Queue<PresentumCandidate>> _queues;

  const PresentumSlotState.empty() : _active = const {}, _queues = const {};

  PresentumSlot? activeFor(Surface surface) => _active[surface];
  bool hasActive(Surface surface) => _active.containsKey(surface);

  PresentumSlotState withActive(Surface surface, PresentumSlot slot) => ...;
  PresentumSlotState withDismissed(Surface surface) => ...;
  PresentumSlotState withShown(Surface surface) => ...;
}

// Composable eligibility rules — pure functions
abstract class PresentumEligibility {
  Future<bool> evaluate(PresentumCandidate candidate, PresentumContext context);
}

class AllOfEligibility extends PresentumEligibility { ... }
class AnyOfEligibility extends PresentumEligibility { ... }
class TimeRangeEligibility extends PresentumEligibility { ... }
class MaxImpressionsEligibility extends PresentumEligibility { ... }
class UserSegmentEligibility extends PresentumEligibility { ... }

// Context — read-only snapshot injected at resolve time
class PresentumContext {
  final String? userId;
  final String appVersion;
  final DateTime now;
  final Map<String, dynamic> attributes; // anything eligibility rules need
}

// Candidate — a payload + surface + options
class PresentumCandidate<T> {
  final T payload;
  final Surface surface;
  final PresentumOptions options; // maxImpressions, cooldownMinutes, priority, etc.
  final PresentumEligibility eligibility;
}

// The resolver — takes candidates + context, returns new slot state
// No mutation of external state. Pure computation.
class PresentumResolver {
  final PresentumHistoryRepository history; // reads impression counts, last shown, etc.

  Future<PresentumSlotState> resolve(
    List<PresentumCandidate> candidates,
    PresentumContext context, {
    PresentumSlotState current = const PresentumSlotState.empty(),
  }) async {
    var state = current;

    // Sequential — order of candidates list is the priority order
    for (final candidate in candidates) {
      final eligible = await candidate.eligibility.evaluate(candidate, context);
      if (!eligible) continue;

      final shown = await history.shownCount(candidate);
      if (shown >= candidate.options.maxImpressions) continue;

      final lastShown = await history.lastShown(candidate);
      if (lastShown != null) {
        final elapsed = context.now.difference(lastShown).inMinutes;
        if (elapsed < candidate.options.cooldownMinutes) continue;
      }

      // Slot available — assign active or enqueue
      if (!state.hasActive(candidate.surface)) {
        state = state.withActive(candidate.surface, PresentumSlot(candidate));
      } else {
        state = state.withEnqueued(candidate.surface, candidate);
      }
    }

    return state;
  }
}

2. State Integration — The Mixin Goes on Your State Class

dart
mixin PresentumStateMixin {
  PresentumSlotState get slots;
}

// Your Bloc's state — you add one field and the mixin, nothing else changes
class PostsState with PresentumStateMixin {
  final List<Post> posts;
  final bool isLoading;
  @override
  final PresentumSlotState slots;

  const PostsState({
    this.posts = const [],
    this.isLoading = false,
    this.slots = const PresentumSlotState.empty(),
  });

  PostsState copyWith({
    List<Post>? posts,
    bool? isLoading,
    PresentumSlotState? slots,
  }) => PostsState(
    posts: posts ?? this.posts,
    isLoading: isLoading ?? this.isLoading,
    slots: slots ?? this.slots,
  );
}

3. The Bloc — Nothing Special

No mixin, no base class. Just a resolver injected as a dependency, called inside event handlers you already own:

dart
class PostsBloc extends Bloc<PostsEvent, PostsState> {
  final PostsRepository _posts;
  final PresentumResolver _presentum;
  final PresentumContext Function() _buildContext; // or injected directly

  PostsBloc(this._posts, this._presentum, this._buildContext)
      : super(const PostsState()) {
    on<PostsLoaded>(_onLoaded);
    on<PostsDismissSlot>(_onDismissSlot);
    on<PostsRevalidateSlots>(_onRevalidate);
  }

  Future<void> _onLoaded(PostsLoaded event, Emitter<PostsState> emit) async {
    emit(state.copyWith(isLoading: true));
    final posts = await _posts.fetchAll();

    // Revalidate slots whenever meaningful app state changes
    final slots = await _presentum.resolve(candidates, _buildContext());
    emit(state.copyWith(posts: posts, isLoading: false, slots: slots));
  }

  Future<void> _onRevalidate(PostsRevalidateSlots event, Emitter<PostsState> emit) async {
    final slots = await _presentum.resolve(candidates, _buildContext());
    emit(state.copyWith(slots: slots));
  }

  void _onDismissSlot(PostsDismissSlot event, Emitter<PostsState> emit) {
    emit(state.copyWith(slots: state.slots.withDismissed(event.surface)));
    // optionally record dismissal in history repo
  }
}

4. The UI — Plain BlocSelector, No Custom Widgets Required

dart
// Anywhere in the widget tree — rebuilds only when slots change
BlocSelector<PostsBloc, PostsState, PresentumSlotState>(
  selector: (state) => state.slots,
  builder: (context, slots) {
    final active = slots.activeFor(Surface.banner);
    if (active == null) return const SizedBox.shrink();
    return BannerWidget(payload: active.payload as BannerPayload);
  },
)

// Or if you want a reusable widget (optional convenience, not required)
class PresentumBlocSlot<B extends BlocBase<S>, S extends PresentumStateMixin>
    extends StatelessWidget {
  final Surface surface;
  final Widget Function(BuildContext, PresentumSlot?) builder;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<B, S, PresentumSlot?>(
      selector: (state) => state.slots.activeFor(surface),
      builder: builder,
    );
  }
}

5. The Full Dependency Graph

text
                    ┌─────────────────────────────┐
                    │     presentum (core)         │
                    │                              │
                    │  PresentumSlotState          │
                    │  PresentumCandidate          │
                    │  PresentumContext            │
                    │  PresentumEligibility (*)    │
                    │  PresentumResolver           │
                    │  PresentumStateMixin         │  ← only thing touching your state
                    └─────────────────────────────┘
                              ▲           ▲
                              │           │
               ┌──────────────┘           └─────────────┐
               │                                        │
    ┌──────────────────┐                   ┌────────────────────┐
    │   Your BLoC      │                   │  Your ChangeNotifier│
    │   PostsState     │                   │  or Provider model  │
    │   with mixin     │                   │   with mixin        │
    └──────────────────┘                   └────────────────────┘

No Listenable. No external refresh trigger. No delegate. No Outlet widget. The Bloc decides when to revalidate because it already knows when its own meaningful state changes — that knowledge was always yours, Presentum was just stealing it.

can you provide full implementation of the presentum history resolver. also, why have you put the PresentumEligibility interface into the PresentumCandidate? And what is PresentumContext, it seems like a domain-app class, not an abstract or T generic version or something that domain app client provides, how do we solve it? Also, as per old presentum API, the entire PresentumState was with generic Surface and something else i forgot, we are missing it completely.

for comprehensive presentum recent docs see docs.presentum.dev

Good — now I have the full picture of the existing generics (TItem, Surface, Variant), the PresentumOption structure, the eligibility resolver, and how storage/history works. Let me answer all four questions rigorously.
Addressing All Four Questions
1. Why PresentumEligibility Should NOT Be on PresentumCandidate

The way I put it in the sketch was wrong. Looking at the actual API, eligibility is evaluated by a separate DefaultEligibilityResolver that receives a context map and operates on the payload — not on the candidate wrapper. The candidate carries data (payload, option), not logic. Coupling eligibility to the candidate violates the same separation of concerns Presentum was designed to enforce. The correct model:

dart
// ✅ Correct — eligibility is injected into the resolver, not the candidate
final resolver = DefaultEligibilityResolver(
  rules: createStandardRules(),
  extractors: [TimeRangeExtractor(), AnySegmentExtractor(), ...],
);

// Candidate carries data only
class PresentumCandidate<TItem, S extends PresentumSurface, V> {
  final TItem item;       // already-constructed PresentumItem
  final S surface;
  // NO eligibility field here
}

The eligibility conditions live inside the payload's metadata (as the existing API shows with contextKey lookups), evaluated by the resolver against an externally injected context map. The candidate is a pure data envelope.
2. PresentumContext — It Is a Domain Class, That's the Problem

You're right to flag it. A concrete PresentumContext class with typed fields like userId, appVersion is a domain decision baked into the library, which forces every consumer to map their app state to Presentum's schema. The existing API already solved this correctly — it uses a Map<String, dynamic> as context:

dart
final context = {
  'user_segments': {'premium', 'trial'},
  'app_version': 2.1,
  'country': 'US',
};
final isEligible = await resolver.isEligible(candidate.payload, context);

So PresentumContext should simply be typedef PresentumContext = Map<String, dynamic>. The consumer builds this map from their own state (BLoC state, repository, wherever) and the library never prescribes its shape. Eligibility rules access it via typed contextKey strings. No domain coupling.
3. Missing Generics — The Full Type Signature

The existing API uses three generics throughout: TItem (the item type, e.g. CampaignItem), S extends PresentumSurface (the surface enum), and V (the variant type, e.g. CampaignVariant). The new design must preserve these. Here's the corrected PresentumStateMixin:

dart
mixin PresentumStateMixin<TItem, S extends PresentumSurface, V> {
  PresentumSlotState<TItem, S, V> get slots;
}

// Your state — the three generics flow through naturally
class PostsState with PresentumStateMixin<CampaignItem, AppSurface, CampaignVariant> {
  final List<Post> posts;
  final bool isLoading;

  @override
  final PresentumSlotState<CampaignItem, AppSurface, CampaignVariant> slots;

  const PostsState({
    this.posts = const [],
    this.isLoading = false,
    this.slots = const PresentumSlotState.empty(),
  });

  PostsState copyWith({
    List<Post>? posts,
    bool? isLoading,
    PresentumSlotState<CampaignItem, AppSurface, CampaignVariant>? slots,
  }) => PostsState(
    posts: posts ?? this.posts,
    isLoading: isLoading ?? this.isLoading,
    slots: slots ?? this.slots,
  );
}

4. Complete PresentumSlotState + Resolver Implementation

dart
// ─── Slot ─────────────────────────────────────────────────────────────────
class PresentumSlot<TItem, S extends PresentumSurface, V> {
  final S surface;
  final TItem? active;
  final List<TItem> queue;

  const PresentumSlot({
    required this.surface,
    this.active,
    this.queue = const [],
  });

  PresentumSlot<TItem, S, V> copyWith({
    TItem? active,
    List<TItem>? queue,
    bool clearActive = false,
  }) => PresentumSlot(
    surface: surface,
    active: clearActive ? null : (active ?? this.active),
    queue: queue ?? this.queue,
  );
}

// ─── SlotState ────────────────────────────────────────────────────────────
class PresentumSlotState<TItem, S extends PresentumSurface, V> {
  final Map<S, PresentumSlot<TItem, S, V>> _slots;

  const PresentumSlotState.empty() : _slots = const {};
  const PresentumSlotState._(this._slots);

  PresentumSlot<TItem, S, V>? slotFor(S surface) => _slots[surface];
  TItem? activeFor(S surface) => _slots[surface]?.active;
  List<TItem> queueFor(S surface) => _slots[surface]?.queue ?? const [];
  bool hasActive(S surface) => _slots[surface]?.active != null;

  // Assign active — does NOT overwrite existing active; use replaceActive for that
  PresentumSlotState<TItem, S, V> withActive(S surface, TItem item) {
    final existing = _slots[surface];
    return PresentumSlotState._({
      ..._slots,
      surface: PresentumSlot(
        surface: surface,
        active: item,
        queue: existing?.queue ?? const [],
      ),
    });
  }

  // Enqueue — appended to back; use withPriorityEnqueue for sorted insertion
  PresentumSlotState<TItem, S, V> withEnqueued(S surface, TItem item) {
    final existing = _slots[surface];
    return PresentumSlotState._({
      ..._slots,
      surface: PresentumSlot(
        surface: surface,
        active: existing?.active,
        queue: [...(existing?.queue ?? []), item],
      ),
    });
  }

  // Dismiss active → promote next from queue automatically
  PresentumSlotState<TItem, S, V> withDismissed(S surface) {
    final slot = _slots[surface];
    if (slot == null) return this;
    final queue = [...slot.queue];
    final next = queue.isNotEmpty ? queue.removeAt(0) : null;
    return PresentumSlotState._({
      ..._slots,
      surface: PresentumSlot(
        surface: surface,
        active: next,
        queue: queue,
      ),
    });
  }

  // Mark shown — does NOT change active/queue, just signals history recording
  // Actual persistence is done via PresentumHistoryRepository outside this class
  PresentumSlotState<TItem, S, V> withShownRecorded(S surface) => this;

  // Clear a specific surface entirely
  PresentumSlotState<TItem, S, V> withCleared(S surface) {
    final updated = Map<S, PresentumSlot<TItem, S, V>>.from(_slots);
    updated.remove(surface);
    return PresentumSlotState._(updated);
  }
}

5. Complete PresentumHistoryResolver

This is the core you asked for — the full resolver that reads history, applies maxImpressions, cooldownMinutes, evaluates eligibility, assigns active/queue per surface:

dart
// ─── History repository interface — you implement this ────────────────────
abstract class PresentumHistoryRepository {
  /// How many times this item was shown on this surface+variant combo
  Future<int> shownCount(String itemId, {required Object surface, Object? variant});

  /// When was it last shown, null if never
  Future<DateTime?> lastShown(String itemId, {required Object surface, Object? variant});

  /// Record a shown event — called by the resolver after assignment
  Future<void> recordShown(String itemId, {required Object surface, Object? variant});
}

// ─── Item identity — your TItem must implement this ──────────────────────
abstract class PresentumIdentifiable {
  String get id;
}

// ─── The resolver ─────────────────────────────────────────────────────────
class PresentumHistoryResolver<
  TItem extends PresentumIdentifiable,
  S extends PresentumSurface,
  V
> {
  final PresentumHistoryRepository history;
  final EligibilityResolver eligibilityResolver;

  const PresentumHistoryResolver({
    required this.history,
    required this.eligibilityResolver,
  });

  /// Primary method — call this from your Bloc event handler.
  ///
  /// [candidates] — ordered list; earlier = higher priority within a surface
  /// [context]    — Map<String, dynamic> built from your app state
  /// [current]    — pass existing slot state to preserve surfaces not in candidates
  Future<PresentumSlotState<TItem, S, V>> resolve({
    required List<PresentumCandidateEntry<TItem, S, V>> candidates,
    required PresentumContext context,
    PresentumSlotState<TItem, S, V> current = const PresentumSlotState.empty(),
    DateTime? now,
  }) async {
    final resolvedNow = now ?? DateTime.now();
    var state = current;

    // Group candidates by surface to handle per-surface active/queue logic
    final bySurface = <S, List<PresentumCandidateEntry<TItem, S, V>>>{};
    for (final candidate in candidates) {
      (bySurface[candidate.surface] ??= []).add(candidate);
    }

    for (final entry in bySurface.entries) {
      final surface = entry.key;
      final surfaceCandidates = entry.value;

      // Clear this surface before re-resolving it fresh
      state = state.withCleared(surface);

      for (final candidate in surfaceCandidates) {
        final item = candidate.item;
        final option = candidate.option;

        // ── 1. Eligibility check ──────────────────────────────────────────
        final eligible = await eligibilityResolver.isEligible(
          candidate.eligibilityPayload,
          context,
        );
        if (!eligible) continue;

        // ── 2. Impression cap ─────────────────────────────────────────────
        if (option.maxImpressions != null) {
          final count = await history.shownCount(
            item.id,
            surface: surface,
            variant: candidate.variant,
          );
          if (count >= option.maxImpressions!) continue;
        }

        // ── 3. Cooldown check ─────────────────────────────────────────────
        if (option.cooldownMinutes != null) {
          final lastShown = await history.lastShown(
            item.id,
            surface: surface,
            variant: candidate.variant,
          );
          if (lastShown != null) {
            final elapsed = resolvedNow.difference(lastShown).inMinutes;
            if (elapsed < option.cooldownMinutes!) continue;
          }
        }

        // ── 4. Assign to surface ──────────────────────────────────────────
        if (!state.hasActive(surface)) {
          state = state.withActive(surface, item);
          // Record shown immediately, or defer to TrackedWidget — your call.
          // Deferring to TrackedWidget is preferable so "shown" only fires
          // when the widget actually renders, not when the resolver runs.
        } else {
          state = state.withEnqueued(surface, item);
        }
      }
    }

    return state;
  }
}

// ─── Candidate entry — data envelope passed to the resolver ───────────────
class PresentumCandidateEntry<TItem, S extends PresentumSurface, V> {
  final TItem item;
  final S surface;
  final V? variant;
  final PresentumResolverOption option;      // maxImpressions, cooldownMinutes, etc.
  final Map<String, dynamic> eligibilityPayload; // what the eligibility rules read

  const PresentumCandidateEntry({
    required this.item,
    required this.surface,
    this.variant,
    required this.option,
    required this.eligibilityPayload,
  });
}

// ─── Option — constraints only, no domain data ────────────────────────────
class PresentumResolverOption {
  final int? maxImpressions;
  final int? cooldownMinutes;
  final bool alwaysOnIfEligible; // skip impression/cooldown checks if true

  const PresentumResolverOption({
    this.maxImpressions,
    this.cooldownMinutes,
    this.alwaysOnIfEligible = false,
  });
}

// ─── Context — just a typedef, no domain class ────────────────────────────
typedef PresentumContext = Map<String, dynamic>;

6. How It All Wires Together in a Bloc

dart
Future<void> _onRevalidateSlots(
  RevalidateSlots event,
  Emitter<PostsState> emit,
) async {
  // You own building the context — Presentum never prescribes its shape
  final context = <String, dynamic>{
    'user_segments': state.user.segments,
    'app_version': PackageInfo.version,
    'country': state.user.country,
  };

  final newSlots = await _resolver.resolve(
    candidates: _buildCandidates(),   // your method, returns List<PresentumCandidateEntry>
    context: context,
    current: state.slots,             // preserve surfaces not being re-resolved
  );

  emit(state.copyWith(slots: newSlots));
}

The key design decisions baked in here:

    eligibilityPayload is separate from TItem — the item is your domain object; the eligibility payload is the flat Map<String, dynamic> the resolver's rules operate on. You map one to the other when building candidates. This means your domain objects stay clean

    current is passed in so surfaces not in the current candidate batch are preserved, not wiped — important if different Blocs own different surfaces

    Shown recording is deferred to TrackedWidget — the resolver assigns slots, but history.recordShown fires only when the widget actually renders, matching the existing TrackedWidget behavior

    PresentumContext is a typedef, not a class — the library enforces zero opinion on what keys you put in it

you've provided a concrete domain-specific history resolver, I think there should be an interface with clear API that user implement and realize whatever logic they need.

Correct. The PresentumHistoryResolver should be an abstract interface — the library defines the contract, the consumer owns the implementation. Here's the clean separation:
The Interface Layer

dart
// ─── The contract the library defines ─────────────────────────────────────

/// Read-only access to presentation history.
/// Implement this against your storage backend (SharedPreferences, Hive, Drift, etc.)
abstract interface class PresentumHistoryRepository {
  Future<int> shownCount(String itemId, {required Object surface, Object? variant});
  Future<DateTime?> lastShown(String itemId, {required Object surface, Object? variant});
  Future<void> recordShown(String itemId, {required Object surface, Object? variant});
  Future<void> recordDismissed(String itemId, {required Object surface, Object? variant});
}

/// Resolves whether a candidate is eligible given the current context.
/// Implement this to wire your own eligibility rule engine, remote config, or
/// a simple flag check — whatever your app needs.
abstract interface class PresentumEligibilityResolver {
  Future<bool> isEligible(
    Map<String, dynamic> eligibilityPayload,
    PresentumContext context,
  );
}

/// Orchestrates history + eligibility into a resolved slot state.
/// This is the top-level interface your Bloc calls.
abstract interface class PresentumResolver<
  TItem extends PresentumIdentifiable,
  S extends PresentumSurface,
  V,
> {
  Future<PresentumSlotState<TItem, S, V>> resolve({
    required List<PresentumCandidateEntry<TItem, S, V>> candidates,
    required PresentumContext context,
    PresentumSlotState<TItem, S, V> current,
    DateTime? now,
  });
}

The Default Implementation — Opt-In, Not Imposed

The library ships a DefaultPresentumResolver that composes PresentumHistoryRepository + PresentumEligibilityResolver with the sequential evaluation logic from before. Consumers use it if it fits, or implement PresentumResolver directly if their logic diverges:

dart
/// The library-provided implementation of PresentumResolver.
/// Covers: eligibility check → impression cap → cooldown → active/queue assignment.
/// If this doesn't fit your needs, implement [PresentumResolver] directly.
class DefaultPresentumResolver<
  TItem extends PresentumIdentifiable,
  S extends PresentumSurface,
  V,
> implements PresentumResolver<TItem, S, V> {
  final PresentumHistoryRepository history;
  final PresentumEligibilityResolver eligibility;

  const DefaultPresentumResolver({
    required this.history,
    required this.eligibility,
  });

  @override
  Future<PresentumSlotState<TItem, S, V>> resolve({
    required List<PresentumCandidateEntry<TItem, S, V>> candidates,
    required PresentumContext context,
    PresentumSlotState<TItem, S, V> current = const PresentumSlotState.empty(),
    DateTime? now,
  }) async {
    final resolvedNow = now ?? DateTime.now();
    var state = current;

    final bySurface = <S, List<PresentumCandidateEntry<TItem, S, V>>>{};
    for (final c in candidates) {
      (bySurface[c.surface] ??= []).add(c);
    }

    for (final entry in bySurface.entries) {
      state = state.withCleared(entry.key);

      for (final candidate in entry.value) {
        if (!await _passes(candidate, context, resolvedNow)) continue;

        state = state.hasActive(entry.key)
            ? state.withEnqueued(entry.key, candidate.item)
            : state.withActive(entry.key, candidate.item);
      }
    }

    return state;
  }

  Future<bool> _passes(
    PresentumCandidateEntry<TItem, S, V> candidate,
    PresentumContext context,
    DateTime now,
  ) async {
    final option = candidate.option;

    if (!await eligibility.isEligible(candidate.eligibilityPayload, context)) {
      return false;
    }

    if (!option.alwaysOnIfEligible) {
      if (option.maxImpressions != null) {
        final count = await history.shownCount(
          candidate.item.id,
          surface: candidate.surface,
          variant: candidate.variant,
        );
        if (count >= option.maxImpressions!) return false;
      }

      if (option.cooldownMinutes != null) {
        final last = await history.lastShown(
          candidate.item.id,
          surface: candidate.surface,
          variant: candidate.variant,
        );
        if (last != null &&
            now.difference(last).inMinutes < option.cooldownMinutes!) {
          return false;
        }
      }
    }

    return true;
  }
}

The Ownership Map

text
┌────────────────────────────────────────────────────────────────┐
│                    presentum (library)                         │
│                                                                │
│  INTERFACES (contracts)          DEFAULT IMPLEMENTATIONS       │
│  ─────────────────────           ───────────────────────────   │
│  PresentumResolver         ←──   DefaultPresentumResolver      │
│  PresentumHistoryRepository ←──  (none — you always own this)  │
│  PresentumEligibilityResolver ←─ DefaultEligibilityResolver    │
│  PresentumIdentifiable                                         │
│  PresentumSurface                                              │
│  PresentumStateMixin                                           │
│  PresentumSlotState                                            │
│  PresentumCandidateEntry                                       │
│  PresentumResolverOption                                       │
│  PresentumContext (typedef)                                    │
└────────────────────────────────────────────────────────────────┘
         ▲                              ▲
         │ implements                   │ implements
┌────────────────────┐      ┌───────────────────────────┐
│   Your app         │      │   Your app                 │
│                    │      │                            │
│  HiveHistoryRepo   │      │  RemoteConfigEligibility   │
│  implements        │      │  implements                │
│  PresentumHistory  │      │  PresentumEligibility      │
│  Repository        │      │  Resolver                  │
└────────────────────┘      └───────────────────────────┘

The Rule
Class	Who defines it	Who implements it
PresentumResolver	Library	Library (Default...) or consumer
PresentumHistoryRepository	Library	Always consumer
PresentumEligibilityResolver	Library	Library (Default...) or consumer
PresentumSlotState	Library	Library (concrete, final)
PresentumStateMixin	Library	Consumer's state class

PresentumHistoryRepository gets no default implementation deliberately — the library has no opinion on whether you use Hive, SharedPreferences, Drift, or an in-memory map. That decision is always yours. Everything else has a default you can opt out of by implementing the interface directly.

Basically we've replaced guards with resolvers, which we are in full control of.

another think id find particularly useful, is to expose a util function to sequentially execute a list of resolver in order, just like guards used to operate. it might be handful in various cases when you want to resolve the effective state on one call, so that subsequent resolver would get updated history, current state, and so on. what do you think

Correct replacement — resolvers are guards without the state mutation sin.

The sequential executor idea is sound, but there's one thing to pressure-test first.
The Honest Trade-off

The useful case is clear: resolver B needs to see what resolver A already assigned to avoid double-filling a surface, or resolver B's eligibility depends on what's already active. Passing current forward between resolvers handles this naturally.

The risk: if resolver B reads history.shownCount for an item resolver A just assigned, it gets stale data — resolver A hasn't called recordShown yet (that's deferred to TrackedWidget). So sequential resolvers share slot state correctly, but history is still the committed history, not the in-flight one. That's a constraint worth documenting explicitly, not hiding inside the utility.
The Implementation

dart
/// Executes a list of resolvers sequentially, threading state forward.
/// Each resolver receives the slot state produced by the previous one as [current].
///
/// ⚠️ History reflects committed records only — items assigned by earlier
/// resolvers in this chain are NOT yet in history until TrackedWidget fires.
/// Design your resolvers with this in mind.
Future<PresentumSlotState<TItem, S, V>> resolveSequentially<
  TItem extends PresentumIdentifiable,
  S extends PresentumSurface,
  V,
>({
  required List<PresentumResolver<TItem, S, V>> resolvers,
  required List<PresentumCandidateEntry<TItem, S, V>> candidates,
  required PresentumContext context,
  PresentumSlotState<TItem, S, V> initial = const PresentumSlotState.empty(),
  DateTime? now,
}) async {
  var state = initial;

  for (final resolver in resolvers) {
    state = await resolver.resolve(
      candidates: candidates,
      context: context,
      current: state,   // each resolver sees what the previous one produced
      now: now,
    );
  }

  return state;
}

That's it. A free function, not a class — it has no state of its own, no reason to be an object.
Usage

dart
// In your Bloc event handler
final newSlots = await resolveSequentially(
  resolvers: [
    _maintenanceResolver,    // runs first — can lock all surfaces
    _appUpdateResolver,      // sees maintenance result, won't fill locked surfaces
    _campaignResolver,       // fills remaining open surfaces
  ],
  candidates: _buildCandidates(),
  context: context,
  initial: state.slots,
);

emit(state.copyWith(slots: newSlots));

One Design Question

Should candidates be shared across all resolvers (as above) or should each resolver receive its own candidate list?

The shared list is simpler but means every resolver sees every candidate and must internally filter by relevance. Per-resolver candidates are more explicit but require a different signature:

dart
// Alternative — paired list
Future<PresentumSlotState<TItem, S, V>> resolveSequentially({
  required List<(
    PresentumResolver<TItem, S, V>,
    List<PresentumCandidateEntry<TItem, S, V>>,
  )> resolvers,
  ...
})

The paired version is more honest — a maintenance resolver genuinely has different candidates than a campaign resolver. Worth deciding before you ship the API, because it's a breaking change to swap later.

the examples you gave was not particularly what I was thinking about. in such scenrario of course your assumption of giving per each resolver desired candidates is logical. however, i was thinking about resolvers that mentally belong to the same resolving sequence, but with different purposes, which together forms a complete sequence and resolves effective final state. mostly the entire logic to schedule, check eligibility, validate, remove, track, mark, etc, could be easily put into one all-in-one resolver, but sometimes to leverage separation of concerns, like it used to be with guards, we could have specifically delegated resolvers as per their respective functionality they only need to handle, whatever it can be, in this case sequantial execution might make sense, if we want to separate resolvers from one huge to several composable and potentially reuse them in loads of other places

That reframes it completely. You're describing resolver composition, not resolver chaining over different candidate sets. Each resolver in the sequence is a single-responsibility transformation of the same slot state — one validates, one schedules, one applies impression logic, one marks shown — and together they form a pipeline over shared candidates.

This is exactly the same mental model as middleware, or a functional pipeline.
The Right Mental Model

text
candidates + context
        │
        ▼
┌─────────────────────┐
│  EligibilityResolver │  → filters ineligible candidates out of contention
└────────┬────────────┘
         │ state
         ▼
┌─────────────────────┐
│  SchedulingResolver  │  → applies time windows, cooldowns, impression caps
└────────┬────────────┘
         │ state
         ▼
┌─────────────────────┐
│  PriorityResolver    │  → orders remaining candidates, fills active/queue
└────────┬────────────┘
         │ state
         ▼
┌─────────────────────┐
│  TrackingResolver    │  → records shown counts, marks history (if eager)
└────────┬────────────┘
         │
         ▼
   PresentumSlotState  ← final effective state

Each resolver does one thing. Any of them can be swapped, skipped, or reused in a different pipeline. The sequence is explicit and readable.
The Implementation

dart
/// A single step in a composed resolution pipeline.
/// Receives the full candidate list and the state produced so far,
/// returns a new state. Does exactly one thing.
abstract interface class PresentumResolverStep<
  TItem extends PresentumIdentifiable,
  S extends PresentumSurface,
  V,
> {
  Future<PresentumSlotState<TItem, S, V>> execute({
    required List<PresentumCandidateEntry<TItem, S, V>> candidates,
    required PresentumContext context,
    required PresentumSlotState<TItem, S, V> current,
    required DateTime now,
  });
}

/// Executes a composed pipeline of resolver steps sequentially,
/// threading slot state forward through each step.
///
/// Steps share the same candidates and context. Each step receives
/// the state produced by the previous one as [current].
///
/// ⚠️ History reflects only committed records. Steps that assign
/// items do not make those items visible to history until
/// TrackedWidget fires recordShown.
Future<PresentumSlotState<TItem, S, V>> runPipeline<
  TItem extends PresentumIdentifiable,
  S extends PresentumSurface,
  V,
>({
  required List<PresentumResolverStep<TItem, S, V>> steps,
  required List<PresentumCandidateEntry<TItem, S, V>> candidates,
  required PresentumContext context,
  PresentumSlotState<TItem, S, V> initial = const PresentumSlotState.empty(),
  DateTime? now,
}) async {
  final resolvedNow = now ?? DateTime.now();
  var state = initial;

  for (final step in steps) {
    state = await step.execute(
      candidates: candidates,
      context: context,
      current: state,
      now: resolvedNow,
    );
  }

  return state;
}

Example Steps — Composed From Reusable Parts

dart
/// Step 1 — strips candidates that fail eligibility
class EligibilityStep<TItem extends PresentumIdentifiable, S extends PresentumSurface, V>
    implements PresentumResolverStep<TItem, S, V> {
  final PresentumEligibilityResolver eligibility;
  const EligibilityStep(this.eligibility);

  @override
  Future<PresentumSlotState<TItem, S, V>> execute({
    required candidates, required context, required current, required now,
  }) async {
    // This step doesn't touch slot state — it returns current unchanged.
    // Its role is to be composed BEFORE assignment steps, which read
    // candidates filtered by earlier steps.
    //
    // NOTE: for filtering to actually work, pipeline needs a candidate
    // filtering mechanism — see the note below on passing filtered candidates.
    return current;
  }
}

/// Step 2 — assigns eligible, non-capped, non-cooldown candidates to slots
class AssignmentStep<TItem extends PresentumIdentifiable, S extends PresentumSurface, V>
    implements PresentumResolverStep<TItem, S, V> {
  final PresentumHistoryRepository history;
  const AssignmentStep(this.history);

  @override
  Future<PresentumSlotState<TItem, S, V>> execute({
    required candidates, required context, required current, required now,
  }) async {
    var state = current;

    final bySurface = <S, List<PresentumCandidateEntry<TItem, S, V>>>{};
    for (final c in candidates) {
      (bySurface[c.surface] ??= []).add(c);
    }

    for (final entry in bySurface.entries) {
      state = state.withCleared(entry.key);

      for (final candidate in entry.value) {
        state = state.hasActive(entry.key)
            ? state.withEnqueued(entry.key, candidate.item)
            : state.withActive(entry.key, candidate.item);
      }
    }

    return state;
  }
}

/// Step 3 — evicts anything that's expired or been dismissed too many times
class EvictionStep<TItem extends PresentumIdentifiable, S extends PresentumSurface, V>
    implements PresentumResolverStep<TItem, S, V> {
  final PresentumHistoryRepository history;
  final PresentumResolverOption option;
  const EvictionStep(this.history, this.option);

  @override
  Future<PresentumSlotState<TItem, S, V>> execute({
    required candidates, required context, required current, required now,
  }) async {
    // walks current active slots and evicts any that no longer pass
    // impression caps or are past their end date — promotes from queue
    return current; // implementation mirrors withDismissed promotion logic
  }
}

The Honest Design Problem

There's a tension here: EligibilityStep logically filters candidates, but steps only return PresentumSlotState — they can't mutate the candidate list passed to subsequent steps. If filtering and assignment are separate steps, they need to communicate through the slot state, or the pipeline signature needs to thread candidates too:

dart
// Option A — steps return (state, filteredCandidates)
typedef PresentumPipelineResult<TItem, S, V> = (
  PresentumSlotState<TItem, S, V>,
  List<PresentumCandidateEntry<TItem, S, V>>,
);

// Option B — filtering is always internal to the AssignmentStep, not a separate step
// EligibilityStep is only useful as a separate step for pure side-effects (logging, analytics)

Option B is more honest — if eligibility filtering is the whole job of a step, it needs to influence what gets assigned, which means either it mutates candidates (leaks into next step) or assignment re-checks eligibility anyway (step is redundant). The cleaner split is:

    Steps that transform slot state — assignment, eviction, promotion, queue reorder

    The eligibility + history check stays inside the assignment step or a shared utility it calls

That way every PresentumResolverStep is unambiguously a state → state transformation, which is the composable primitive you want. Filtering is a concern of the assignment logic, not a standalone pipeline stage.

I didnt get it 100% clearly, could you state the complete implementations with practical use cases and reusability and explain slightly more straightforward and in a more simple way

Let me strip it down to the clearest possible explanation first, then show concrete code.
The Core Idea in Plain Terms

A pipeline is just a list of steps that run one after another. Each step gets the same candidates and context, plus whatever state the previous step produced, and returns a new state.

text
Step 1 runs → produces State A
Step 2 runs with State A → produces State B  
Step 3 runs with State B → produces State C  ← this is your final result

That's the entire concept. The value is that each step does exactly one job, and you can mix and match steps across different pipelines in different Blocs.
The Problem With Filtering as a Separate Step

Here's why a dedicated "eligibility filter step" doesn't work cleanly. Steps only pass state forward — they can't remove candidates from the list that later steps see. So an EligibilityStep would run, decide "this candidate is ineligible"... and have nowhere to put that decision. The next AssignmentStep still sees all the original candidates and assigns them anyway. The filter did nothing.

The fix: eligibility + history checks always live inside the step that assigns. Steps are state → state transformations. Filtering is internal logic, not a pipeline stage.
Complete Implementation

dart
// ─── The step interface ────────────────────────────────────────────────────

abstract interface class PresentumResolverStep<
  TItem extends PresentumIdentifiable,
  S extends PresentumSurface,
  V,
> {
  Future<PresentumSlotState<TItem, S, V>> execute({
    required List<PresentumCandidateEntry<TItem, S, V>> candidates,
    required PresentumContext context,
    required PresentumSlotState<TItem, S, V> current,
    required DateTime now,
  });
}

// ─── The pipeline runner ───────────────────────────────────────────────────

Future<PresentumSlotState<TItem, S, V>> runPipeline<
  TItem extends PresentumIdentifiable,
  S extends PresentumSurface,
  V,
>({
  required List<PresentumResolverStep<TItem, S, V>> steps,
  required List<PresentumCandidateEntry<TItem, S, V>> candidates,
  required PresentumContext context,
  PresentumSlotState<TItem, S, V> initial = const PresentumSlotState.empty(),
  DateTime? now,
}) async {
  final resolvedNow = now ?? DateTime.now();
  var state = initial;

  for (final step in steps) {
    state = await step.execute(
      candidates: candidates,
      context: context,
      current: state,
      now: resolvedNow,
    );
  }

  return state;
}

Four Concrete Reusable Steps
Step 1 — EligibilityAndSchedulingStep

Assigns eligible, non-capped, non-cooldown candidates to active/queue. This is the workhorse — eligibility and history checks are internal.

dart
class EligibilityAndSchedulingStep<
  TItem extends PresentumIdentifiable,
  S extends PresentumSurface,
  V,
> implements PresentumResolverStep<TItem, S, V> {
  final PresentumHistoryRepository history;
  final PresentumEligibilityResolver eligibility;

  const EligibilityAndSchedulingStep({
    required this.history,
    required this.eligibility,
  });

  @override
  Future<PresentumSlotState<TItem, S, V>> execute({
    required candidates,
    required context,
    required current,
    required now,
  }) async {
    var state = current;

    // Group by surface so we handle active/queue per surface correctly
    final bySurface = <S, List<PresentumCandidateEntry<TItem, S, V>>>{};
    for (final c in candidates) {
      (bySurface[c.surface] ??= []).add(c);
    }

    for (final entry in bySurface.entries) {
      final surface = entry.key;
      state = state.withCleared(surface);

      for (final candidate in entry.value) {
        // All checks are here — eligibility, impressions, cooldown
        if (!await _isAllowed(candidate, context, now)) continue;

        state = state.hasActive(surface)
            ? state.withEnqueued(surface, candidate.item)
            : state.withActive(surface, candidate.item);
      }
    }

    return state;
  }

  Future<bool> _isAllowed(
    PresentumCandidateEntry<TItem, S, V> candidate,
    PresentumContext context,
    DateTime now,
  ) async {
    if (!await eligibility.isEligible(candidate.eligibilityPayload, context)) {
      return false;
    }

    final option = candidate.option;
    if (option.alwaysOnIfEligible) return true;

    if (option.maxImpressions != null) {
      final count = await history.shownCount(
        candidate.item.id,
        surface: candidate.surface,
        variant: candidate.variant,
      );
      if (count >= option.maxImpressions!) return false;
    }

    if (option.cooldownMinutes != null) {
      final last = await history.lastShown(
        candidate.item.id,
        surface: candidate.surface,
        variant: candidate.variant,
      );
      if (last != null &&
          now.difference(last).inMinutes < option.cooldownMinutes!) {
        return false;
      }
    }

    return true;
  }
}

Step 2 — EvictionStep

Walks the current active slots and removes anything that is no longer valid (expired time window, item removed from remote config, etc.). Promotes the next queued item automatically.

dart
/// Practical use: remote config returns a new payload without a previously
/// active campaign. Without eviction, the stale item stays active forever
/// because the scheduler only clears surfaces it's been asked to fill.
class EvictionStep<
  TItem extends PresentumIdentifiable,
  S extends PresentumSurface,
  V,
> implements PresentumResolverStep<TItem, S, V> {
  final PresentumEligibilityResolver eligibility;

  const EvictionStep({required this.eligibility});

  @override
  Future<PresentumSlotState<TItem, S, V>> execute({
    required candidates,
    required context,
    required current,
    required now,
  }) async {
    var state = current;

    // Build a set of still-valid item IDs from the candidate list
    final validIds = candidates.map((c) => c.item.id).toSet();

    for (final surface in state.activeSurfaces) {
      final active = state.activeFor(surface);
      if (active == null) continue;

      final stillValid = validIds.contains(active.id) &&
          await eligibility.isEligible(
            // find the matching candidate's eligibility payload
            candidates
                .firstWhere((c) => c.item.id == active.id)
                .eligibilityPayload,
            context,
          );

      if (!stillValid) {
        // Dismiss the stale item — withDismissed auto-promotes from queue
        state = state.withDismissed(surface);
      }
    }

    return state;
  }
}

Step 3 — PriorityReorderStep

Reorders the queue inside each surface slot by a priority score without touching what's currently active. Useful when remote config returns items with explicit priority weights.

dart
/// Practical use: a campaign manager returns 5 banners with priority scores.
/// The scheduler fills the queue in candidate list order (insertion order).
/// This step re-sorts the queue by priority so the highest-value item
/// promotes next when the active one is dismissed.
class PriorityReorderStep<
  TItem extends PresentumIdentifiable,
  S extends PresentumSurface,
  V,
> implements PresentumResolverStep<TItem, S, V> {
  final int Function(TItem a, TItem b) comparator;

  const PriorityReorderStep({required this.comparator});

  @override
  Future<PresentumSlotState<TItem, S, V>> execute({
    required candidates,
    required context,
    required current,
    required now,
  }) async {
    var state = current;

    for (final surface in state.activeSurfaces) {
      final queue = state.queueFor(surface);
      if (queue.length < 2) continue;

      final sorted = [...queue]..sort(comparator);
      state = state.withReorderedQueue(surface, sorted);
    }

    return state;
  }
}

Step 4 — AnalyticsStep

Side-effect only — fires analytics events for what just became active. Returns current unchanged. This is the legitimate use case for a step that doesn't mutate state.

dart
/// Practical use: you want to log "slot_filled" to Firebase every time
/// a surface gets a new active item, without coupling that logic to
/// the assignment step or the Bloc.
class AnalyticsStep<
  TItem extends PresentumIdentifiable,
  S extends PresentumSurface,
  V,
> implements PresentumResolverStep<TItem, S, V> {
  final void Function(S surface, TItem item) onSlotFilled;

  const AnalyticsStep({required this.onSlotFilled});

  @override
  Future<PresentumSlotState<TItem, S, V>> execute({
    required candidates,
    required context,
    required current,
    required now,
  }) async {
    for (final surface in current.activeSurfaces) {
      final active = current.activeFor(surface);
      if (active != null) onSlotFilled(surface, active);
    }
    return current; // pure side-effect, state unchanged
  }
}

Composing Them in a Bloc

dart
Future<void> _onRevalidateSlots(event, Emitter<PostsState> emit) async {
  final context = {
    'user_segments': state.user.segments,
    'app_version': PackageInfo.version,
  };

  // ── Standard pipeline used in most Blocs ──────────────────────────────
  final newSlots = await runPipeline(
    steps: [
      EvictionStep(eligibility: _eligibility),              // remove stale
      EligibilityAndSchedulingStep(                         // fill slots
        history: _history,
        eligibility: _eligibility,
      ),
      PriorityReorderStep(comparator: (a, b) =>            // sort queues
          b.priority.compareTo(a.priority)),
      AnalyticsStep(onSlotFilled: _analytics.logSlotFilled), // side effects
    ],
    candidates: _buildCandidates(),
    context: context,
    initial: state.slots,
  );

  emit(state.copyWith(slots: newSlots));
}

dart
// ── A lighter pipeline for a Bloc that only needs basic scheduling ─────
final newSlots = await runPipeline(
  steps: [
    EligibilityAndSchedulingStep(
      history: _history,
      eligibility: _eligibility,
    ),
  ],
  candidates: _buildCandidates(),
  context: context,
);

The steps are individually constructable, independently testable, and composable in any order. EvictionStep alone is reusable anywhere you need stale-item cleanup. AnalyticsStep is reusable across every Bloc without duplicating the callback logic. A new Bloc just picks the steps it needs.

I really don't like the global functions like runPipeline. Can we create a dedicated static PresentumStepsPipepline abstract final class with exactly one function that our current runPipeline does. One small trick we could do is to name the function itself call inside of the class, which would automatically make the class itself a callable function, you don't even need to execute manually PresentumStepsPipepline.run or something like that. If you think this function might have some other useful functions, then the trick with call won't be not appropriate

The call trick is clean here — runPipeline is the only meaningful operation this class has. No other utility functions belong on it. Steps compose themselves, the pipeline just threads them. So call is appropriate.

dart
abstract final class PresentumPipeline {
  const PresentumPipeline._();

  static Future<PresentumSlotState<TItem, S, V>> call<
    TItem extends PresentumIdentifiable,
    S extends PresentumSurface,
    V,
  >({
    required List<PresentumResolverStep<TItem, S, V>> steps,
    required List<PresentumCandidateEntry<TItem, S, V>> candidates,
    required PresentumContext context,
    PresentumSlotState<TItem, S, V> initial = const PresentumSlotState.empty(),
    DateTime? now,
  }) async {
    final resolvedNow = now ?? DateTime.now();
    var state = initial;

    for (final step in steps) {
      state = await step.execute(
        candidates: candidates,
        context: context,
        current: state,
        now: resolvedNow,
      );
    }

    return state;
  }
}

Usage is then just:

dart
final newSlots = await PresentumPipeline(
  steps: [...],
  candidates: _buildCandidates(),
  context: context,
  initial: state.slots,
);

One Honest Caveat

Dart's call trick on a class only works when you have an instance to call — PresentumPipeline(...) invokes the constructor, not call. Since this is abstract final with no public constructor, PresentumPipeline(...) won't compile.

The actual invocation has to be:

dart
final newSlots = await PresentumPipeline.call(
  steps: [...],
  candidates: _buildCandidates(),
  context: context,
  initial: state.slots,
);

Which is clean and readable — arguably cleaner than the global function because the namespace is explicit. The call naming still signals "this class exists to be invoked, not instantiated", which is the right mental model. Just not the syntactic sugar you were hoping for — Dart reserves the call shorthand for instance methods, not static ones.

If the one-word invocation matters, a top-level function inside a dedicated presentum_pipeline.dart file with part of presentum scoping keeps it namespaced without the class wrapper noise. But PresentumPipeline.call(...) reads well enough on its own.

Aha, got it, then we can define the presentum pipeline as a default class, without using abstract final, this way we can initialize the class and the call would be accessible automatically.

Exactly. Make it a proper instantiable class, constructor takes the steps, call takes the runtime arguments. The steps are fixed at construction time, the candidates and context vary per invocation.

dart
class PresentumPipeline<
  TItem extends PresentumIdentifiable,
  S extends PresentumSurface,
  V,
> {
  final List<PresentumResolverStep<TItem, S, V>> steps;

  const PresentumPipeline(this.steps);

  Future<PresentumSlotState<TItem, S, V>> call({
    required List<PresentumCandidateEntry<TItem, S, V>> candidates,
    required PresentumContext context,
    PresentumSlotState<TItem, S, V> initial = const PresentumSlotState.empty(),
    DateTime? now,
  }) async {
    final resolvedNow = now ?? DateTime.now();
    var state = initial;

    for (final step in steps) {
      state = await step.execute(
        candidates: candidates,
        context: context,
        current: state,
        now: resolvedNow,
      );
    }

    return state;
  }
}

Now the usage is genuinely clean. Define the pipeline once — likely as a Bloc dependency — and invoke it naturally:

dart
// Defined once, injected into the Bloc
final _pipeline = PresentumPipeline<CampaignItem, AppSurface, CampaignVariant>([
  EvictionStep(eligibility: _eligibility),
  EligibilityAndSchedulingStep(history: _history, eligibility: _eligibility),
  PriorityReorderStep(comparator: (a, b) => b.priority.compareTo(a.priority)),
  AnalyticsStep(onSlotFilled: _analytics.logSlotFilled),
]);

// Called inside any event handler
final newSlots = await _pipeline(
  candidates: _buildCandidates(),
  context: context,
  initial: state.slots,
);

This also opens a natural pattern: different Blocs construct different PresentumPipeline instances with different step compositions, and since it's a plain class, it's trivially injectable and mockable in tests.