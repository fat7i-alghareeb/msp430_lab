import 'package:flutter/material.dart';

import '../../../utils/constants/design_constants.dart';
import '../../../utils/helpers/build_svg_icon.dart';

/// The icon set — `DESIGN_SYSTEM.md`.
///
/// One line family: Lucide, normalised to stroke `1.7` with round caps and
/// joins, served from `assets/svgIcons/` through `vector_graphics` so the SVGs
/// are compiled at build time rather than parsed on screen.
///
/// **`font_awesome_flutter` was removed.** Nothing drew it, yet its three
/// fonts shipped in every build (~720 KB) — a font whose glyphs are reached
/// through `FaIconData` is not icon-tree-shaken. Its drawing style did not
/// match this system anyway.
///
/// Names here are the app's own, not Lucide's, so swapping the underlying set
/// later touches one file.
class AppIcons {
  AppIcons._();

  // ── navigation
  static const String home = 'assets/svgIcons/home.svg';
  static const String news = 'assets/svgIcons/news.svg';
  static const String store = 'assets/svgIcons/store.svg';
  static const String marketplace = 'assets/svgIcons/marketplace.svg';
  static const String search = 'assets/svgIcons/search.svg';
  static const String bell = 'assets/svgIcons/bell.svg';
  static const String user = 'assets/svgIcons/user.svg';
  static const String settings = 'assets/svgIcons/settings.svg';
  static const String grid = 'assets/svgIcons/grid.svg';

  // ── actions
  static const String bookmark = 'assets/svgIcons/bookmark.svg';
  static const String share = 'assets/svgIcons/share.svg';
  static const String phone = 'assets/svgIcons/phone.svg';
  static const String report = 'assets/svgIcons/report.svg';
  static const String more = 'assets/svgIcons/more.svg';
  static const String close = 'assets/svgIcons/close.svg';
  static const String chevronLeft = 'assets/svgIcons/chevron_left.svg';
  static const String chevronRight = 'assets/svgIcons/chevron_right.svg';
  static const String arrowLeft = 'assets/svgIcons/arrow_left.svg';
  static const String arrowRight = 'assets/svgIcons/arrow_right.svg';
  static const String arrowUp = 'assets/svgIcons/arrow_up.svg';
  static const String refresh = 'assets/svgIcons/refresh.svg';
  static const String filter = 'assets/svgIcons/filter.svg';
  static const String externalLink = 'assets/svgIcons/external_link.svg';
  static const String send = 'assets/svgIcons/send.svg';
  static const String edit = 'assets/svgIcons/edit.svg';
  static const String delete = 'assets/svgIcons/delete.svg';
  static const String logout = 'assets/svgIcons/logout.svg';

  // ── content
  static const String tag = 'assets/svgIcons/tag.svg';
  static const String calendar = 'assets/svgIcons/calendar.svg';
  static const String pin = 'assets/svgIcons/pin.svg';
  static const String directions = 'assets/svgIcons/directions.svg';
  static const String clock = 'assets/svgIcons/clock.svg';
  static const String comment = 'assets/svgIcons/comment.svg';
  static const String heart = 'assets/svgIcons/heart.svg';
  static const String star = 'assets/svgIcons/star.svg';
  static const String views = 'assets/svgIcons/views.svg';
  static const String image = 'assets/svgIcons/image.svg';
  static const String attachment = 'assets/svgIcons/attachment.svg';
  static const String link = 'assets/svgIcons/link.svg';

  // ── states
  static const String alert = 'assets/svgIcons/alert.svg';
  static const String info = 'assets/svgIcons/info.svg';
  static const String success = 'assets/svgIcons/success.svg';
  static const String offline = 'assets/svgIcons/offline.svg';
  static const String empty = 'assets/svgIcons/empty.svg';
  static const String power = 'assets/svgIcons/power.svg';
  static const String services = 'assets/svgIcons/services.svg';

  // ── preferences
  static const String language = 'assets/svgIcons/language.svg';
  static const String darkMode = 'assets/svgIcons/dark_mode.svg';
  static const String lightMode = 'assets/svgIcons/light_mode.svg';

  // ── controls — what the last Material `Icons.*` drew, in the same line
  static const String menu = 'assets/svgIcons/menu.svg';
  static const String check = 'assets/svgIcons/check.svg';
  static const String chevronDown = 'assets/svgIcons/chevron_down.svg';
  static const String eye = 'assets/svgIcons/eye.svg';
  static const String eyeOff = 'assets/svgIcons/eye_off.svg';
  static const String devices = 'assets/svgIcons/devices.svg';

  // ── large screens and desktop
  static const String panelLeft = 'assets/svgIcons/panel_left.svg';
  static const String zoomIn = 'assets/svgIcons/zoom_in.svg';
  static const String zoomOut = 'assets/svgIcons/zoom_out.svg';
  static const String keyboard = 'assets/svgIcons/keyboard.svg';

  /// Resolves a server-sent `iconKey` to an asset path.
  ///
  /// A server that names its own icons (categories, sections, notification
  /// types) will one day send a key the app does not know. An unknown key
  /// falls back to [grid] — **an item is never hidden because its icon is
  /// missing**. Add your server's keys to [_byKey].
  static String fromKey(String? key) {
    // An asset path is already resolved — pass it straight through.
    if (key != null && key.startsWith('assets/')) return key;
    return _byKey[key] ?? grid;
  }

  static const Map<String, String> _byKey = <String, String>{
    'home': home,
    'news': news,
    'store': store,
    'shop': marketplace,
    'marketplace': marketplace,
    'search': search,
    'bell': bell,
    'alert': alert,
    'info': info,
    'user': user,
    'settings': settings,
    'calendar': calendar,
    'event': calendar,
    'tag': tag,
    'offer': tag,
    'heart': heart,
    'star': star,
    'image': image,
    'link': link,
    'pin': pin,
    'location': pin,
    'phone': phone,
    'services': services,
    'tools': services,
    'power': power,
    'electronics': power,
    'grid': grid,
    'other': grid,
  };
}

/// Draws an icon from [AppIcons].
///
/// Defaults to `onSurfaceVariant` at 20dp — the list size from
/// `DESIGN_SYSTEM.md`. Pass a size from [AppIconSizes] rather than a number.
///
/// This does NOT add a touch target. Anything tappable must still be wrapped to
/// at least `44×44` ([AppIconSizes.minTouchTarget]), even when the glyph is 20.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.asset, {
    super.key,
    this.size = AppIconSizes.list,
    this.color,
    this.semanticLabel,
  });

  /// A constant from [AppIcons].
  final String asset;

  final double size;

  /// Defaults to `onSurfaceVariant`; the active state uses `primary`.
  final Color? color;

  /// Set it only when the icon carries meaning on its own. An icon beside a
  /// label that already says the same thing should stay unlabelled so a screen
  /// reader does not announce it twice.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    // The scheme's own `onSurfaceVariant` is the default;
    // an inherited text colour wins when there is one, because an icon beside a
    // word should match it. The hand-written hex this replaced was the LIGHT
    // scheme's, so an unstyled icon stayed light on a dark ground.
    final resolved =
        color ??
        DefaultTextStyle.of(context).style.color ??
        Theme.of(context).colorScheme.onSurfaceVariant;

    final icon = buildSvgIcon(
      assetName: asset,
      color: resolved,
      width: size,
      height: size,
    );

    if (semanticLabel == null) {
      return ExcludeSemantics(child: icon);
    }
    return Semantics(label: semanticLabel, image: true, child: icon);
  }
}
