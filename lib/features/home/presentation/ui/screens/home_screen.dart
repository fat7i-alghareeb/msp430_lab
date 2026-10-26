import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/router/app_navigator.dart';
import '../../../../../core/scene3d/orbit_camera.dart';
import '../../../../../core/scene3d/scene3d_view.dart';
import '../../../../../utils/extensions/context_extensions.dart';
import '../../../../../utils/helpers/app_strings.dart';
import '../../../../topics/domain/entities/topic_entity.dart';
import '../../../../topics/presentation/states/topics_bloc.dart';
import '../../../../topics/presentation/ui/widgets/topic_list_view.dart';
import '../../states/home_chip_scene.dart';

/// The first tab: the chip in 3D with a numbered dot per topic. Tapping a
/// dot glides the camera to it, then opens the topic.
///
/// Phone: the chip on top, the parts and their topics below it.
/// Wide window: the chip beside a panel with the colour legend and the list.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TopicsBloc, TopicsState>(
      builder: (context, state) {
        final topics = state.topics;
        if (topics.isEmpty) return const Center(child: CircularProgressIndicator());
        return _HomeBody(topics: topics);
      },
    );
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody({required this.topics});

  final List<TopicEntity> topics;

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  late final HomeChipScene _scene = HomeChipScene(widget.topics);
  OrbitCamera? _cameraOrNull;
  OrbitCamera get _camera => _cameraOrNull!;
  int _part = 0;

  @override
  void dispose() {
    _cameraOrNull?.dispose();
    super.dispose();
  }

  void _open(TopicEntity t) {
    AppNavigator.push<void>(context, AppPage.topic, params: <String, String>{'id': '${t.id}'});
  }

  void _fromHotspot(String id) {
    final topicId = int.parse(id.split(':').last);
    final topic = widget.topics.firstWhere((t) => t.id == topicId);
    final at = HomeChipScene.spots[topicId];
    if (at != null) _camera.focus(at, closeness: 0.42);
    Future<void>.delayed(const Duration(milliseconds: 750), () {
      if (!mounted) return;
      _open(topic);
      _camera.goHome();
    });
  }

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final wide = layout.isExpandedUp && !layout.isShort;
    _cameraOrNull ??= OrbitCamera(wide ? _scene.home : HomeChipScene.phoneHome);
    final scene = Scene3DView(source: _scene, camera: _camera, onHotspot: _fromHotspot);
    final title = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AppStrings.appName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            AppStrings.homeHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(borderRadius: BorderRadius.circular(18), child: scene),
            ),
          ),
          SizedBox(
            width: 330,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  title,
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      AppStrings.homePick,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                  Expanded(
                    child: TopicListView(
                      topics: widget.topics,
                      dense: true,
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                      onOpen: _open,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final parts = <TopicPartEntity>[];
    for (final t in widget.topics) {
      if (!parts.any((p) => p.index == t.part.index)) parts.add(t.part);
    }
    final inPart = widget.topics.where((t) => t.part.index == _part).toList();
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          title,
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ClipRRect(borderRadius: BorderRadius.circular(18), child: scene),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: <Widget>[
                for (final p in parts)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _PartTab(
                        part: p,
                        selected: p.index == _part,
                        onTap: () => setState(() => _part = p.index),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 110),
              children: <Widget>[
                for (final t in inPart) TopicRow(topic: t, onTap: () => _open(t)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PartTab extends StatelessWidget {
  const _PartTab({required this.part, required this.selected, required this.onTap});

  final TopicPartEntity part;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? part.color : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? part.color : const Color(0xFFE3E8E4), width: 1.5),
          ),
          child: Column(
            children: <Widget>[
              Text(
                'الجزء ${part.number}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: selected ? Colors.white : const Color(0xFF5A6670),
                ),
              ),
              Text(
                part.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  color: selected ? Colors.white : const Color(0xFF5A6670),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
