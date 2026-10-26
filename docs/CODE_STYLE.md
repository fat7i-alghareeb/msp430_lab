# Code style — how this project is written

The conventions the code actually follows, so the next feature looks like the last one. **The code wins over this file**: when
they disagree, fix this file (or the code) in the same task.

- **Reference feature:** `lib/features/showcase_feed/` — _change this line when you pick another feature as the model._
- **Before you write a feature:** find the closest finished feature, read it, and copy its shape (folders, names, state, tests).
- **How this file grows:** every time the owner corrects you ("write it like this, not like that"), add one line under the right
  heading with the reason, marked `corrected`. A line marked `observed` was read from the code and has not been confirmed; the
  owner strikes what is wrong.

## Files and structure

- `observed` One public widget per file, named after it (`feed_cards.dart` holds the three card types that belong together).
  Private helper widgets (`_Sections`, `_ListFooter`) stay in the same file when only that file uses them.
- `observed` A file past ~450 lines is a signal to split by section (`feed_body.dart` and `feed_header.dart` are the largest).
- `observed` Layers as in `.ai/architecture-rules.md`. The reference feature condenses `data/` and `domain/` into one file each
  (`feed_data.dart`, `feed_entities.dart`); a new feature uses the full folders (`lib/features/auth/`).
- `observed` Imports inside `lib/` are relative (`../../../../core/...`), dart/flutter/package imports first, a blank line between groups.

## Widgets

- `observed` A card that loads is a `SkeletonWidget` with two constructors, `.success(...)` and `.loading()`, over one
  `buildBody`: `FeedCard.success({super.key, required FeedItemEntity this.item}) : super.success();`
  `const FeedCard.loading({super.key}) : item = null, super.loading();` — the data field is nullable, the skeleton leaves are
  `SkeletonText` / `SkeletonBox`.
- `observed` Widgets are `const` wherever possible; a static size is a named constant on the class (`static const double thumbnail = 84;`).
- `observed` Colour and text style are read once at the top of `build` (`final theme = Theme.of(context); final colors = theme.colorScheme;`).
- `observed` A navigation helper is a class of static methods next to the widgets (`FeedNavigation.openItem(context, id)`), not logic in `onTap`.
- `observed` Shared constants that two widgets must agree on live in one class (`FeedHeroTags`), never typed twice.
- `needs a decision` `.ai/flutter-ui-rules.md` says each non-trivial widget gets its own file, while the reference feature keeps private
  helper classes (up to ~100 lines) in the file that uses them. Working rule until the owner decides: a private class stays in
  its file below ~120 lines and when no other file needs it; anything bigger or shared gets its own file.

## State

- `observed` Bloc + Freezed with `part` files (`feed_bloc.dart`, `feed_event.dart`, `feed_state.dart`, `feed_bloc.freezed.dart`).
- `observed` One `BlocStatus<T>` per independent operation, each with a doc comment saying why it is separate.
- `observed` Event handlers are named `_onSomethingHappened`; a handler that must not run twice checks the status first
  (`if (!_statusOf(event.section).isInit) return;`).
- `observed` Magic numbers are named constants on the bloc (`pageSize`, `searchHideThreshold`) with a comment saying what they do.
- `observed` A screen provides its bloc with `BlocProvider(create: ...)` and holds almost nothing else (`feed_screen.dart` is 31 lines).

## Comments and naming

- `observed` Doc comments (`///`) explain **why** and what could go wrong, often with a small ASCII layout for a visual widget; they
  do not restate the code.
- `observed` Names say what a thing is for: `FeedHighlightSlide`, `_LatestList`, `searchHideThreshold`, not `Item2` or `helper`.
- `observed` Files are `snake_case`, one concept each; classes `UpperCamelCase`; private helpers `_Name`.

## Reuse (the rule behind all of this)

1. Before building anything visual or any helper: `dart run tool/widget_catalog.dart <word>` (add `--all` to include feature widgets).
2. A close match → use it; if it needs a small change, add a parameter or a named constructor rather than a copy.
3. Two near-identical widgets already exist, or you are about to write the second copy → **stop and ask the owner** whether to merge
   them (one question, with the options). Never silently duplicate and never silently refactor shared code.
4. The second feature that needs a widget the first one defined privately: move it to `lib/common/widgets/` (or `ds/`), update
   both, and add it to `lib/common/common_folder_guide.md`.

## Corrections log

_Add one line per correction: `date · what the owner said · the rule · why`. Newest first._
