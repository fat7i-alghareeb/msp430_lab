import 'package:flutter/material.dart';

import '../../../domain/entities/topic_entity.dart';

/// The twelve topics grouped by part, as the paper lists them.
class TopicListView extends StatelessWidget {
  const TopicListView({
    super.key,
    required this.topics,
    required this.onOpen,
    this.currentId,
    this.dense = false,
    this.padding = EdgeInsets.zero,
    this.shrinkWrap = false,
  });

  final List<TopicEntity> topics;
  final ValueChanged<TopicEntity> onOpen;
  final int? currentId;
  final bool dense;
  final EdgeInsets padding;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final parts = <int, List<TopicEntity>>{};
    for (final t in topics) {
      parts.putIfAbsent(t.part.index, () => <TopicEntity>[]).add(t);
    }
    final children = <Widget>[];
    for (final entry in parts.entries) {
      final part = entry.value.first.part;
      children.add(
        Padding(
          padding: EdgeInsets.fromLTRB(8, children.isEmpty ? 4 : 14, 8, 4),
          child: Row(
            children: <Widget>[
              CircleAvatar(radius: 4, backgroundColor: part.color),
              const SizedBox(width: 8),
              Text(
                'الجزء ${part.number} · ${part.name}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
      for (final t in entry.value) {
        children.add(
          TopicRow(
            topic: t,
            selected: t.id == currentId,
            dense: dense,
            onTap: () => onOpen(t),
          ),
        );
      }
    }
    return ListView(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      children: children,
    );
  }
}

/// One topic: its number in its part's colour, and its name.
class TopicRow extends StatelessWidget {
  const TopicRow({
    super.key,
    required this.topic,
    required this.onTap,
    this.selected = false,
    this.dense = false,
  });

  final TopicEntity topic;
  final VoidCallback onTap;
  final bool selected;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: dense ? 7 : 10),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: dense ? 12 : 15,
                backgroundColor: topic.part.color,
                child: Text(
                  '${topic.indexInPart}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: dense ? 11.5 : 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  topic.title,
                  style: TextStyle(
                    fontSize: dense ? 13.5 : 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
