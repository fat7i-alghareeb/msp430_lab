import 'package:flutter/material.dart';
import 'app_icons.dart';
import '../../../utils/helpers/app_strings.dart';

import '../../../utils/constants/design_constants.dart';

/// The search field — `DESIGN_SYSTEM.md`.
///
/// `surfaceVariant`, radius 14, height 44, search icon at the start. On focus
/// a clear `×` appears at the end.
///
/// The default placeholder is `AppStrings.searchPlaceholder`.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.trailing,
  });

  final TextEditingController? controller;

  /// Defaults to `AppStrings.searchPlaceholder`.
  final String? hintText;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Used when the field is a button that opens the real search screen —
  /// pair it with `readOnly: true`.
  final VoidCallback? onTap;

  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;

  /// Replaces the clear button, e.g. a filter button with a badge.
  final Widget? trailing;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();

  bool _ownsController = false;
  bool _ownsFocusNode = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _ownsFocusNode = widget.focusNode == null;
    _controller.addListener(_onChanged);
    _focusNode.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _focusNode.removeListener(_onChanged);
    if (_ownsController) _controller.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // The clear button appears only while focused AND non-empty — showing it
    // on an unfocused empty field is noise.
    final showClear =
        widget.trailing == null &&
        _focusNode.hasFocus &&
        _controller.text.isNotEmpty;

    return Material(
      // Its own `Material`, so the field works wherever it is put: a
      // `TextField` throws without one above it, and a tab that lets the
      // shell own the scaffold has nothing above it at all.
      type: MaterialType.transparency,
      // A floating card: surface, a soft shadow, a full pill.
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.full),
          boxShadow: theme.brightness == Brightness.dark
              ? null
              : const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x14141510),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
        ),
        child: SizedBox(
          height: 48,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            readOnly: widget.readOnly,
            // A read-only field is a BUTTON into the search screen.
            // Focusable, it took focus on the tap and got it back when search
            // closed, and the field sat outlined as if typed in.
            canRequestFocus: !widget.readOnly,
            autofocus: widget.autofocus,
            onTap: widget.onTap,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            textInputAction: TextInputAction.search,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: widget.hintText ?? AppStrings.searchPlaceholder,
              filled: true,
              fillColor: colors.surface,
              isDense: true,
              contentPadding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              // The app's own line glyphs, not Material's.
              prefixIcon: Padding(
                padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
                child: Center(
                  widthFactor: 1,
                  child: AppIcon(AppIcons.search, color: colors.primary),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 44,
              ),
              suffixIcon:
                  widget.trailing ??
                  (showClear
                      ? IconButton(
                          icon: AppIcon(
                            AppIcons.close,
                            size: AppIconSizes.inline,
                            color: colors.onSurfaceVariant,
                          ),
                          color: colors.onSurfaceVariant,
                          tooltip: AppStrings.clear,
                          onPressed: () {
                            _controller.clear();
                            widget.onChanged?.call('');
                          },
                        )
                      : null),
              border: _border(colors, focused: false),
              enabledBorder: _border(colors, focused: false),
              focusedBorder: _border(colors, focused: true),
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(ColorScheme colors, {required bool focused}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.full),
      borderSide: focused
          ? BorderSide(color: colors.primary, width: 2)
          : colors.brightness == Brightness.dark
          ? BorderSide(color: colors.outline)
          : BorderSide.none,
    );
  }
}
