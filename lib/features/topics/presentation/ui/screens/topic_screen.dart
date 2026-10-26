import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/layout/app_layout.dart';
import '../../../../../core/scene3d/orbit_camera.dart';
import '../../../../../core/scene3d/scene3d_view.dart';
import '../../../../../utils/extensions/context_extensions.dart';
import '../../../../../utils/helpers/app_strings.dart';
import '../../../domain/entities/topic_entity.dart';
import '../../labs/lab_factory.dart';
import '../../labs/topic_lab.dart';
import '../../states/topics_bloc.dart';
import '../../states/tour_controller.dart';
import '../widgets/lab_controls_view.dart';
import '../widgets/topic_list_view.dart';
import '../widgets/tour_bar.dart';

/// A topic: its 3D scene, its self-explaining tour, its values and the
/// controls to try it.
///
/// - **Phone / narrow window**: the scene fills the screen. Over it only two
///   things: the tour bar at the top and a one-line values strip under it.
///   The controls, the theory and the book reference sit in a folded drawer
///   at the bottom; opening it hides the tour bar.
/// - **Wide window (Windows)**: three columns — the topic list, the scene
///   with the tour bar on it, and a panel with the values, the controls,
///   the theory and the reference — and a bottom bar to step topics.
///   Keys: ← next, → previous, Space the tour, Esc back, R the camera.
///
/// Next/Previous swap the topic in place, in the paper's order.
class TopicScreen extends StatefulWidget {
  const TopicScreen({super.key, required this.topicId});

  static const String pagePath = 'topics/:id';
  static const String pageName = 'TopicScreen';
  static const String idParam = 'id';

  final String topicId;

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  late int _id = int.tryParse(widget.topicId)?.clamp(1, 12) ?? 1;

  void _go(int id) => setState(() => _id = id.clamp(1, 12));

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TopicsBloc, TopicsState>(
      builder: (context, state) {
        final topic = state.byId(_id);
        if (topic == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _TopicPage(
          key: ValueKey<int>(_id),
          topic: topic,
          topics: state.topics,
          onOpen: _go,
        );
      },
    );
  }
}

class _TopicPage extends StatefulWidget {
  const _TopicPage({
    super.key,
    required this.topic,
    required this.topics,
    required this.onOpen,
  });

  final TopicEntity topic;
  final List<TopicEntity> topics;
  final ValueChanged<int> onOpen;

  @override
  State<_TopicPage> createState() => _TopicPageState();
}

class _TopicPageState extends State<_TopicPage> with TickerProviderStateMixin {
  late final TopicLab _lab = createLab(widget.topic.id);
  late final OrbitCamera _camera = OrbitCamera(_lab.home);
  late final TourController _tour = TourController(
    steps: widget.topic.tour,
    lab: _lab,
    camera: _camera,
    vsync: this,
  );
  bool _drawerOpen = false;

  TopicEntity get _topic => widget.topic;
  bool get _hasPrev => _topic.id > 1;
  bool get _hasNext => _topic.id < widget.topics.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tour.start();
    });
  }

  @override
  void dispose() {
    _tour.dispose();
    _lab.dispose();
    _camera.dispose();
    super.dispose();
  }

  void _prev() {
    if (_hasPrev) widget.onOpen(_topic.id - 1);
  }

  void _next() {
    if (_hasNext) widget.onOpen(_topic.id + 1);
  }

  void _back() => Navigator.of(context).maybePop();

  void _openList() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheet).height * 0.75,
          ),
          child: TopicListView(
            topics: widget.topics,
            currentId: _topic.id,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            onOpen: (t) {
              Navigator.of(sheet).pop();
              widget.onOpen(t.id);
            },
          ),
        ),
      ),
    );
  }

  Map<ShortcutActivator, VoidCallback> get _keys =>
      <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _next,
        const SingleActivator(LogicalKeyboardKey.pageDown): _next,
        const SingleActivator(LogicalKeyboardKey.arrowRight): _prev,
        const SingleActivator(LogicalKeyboardKey.pageUp): _prev,
        const SingleActivator(LogicalKeyboardKey.space): _tour.toggle,
        const SingleActivator(LogicalKeyboardKey.escape): _back,
        const SingleActivator(LogicalKeyboardKey.keyR): _camera.goHome,
      };

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final wide = layout.isExpandedUp && !layout.isShort;
    return CallbackShortcuts(
      bindings: _keys,
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: const Color(0xFFF7F8F7),
          body: wide ? _wide(context) : _narrow(context, layout),
        ),
      ),
    );
  }

  // ───────────────────────────────────────── shared pieces

  Widget _scene({EdgeInsets tipPadding = const EdgeInsets.all(10)}) =>
      Scene3DView(source: _lab, camera: _camera, tipPadding: tipPadding);

  Widget _values({bool strip = false}) {
    return ListenableBuilder(
      listenable: _lab,
      builder: (context, _) {
        final lines = _lab.values;
        final text = Theme.of(context).textTheme;
        if (strip) {
          return Material(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Text(
                lines.isEmpty ? '' : lines.first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          );
        }
        return Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFE3E8E4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (var i = 0; i < lines.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      lines[i],
                      style: i == 0
                          ? text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            )
                          : text.bodySmall?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _controls() => ListenableBuilder(
    listenable: _lab,
    builder: (context, _) => LabControlsView(controls: _lab.controls),
  );

  Widget _sectionTitle(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _theory(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.55);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: Text(
          AppStrings.topicTheory,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        children: <Widget>[
          Text(
            _topic.intro,
            style: style?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          for (final p in _topic.theory)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: CircleAvatar(
                      radius: 2.5,
                      backgroundColor: _topic.part.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(p, style: style)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _ref(BuildContext context) => Text(
    AppStrings.topicFromBook(_topic.bookRef),
    style: const TextStyle(
      color: Color(0xFFAD5C17),
      fontWeight: FontWeight.w600,
      fontSize: 12.5,
    ),
  );

  Widget _heading(BuildContext context, {bool big = false}) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          AppStrings.topicPartOf(_topic.part.number, _topic.indexInPart),
          style: text.labelMedium?.copyWith(
            color: _topic.part.color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          _topic.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: (big ? text.titleLarge : text.titleMedium)?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────── phone

  Widget _narrow(BuildContext context, AppLayout layout) {
    final media = MediaQuery.of(context);
    return Column(
      children: <Widget>[
        Material(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
              child: Row(
                children: <Widget>[
                  IconButton(
                    tooltip: AppStrings.actionBack,
                    icon: const BackButtonIcon(),
                    onPressed: _back,
                  ),
                  Expanded(child: _heading(context)),
                  IconButton(
                    tooltip: AppStrings.navTopics,
                    icon: const Icon(Icons.format_list_bulleted),
                    onPressed: _openList,
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: _scene(
                  tipPadding: const EdgeInsets.fromLTRB(10, 160, 10, 10),
                ),
              ),
              PositionedDirectional(
                start: 10,
                end: 10,
                top: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _drawerOpen
                          ? const SizedBox.shrink()
                          : TourBar(tour: _tour, compact: true),
                    ),
                    const SizedBox(height: 6),
                    _values(strip: true),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _drawer(context, media.size.height),
              ),
            ],
          ),
        ),
        _bottomNav(context, compact: true),
      ],
    );
  }

  Widget _drawer(BuildContext context, double screenHeight) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      constraints: BoxConstraints(
        maxHeight: _drawerOpen ? screenHeight * 0.48 : 52,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          InkWell(
            onTap: () => setState(() => _drawerOpen = !_drawerOpen),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.touch_app_outlined,
                      color: scheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.topicTryIt,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Icon(_drawerOpen ? Icons.expand_more : Icons.expand_less),
                  ],
                ),
              ),
            ),
          ),
          if (_drawerOpen)
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                shrinkWrap: true,
                children: <Widget>[
                  _controls(),
                  _values(),
                  const SizedBox(height: 4),
                  _theory(context),
                  _ref(context),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _bottomNav(BuildContext context, {required bool compact}) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFEEF1EE))),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 18,
            vertical: 8,
          ),
          child: Row(
            children: <Widget>[
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: compactButtonSize),
                onPressed: _hasPrev ? _prev : null,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text(
                  compact ? AppStrings.actionBack : AppStrings.topicPrevious,
                ),
              ),
              Expanded(
                child: Text(
                  compact
                      ? AppStrings.topicCounter(_topic.id)
                      : '${AppStrings.topicCounter(_topic.id)} · ${_topic.title}\n${AppStrings.topicKeys}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12.5,
                  ),
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: compactButtonSize),
                onPressed: _hasNext ? _next : null,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text(AppStrings.topicNext),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────── Windows / wide

  Widget _wide(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: <Widget>[
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // The topic list, on the start side.
              Container(
                width: 260,
                color: const Color(0xFFF0F2F0),
                child: SafeArea(
                  right: false,
                  left: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
                        child: Row(
                          children: <Widget>[
                            IconButton(
                              tooltip: AppStrings.actionBack,
                              icon: const BackButtonIcon(),
                              onPressed: _back,
                            ),
                            Text(
                              AppStrings.navTopics,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TopicListView(
                          topics: widget.topics,
                          currentId: _topic.id,
                          dense: true,
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                          onOpen: (t) => widget.onOpen(t.id),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // The scene.
              Expanded(
                child: Column(
                  children: <Widget>[
                    Container(
                      color: const Color(0xFFFBFCFB),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(child: _heading(context, big: true)),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: compactButtonSize,
                            ),
                            onPressed: _camera.goHome,
                            icon: const Icon(
                              Icons.center_focus_strong_outlined,
                              size: 18,
                            ),
                            label: Text(AppStrings.topicResetCamera),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: <Widget>[
                          Positioned.fill(child: _scene()),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 640,
                                ),
                                child: TourBar(tour: _tour),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Values, controls, theory, reference.
              Container(
                width: 340,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFCFB),
                  border: BorderDirectional(
                    start: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                // Its own Material: the theory's ExpansionTile paints on it.
                child: Material(
                  type: MaterialType.transparency,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      _sectionTitle(context, AppStrings.topicValues),
                      _values(),
                      const SizedBox(height: 14),
                      _sectionTitle(context, AppStrings.topicTryIt),
                      _controls(),
                      _theory(context),
                      const SizedBox(height: 6),
                      _ref(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _bottomNav(context, compact: false),
      ],
    );
  }
}
