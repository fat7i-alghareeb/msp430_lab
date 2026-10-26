# Router guide (`lib/core/router/`)

Read this before you change a route, a guard, a redirect, the splash or onboarding flow, or a deep link.
Rules in short: `.ai/architecture-rules.md` → Routing.

- Pages are `AppPage`s opened with `AppNavigator.push`; ids travel as path parameters. Pass an object through `extra` only
  when a page cannot re-read it by id.
- Pushed pages have a **relative** `pagePath` (`'settings'`, `'items/:id'`); top-level routes (`'/splash'`, `'/onboarding'`,
  `RootConstants.routePath`, `LoginScreen.wallPath`) are absolute.

The router is intentionally written so that **startup is driven by state**:

- **`AuthStateNotifier`** decides whether the user is authenticated/guest.
- **`OnboardingService`** decides whether onboarding is finished.
- **`SplashConfig.initialDelay`** enforces a minimum splash duration.

So the app does not manually navigate during startup; instead, routing reacts to state changes.

## Files in this folder

### `router_config.dart`

Owns the router instance and all redirect logic.

Key parts:

- **`RouterRefreshListenable`**
  - Purpose: provide _one_ `Listenable` for GoRouter to re-evaluate redirects.
  - It listens to:
    - `AuthStateNotifier`
    - `OnboardingService`

  - It starts `OnboardingService.initialize()` without awaiting it so storage loading happens outside the redirect path.
  - It also starts a timer that waits `SplashConfig.initialDelay` before allowing the app to leave splash.
  - Any change triggers `notifyListeners()`, which causes `GoRouter.redirect` to run again.

- **`AppRouterConfig`**
  - Purpose: composition root for routing.
  - Builds:
    - `RouterRefreshListenable`
    - `AppRouteGuard`
    - `GoRouter`

  - Sets `initialLocation` to `SplashScreen.pagePath`.

- **`AppRouteGuard`**
  - Purpose: keep _all_ redirect rules in a single focused class.
  - Exposes one method: `handleRedirect(...)`.
  - Runs, in order: the splash step, the onboarding step, the login wall (`AuthMode.loginRequired` only), a held share link, and
    `_handleEntry`, which leaves the startup screens for the shell and nothing else.

### `app_routes.dart` — the page tree

- **`AppPage`**: every page pushed over the shell, with its relative `segment` (`items/:id`) and `children` (which pages it opens). Sign-in is a child of every page.
- **`AppRouteTree.build`**: generates the nested `GoRoute`s under `/root` up to `maxDepth` (6), so `/root/items/1/items/2/login` is a real stack. Parameters are renamed per depth (`:id`, `:id2`…).
- **`AppRouteRegistry.routes`**: splash, onboarding, the login wall (`/login`) and the tree.

### `app_navigator.dart`

`AppNavigator.push(context, AppPage.x, params: {...})` pushes the page as a child of the page on top when the graph allows it, or under the shell otherwise — always a PUSH, so back pops one page. `pushTarget(router, AppTarget(...))` does the same without a context.

### `app_links.dart`

`AppLinks` (hosts, custom scheme, `linkable` pages, `locationOf`, `shareUrlOf`, notification `locationOfTarget`) and `LinkDispatcher`, the binding observer that opens a link from outside OVER the shell — and holds it until `RootScreen` reports the shell ready on a cold start.

### `desktop_links.dart`

`DesktopLinks`: on Windows and macOS a `myapp://` link arrives through `app_links` (a second Windows launch forwards its link to the
running copy before the app starts — `SendAppLinkToInstance` in the runner). It hands the location to `LinkDispatcher`; nothing
else in the router changes. Setup: `docs/DESKTOP_SETUP.md`.

### `app_page_transitions.dart`

Shared helper for consistent transitions between pages.

Responsibilities:

- Centralize animation duration/curve and reduce repeated `CustomTransitionPage` boilerplate.

## What triggers redirects (when does the guard run?)

`GoRouter.redirect` runs when:

- The current location changes.
- `RouterRefreshListenable` calls `notifyListeners()`.

`RouterRefreshListenable` notifies when:

- `AuthStateNotifier` changes (login, logout, token refresh, guest mode).
- `OnboardingService` changes (onboarding finished flag changes).
- The splash delay timer finishes.

## Startup flow (from first frame to the final screen)

This is the exact order enforced by `AppRouteGuard.handleRedirect`.

### Step 0: App starts on Splash

- Router starts at `SplashScreen.pagePath`.
- At this moment, one (or both) may still be _unresolved_:
  - **Auth**: `AuthStateNotifier.authStatus.status` can still be `Status.initial`.
  - **Onboarding**: `OnboardingService.initialize()` may still be loading the cached flag.

Additionally:

- `RouterRefreshListenable` starts the `SplashConfig.initialDelay` timer.

### Step 1: Splash guard (minimum splash + initial auth status)

Guard logic (simplified):

- If `splashDelayElapsed == false` **OR** `authStatus.status == Status.initial`:
  - Stay on splash (or redirect back to splash if you tried to navigate away).

What this means:

- Even if auth/onboarding resolve instantly, the splash remains visible for at least `SplashConfig.initialDelay` (zero on desktop,
  where the window already waited for its first frame).
- If the app is still bootstrapping session state, splash stays until `AuthStateNotifier` moves out of `Status.initial`.

### Step 2: Onboarding guard (only if enabled)

After splash conditions are satisfied, the guard checks onboarding:

- If `AppFlowConfig.onboardingEnabled == false`:
  - Skip onboarding completely.

- Else, it reads the synchronous cached value from `OnboardingService`.
  - If onboarding cache is not initialized yet:
    - Stay on `SplashScreen.pagePath`.
    - The service notifies the router when the value is loaded.

  - If onboarding is **not finished**:
    - Redirect to `OnboardingScreen.pagePath`.
    - While the user is on onboarding and it is still not finished, the guard allows staying there and does not run auth redirects yet.

  - If onboarding is **finished**:
    - Continue to the auth step.

Transition point:

- When onboarding is completed, the service notifies listeners → `RouterRefreshListenable` notifies → redirect re-runs.

### Step 3: Auth guard

After onboarding (or if onboarding is disabled), the guard checks auth:

- `isAuthenticated = (authStatus.status == Status.authenticated) && !authState.isGuest`
- `canEnterApp = isAuthenticated || authState.isGuest`

Then:

- `AuthMode.loginRequired` and **not authenticated and not guest**:
  - Redirect to `LoginScreen.wallPath` (`/login`). The wall offers «Continue as guest» (`AppFlowConfig.guestOnLoginWall`, on by default): it starts a guest session, which is the second half of `canEnterApp`, so the guard then moves the reader to the shell.
- `AuthMode.guestFirst`: never redirected to sign-in — protected actions open the sign-in sheet instead (`AuthGate.run`).

- If **authenticated or guest**:
  - If you are currently on splash/login/onboarding, redirect to `RootScreen.pagePath`.
  - Otherwise, allow the current route.

## Common scenarios (what happens in real life)

### Fresh install (onboarding enabled)

1. Start on Splash.
2. Wait for splash delay + auth status resolves.
3. Onboarding not finished → go to Onboarding.
4. User completes onboarding → redirect re-runs.
5. Unauthenticated → go to Login.

### Returning user (onboarding finished, already logged in)

1. Start on Splash.
2. Wait for splash delay + auth status resolves to authenticated.
3. Onboarding finished → proceed.
4. Authenticated → go to Root.

### Token expired

1. Requests may return 401 or token may be near expiry.
2. `DioClient` refresh flow attempts refresh.
3. If refresh succeeds → status stays authenticated.
4. If refresh fails/revoked → `AuthManager.expireSession()` (not `logout()`: the user did not ask to leave) → login wall with «session ended», or in guest-first mode a banner over the app and the user stays where they were.

## How to add a new page

1. Screen with `static const pagePath = 'orders/:id'` (relative) and `pageName`.
2. Add `orders(OrderScreen.pagePath, OrderScreen.pageName)` to `AppPage`, list it in the `children` of the pages that open it, and build it in `AppRouteTree`'s page switch.
3. Open it: `AppNavigator.push(context, AppPage.orders, params: {'id': id})`.
4. Reachable from a link? Add it to `AppLinks.linkable` and the Android/iOS link config (`docs/ANDROID_RELEASE_SETUP.md` §8, `docs/IOS_SETUP.md` §4).
5. Test the walk in `test/core/router/navigation_stack_test.dart`.

`context.go` replaces the whole stack — use it only for that (sign-out on the wall). Everything else is a push.
