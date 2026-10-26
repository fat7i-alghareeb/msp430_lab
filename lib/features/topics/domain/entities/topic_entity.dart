import 'dart:ui';

/// One of the paper's three parts.
class TopicPartEntity {
  const TopicPartEntity({
    required this.index,
    required this.name,
    required this.color,
  });

  /// 0, 1 or 2.
  final int index;
  final String name;
  final Color color;

  /// «1», «2» or «3», as the app shows it.
  int get number => index + 1;
}

/// One step of a topic's self-explaining tour.
class TourStepEntity {
  const TourStepEntity({
    required this.title,
    required this.text,
    this.action,
    this.focus,
    this.seconds = 4,
  });

  /// Two to five words, in bold.
  final String title;

  /// One sentence.
  final String text;

  /// What the scene does in this step, by the lab's own name for it.
  final String? action;

  /// Where the camera goes: a part of the scene by name, `home` for the
  /// whole scene, null to stay.
  final String? focus;

  /// How long the step stays before the next one.
  final double seconds;
}

/// A topic of the paper: its place, its words and its tour.
class TopicEntity {
  const TopicEntity({
    required this.id,
    required this.part,
    required this.indexInPart,
    required this.title,
    required this.shortTitle,
    required this.bookRef,
    required this.intro,
    required this.theory,
    required this.tour,
  });

  /// 1 to 12, in the paper's order.
  final int id;
  final TopicPartEntity part;

  /// 1 to 4 inside its part.
  final int indexInPart;
  final String title;
  final String shortTitle;

  /// «الفصل 5 · ص 69–72».
  final String bookRef;

  /// Two sentences on what the topic is.
  final String intro;

  /// The theory the scene illustrates, as short points.
  final List<String> theory;
  final List<TourStepEntity> tour;

  /// «2.3».
  String get code => '${part.number}.$indexInPart';
}
