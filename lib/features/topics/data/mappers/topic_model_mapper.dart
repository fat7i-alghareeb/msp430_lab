import 'dart:ui';

import '../../domain/entities/topic_entity.dart';
import '../models/topic_model.dart';

extension TopicPartModelMapper on TopicPartModel {
  TopicPartEntity get toEntity =>
      TopicPartEntity(index: index, name: name, color: Color(colorValue));
}

extension TourStepModelMapper on TourStepModel {
  TourStepEntity get toEntity => TourStepEntity(
    title: title,
    text: text,
    action: action,
    focus: focus,
    seconds: seconds,
  );
}

extension TopicModelMapper on TopicModel {
  TopicEntity toEntity(List<TopicPartEntity> parts) => TopicEntity(
    id: id,
    part: parts[part],
    indexInPart: indexInPart,
    title: title,
    shortTitle: shortTitle,
    bookRef: bookRef,
    intro: intro,
    theory: theory,
    tour: tour.map((s) => s.toEntity).toList(),
  );
}
