# Responsive layout

One app for phones, tablets, iPads and desktop windows. The layout follows the
**window**, not the device: an iPad in a narrow Stage Manager window behaves
like a phone, and a desktop window dragged narrow does too.

Why this and not a device check, from Flutter's own guidance
([adaptive best practices](https://docs.flutter.dev/ui/adaptive-responsive/best-practices),
[general approach](https://docs.flutter.dev/ui/adaptive-responsive/general)):

- "Your choice shouldn't depend on the *type* of device, but on the device's
  available window size."
- Don't lock the orientation, and don't switch layouts on `orientation`:
  "the device's orientation also doesn't necessarily inform you of how much
  space your app window has."
- Apple deprecated `UIRequiresFullScreen` in iPadOS 26 (TN3192) and Android 16
  ignores orientation locks on screens 600dp and wider — a portrait lock is no
  longer something an app can rely on.

## Size classes

Material 3 window size classes (`lib/core/layout/app_breakpoints.dart`):

| Class | Width | Typical | Navigation |
| --- | --- | --- | --- |
| compact | < 600 | phone upright | floating capsule at the bottom |
| medium | 600 – 839 | iPad upright, foldable open, half a desktop | rail (80dp) |
| expanded | 840 – 1199 | iPad landscape, laptop window | sidebar (256dp), collapsible to the rail |
| large | 1200 – 1599 | big tablet, desktop | sidebar |
| extra-large | ≥ 1600 | monitor | sidebar |

A window under **480dp tall** (every phone held sideways) is *compact height*
and always gets the rail, whatever its width.

## What the app knows

`AppLayout` (`lib/core/layout/app_layout.dart`) — immutable, compared by value:

```dart
final layout = context.layout;      // rebuilds on any size change
layout.windowSize;                   // compact · medium · expanded · large · extraLarge
layout.heightClass;                  // compact · medium · expanded
layout.deviceType;                   // phone · tablet · desktop — platform habits only
layout.nav;                          // bar · rail · sidebar
layout.gutter;                       // 16 · 24 · 32
AppLayout.columnsFor(width);         // 1 · 2 · 3
```

It is built **every frame** by `AppLayoutHost` (in `MaterialApp.builder`) from
`MediaQuery.sizeOf`, which already holds the window's size in the first frame.
So the first frame is laid out right, and a rotation or a window resize is
picked up in the same frame — there is no listener to start and no value to
seed. `AppLayoutScope` is an `InheritedModel`: a widget that asks only for the
class rebuilds when the *class* changes, not on every pixel of a drag.

| You want | Use |
| --- | --- |
| a padding or a flag | `context.layout.gutter`, `.isCompact`, `.isExpandedUp` |
| a whole subtree per class | `AdaptiveLayout(compact:, medium:, expanded:)` (missing → next smaller) |
| rebuild only when the class flips | `AppLayoutScope.windowSizeOf(context)` |
| code with no `BuildContext` (a bloc, a service) | `getIt<LayoutReader>().current` — a read-only copy the host writes from each frame |
| the device kind (a title bar, hover, shortcuts) | `layout.deviceType`, never for layout |

Never write `MediaQuery.of(context).size.width < 600`, an orientation check, or
`Platform.isX` to choose a layout.

## The shell

`RootScreen` picks the navigation from `AppLayoutScope.navOf(context)`:

- **bar** — the floating capsule (`AppBottomNav`), which tucks into a dock on
  scroll. Only compact windows have it, so `AppBottomNav.listBottomPadding`
  reserves its height only there.
- **rail / sidebar** — `AppSideNav`, Material 3 Expressive's collapsed and
  expanded navigation rail (the navigation drawer was deprecated in favour of
  the expanded rail). A floating card on the start edge, so it flips with the
  language. The open destination is marked by the pill **and** bold text.
  `SideNavController` remembers collapsed/expanded; Ctrl/⌘+B toggles it.

The tab stack keeps its state through a `GlobalKey`, so a rotation or a resize
that swaps the capsule for the rail does not rebuild the tabs: scroll
positions, loaded data and an open search survive.

## Screens

| Screen | Compact | Medium | Expanded and wider |
| --- | --- | --- | --- |
| Feed | 1 column | 2 | 3, in a ≤ 1200dp centred column |
| Rails / carousels | one slide + peek | 60% slides | 42% slides; mouse drag and hover arrows |
| Detail | picture above, sheet over it | same | picture beside the text |
| Settings | one list | one list | groups on the start side, the chosen one beside them |
| Sign-in | form | form | brand panel beside the form |
| Onboarding | collage over a sheet | same | collage beside a card |
| Sheets (`AppBottomSheet`) | bottom sheet | bottom sheet | centred dialog, ≤ 720dp |
| Image viewer | swipe | swipe | arrows, zoom buttons, thumbnails, ← → Esc + − |
| Snackbars | above the capsule | bottom | bottom end corner, 360dp |

Headings step up one size from 840dp (`AppTypography.expandedFrom`), and all
text grows a little with the window: ×1.05 at expanded, ×1.10 at large, ×1.15 at
extra-large (`AppTextScale.windowBoost`, applied by `AppTextScaleHost` in `App`).
It multiplies the reader's own text size, which is capped at 130% first, and
does nothing below 840dp, so a phone is untouched. Content is capped in width
as well.

## Input

Touch first, then pointer and keyboard as accelerators
([input guide](https://docs.flutter.dev/ui/adaptive-responsive/input)):

- **Hover** — `AppStates.hoverOverlay` on cards; a `Tooltip` on icon buttons
  (hover with a pointer, long press on touch).
- **Focus** — `AppFocusRing` draws the ring only while the *keyboard* is in
  use, never after a mouse click.
- **Shortcuts** — `AppShortcuts` (Ctrl, ⌘ on Apple platforms): 1–5 tabs, K or F
  search, `,` settings, Esc back, R / F5 refresh, B sidebar, F11 / ⌃⌘F full
  screen, `?` help. They step aside while a text field has the focus. The list
  is `AppShortcutCatalog`, shown by `?` and by Settings → Keyboard shortcuts.
- **Context menus** — `AppCard.menuActions`: right click with a mouse, long
  press on touch.
- **Scrollbars** — always visible on desktop (`AppScrollBehavior`), Material's
  default elsewhere. Horizontal rails and carousels can be dragged with a mouse
  (`AppDragScroll`); lists keep the wheel so a drag still selects text.
- **Density** — `VisualDensity.compact` on desktop; touch targets stay ≥ 44dp
  elsewhere.

## Platform capabilities

`AppPlatform` (`lib/core/platform/app_platform.dart`) names what the code needs
to know, never the device — Flutter's
[capabilities and policies](https://docs.flutter.dev/ui/adaptive-responsive/capabilities)
advice. A plugin with no code for a platform still **builds** there and throws
`MissingPluginException` when called, so every call into one sits behind a
capability or a DI service.

| Getter | True on | Guards |
| --- | --- | --- |
| `supportsVibration` | Android, iOS | `HapticsService` (`NoHaptics` on desktop) |
| `supportsPush` | Android, iOS | Firebase Messaging |
| `supportsPermissionHandler` | Android, iOS, Windows | `permission_handler` |
| `hasDesktopWindow` | Windows, macOS, Linux | window_manager, title bar, shortcuts |
| `hasNativeSplash` | Android, iOS, web | desktop hides the window until the first frame instead |

In tests: `debugDefaultTargetPlatformOverride = TargetPlatform.windows;`.

## Testing

`TestDevices` names the sizes (`test/helpers/test_app.dart`): `reference`
390×844, `tablet` 800×1200, `phoneLandscape` 844×390, `tabletLandscape`
1180×820, `desktop` 1280×800. `pumpApp(tester, widget, surfaceSize: …)` sets the
view; change `tester.view.physicalSize` and pump to test a live resize.
