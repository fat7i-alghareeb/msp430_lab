# Windows and macOS

The same app, the same code, the same package list as on phones. Nothing that
works on Android or iOS is removed for desktop: platform-specific plugins stay
in `pubspec.yaml` and are called only where they exist (`AppPlatform`,
`docs/RESPONSIVE.md`).

## Create the platforms

`flutter create` writes `windows/` and `macos/`; the brick writes everything
else.

```bash
flutter create --org com.yourcompany --project-name my_app \
  --platforms=android,ios,windows,macos my_app
mason make flutter_app_template --on-conflict overwrite
cd my_app
dart run tool/setup_project.dart
```

`tool/setup_project.dart` edits the runner files for you. Run it after both
commands, in either order, and again whenever you add a platform. It is
idempotent, plain Dart with nothing to download, and it leaves a file alone
that it does not recognise:

| File | Edit | Why |
| --- | --- | --- |
| `windows/CMakeLists.txt` | defines `_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS` | `permission_handler_windows` includes a header the newest MSVC (Visual Studio 2026) rejects; without this `flutter build windows` stops with error STL1011 |
| `windows/CMakeLists.txt` | `CMAKE_POLICY_DEFAULT_CMP0169 OLD` | `objectbox_flutter_libs` calls CMake's `FetchContent_Populate` the old way; CMake 3.30+ warns about it on every configure. Its own `cmake_policy(VERSION 3.14...3.25)` resets newer policies inside the plugin, so the *DEFAULT* variable is the one that reaches it |
| `windows/CMakeLists.txt` | removes `/await` from `permission_handler_windows_plugin` | the plugin asks for C++20 and still passes the deprecated `/await`, which MSVC 14.51 reports on every build (`D9047`); C++20 coroutines need no switch |
| `windows/CMakeLists.txt` | `add_link_options(/ignore:4099 /ignore:4078)` | hides two harmless linker warnings from prebuilt libraries — see «Warnings that are hidden» below |
| `windows/runner/flutter_window.cpp` | no `Show()` after the first frame | Dart restores the window's size and place, then shows it |
| `windows/runner/main.cpp` | `SendAppLinkToInstance()` first | a launch with a link goes to the open window |
| `macos/Runner/MainFlutterWindow.swift` | `hiddenWindowAtLaunch()` | no empty rectangle before the first frame |
| `macos/Runner/*.entitlements` | `com.apple.security.network.client` | a sandboxed Mac app cannot make a request without it — every release-build call fails with «Operation not permitted» |
| `macos/Runner/Info.plist` | `CFBundleURLTypes` | `myapp://…` opens the app |

If the script reports a file it could not patch (`CHECK`), make the edit by
hand from the table. Run it again any time: it skips what is already done.

The same script gives the project its own Windows toast GUID, replacing the
all-zero placeholder in `AppConfig.windowsToastGuid`: Windows files toast
notifications under it and Inno Setup uses it to recognise an earlier install.
Keep it for the app's lifetime.

## Run

```bash
flutter run -d windows
flutter run -d macos
```

The window opens hidden and appears once its first frame is painted, back at
the size and place it had last time (clamped back onto a screen that exists).
The minimum is **500 × 600**: Microsoft asks for at most 500 so Snap Layouts can
fit the window in their zones.

## The title bar

The app draws its own (`lib/core/window/app_title_bar.dart`), in the screen's
own ground colour — Microsoft's title bar guidance asks bars to blend with the
window. It holds the sidebar toggle, the page title, a centred search field,
theme and language switches.

- **Height** — 32, or 48 when it carries the search field (Microsoft's two
  sizes). On macOS it matches the system band the traffic lights sit in.
- **Drag** — empty space moves the window; a double click maximises; a right
  click opens the system menu on Windows. The search field does not drag.
- **Inactive window** — the bar's content dims while the window has no focus.
- **Windows** — minimise, maximise/restore and close are drawn the way
  Microsoft specifies a custom bar: the Segoe Fluent glyphs (E921, E922, E923,
  E8BB), 46 wide, full bar height, rest · hover · pressed · inactive states,
  Close red on hover. They stay top-right in Arabic too, as Windows keeps them.
- **macOS** — the real traffic lights stay. Apple's HIG: avoid custom window
  controls on macOS; the app only extends its content under the bar.
- **Snap Layouts** — Windows 11 shows its layout flyout over a *system*
  maximise button. A drawn one would need the runner to answer
  `WM_NCHITTEST` with `HTMAXBUTTON` over the button; this template does not.
  `Win + Z` and dragging to a screen edge snap as usual.

## Notifications

`flutter_local_notifications` covers Android, iOS, macOS and Windows.

- **macOS** — permission is requested through the plugin (`permission_handler`
  has no macOS code).
- **Windows** — toasts need no permission. Cancelling or listing shown toasts
  needs *package identity*, which the MSIX build has and `flutter run` does not.
  Repeating notifications are not supported on Windows.
- **Push** (Firebase Messaging) stays Android and iOS: the plugin has no Windows
  code. `_fcmEnabled` is still `false` by default.

## Storage

- **ObjectBox** stays: it lists Android, iOS, macOS, Windows and Linux, and the
  store already lives in its own folder under the documents directory, which
  is what it recommends on desktop. A *sandboxed* macOS app (this one is) is
  also meant to pass an App Group to `openStore`. The group starts with your
  Apple team id, so the template cannot invent it: build with
  `--dart-define=MACOS_APP_GROUP=TEAMID.group.yourapp` and add the
  `com.apple.security.application-groups` entitlement for the same id.
  Without it ObjectBox opens as before, as it does on every other platform.
  *Not verified without a Mac and an Apple team — check it on your first
  macOS build.*
- **Secure storage on macOS** uses the legacy keychain
  (`usesDataProtectionKeychain: false`), so it works without an Apple team. The
  data-protection keychain needs the `keychain-access-groups` entitlement and a
  provisioning profile from the paid program. On Windows, Visual Studio's *C++
  ATL* component must be installed.

## Links

`myapp://items/42` opens the item. The scheme is `AppLinks.scheme`; keep
`msix_config.protocol_activation` (in `pubspec.yaml`) equal to it. Windows
registers it from the MSIX or the Inno Setup script; macOS from `Info.plist`.
Activation only works from an installed package, not `flutter run`.

## Shipping — all free

### Windows

| Route | Command | Good for | Notes |
| --- | --- | --- | --- |
| **Installer** (`setup.exe`, Inno Setup) | `dart run tool/build_windows_installer.dart` | your website | needs [Inno Setup 6](https://jrsoftware.org/isinfo.php) (free). SmartScreen warns «unknown publisher» until the installer is signed or has download history |
| **Microsoft Store** (MSIX) | `dart run msix:create --store` | public release | the Store signs it, no warning; registration is **free for individuals** |
| **MSIX for testing** | `dart run msix:create` | your own PC | self-signed test certificate, installed on this PC |
| **zip** | Codemagic `windows-release` | a quick share | unzip and run |

Windows requires an MSIX to be signed with a certificate the PC trusts; the
Store does that for you. Signing your own installer costs money (a code-signing
certificate, or Azure Artifact Signing).

### macOS

```bash
tool/build_macos_dmg.sh
```

Makes `dist/<name>-<version>.dmg` — open it, drag the app onto Applications.
Without Apple's paid Developer Program there is no Developer ID, so the app is
not notarised and macOS says it «cannot verify the developer» the first time:
the user opens **System Settings → Privacy & Security → Open Anyway**, once.

When you join the program: sign with your Developer ID (`codesign --options
runtime --timestamp`), submit with `xcrun notarytool submit … --wait`, then
`xcrun stapler staple`.

## CI

`codemagic.yaml` has `windows-release` (zip + MSIX) and `macos-release`
(zipped `.app` + `.dmg`), both unsigned. See `docs/CODEMAGIC.md`.

Shorebird code push also lists Windows, macOS and Linux; `docs/SHOREBIRD.md`
stays Android and iOS unless you extend it.

## Icons

`dart run flutter_launcher_icons -f flutter_launcher_icons.yaml` writes the
Windows `.ico` and the macOS `.icns` from `assets/images/app_icon.png`.

## One keyboard note

Dialogs put the confirming button **first on Windows** and last elsewhere
(Flutter's platform idioms guide). `AppDialog` does this by itself.

## Troubleshooting

**The first Windows build is slow.** `firebase_core` downloads the Firebase C++
SDK (about 960 MB) the first time, even though push is off on Windows — the
plugin cannot link without it. Later builds reuse the file in
`build/windows/x64` — do not delete that `.zip` when you clean the build folder.
To share one copy between projects, unzip it once and set `FIREBASE_CPP_SDK_DIR`
to the `firebase_cpp_sdk_windows` folder. The plugin only uses it when its
version is **exactly** the one the plugin asks for (it is written in
`windows/flutter/ephemeral/.plugin_symlinks/firebase_core/windows/CMakeLists.txt`
as `FIREBASE_SDK_VERSION`); any other version is ignored without a message and the
download starts anyway.

**`flutter build windows` stops at «Unable to generate build files» with
`non-existent target "firebase_app_check"`.** An interrupted first build left
an *empty* `build/windows/x64/extracted` folder, and the plugin treats a folder
that merely exists as an unpacked SDK. Delete `build/windows/x64/extracted` and
build again; if the `.zip` next to it was cut short as well, delete that too.

**`STL1011` / `<experimental/coroutine>` errors.** Visual Studio 2026's compiler
rejects a header `permission_handler_windows` still includes. `tool/setup_project.dart` defines
`_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS`; if you have not run it,
add the same `add_definitions` line to `windows/CMakeLists.txt`.

## Warnings that are hidden

The setup script hides these, on purpose, because they come from prebuilt third-party
code the app cannot change and nothing is wrong with the build:

| Warning | From | Why it is safe to hide |
| --- | --- | --- |
| `LNK4099` «PDB … not found; linking object as if no debug info» | the Firebase C++ SDK's `.lib` files, which point at `.pdb` files the SDK does not ship | only stepping into Firebase's own code in a debugger is affected |
| `LNK4078` «multiple `.voltbl` sections…» | Microsoft's `msvcprtd.lib` linked with that prebuilt code | the link succeeds; no cause is documented |
| CMake `CMP0169` | `objectbox_flutter_libs` | still fully supported; ObjectBox 5.3.2 is its newest stable release (`6.0.0-preview` is a prerelease) |

This hides the messages; it does not remove their causes. To see them again,
delete the matching lines from `windows/CMakeLists.txt`.
