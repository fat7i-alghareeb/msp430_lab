/// A topic as the data source stores it: plain values only.
class TopicModel {
  const TopicModel({
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

  final int id;

  /// 0, 1 or 2.
  final int part;
  final int indexInPart;
  final String title;
  final String shortTitle;
  final String bookRef;
  final String intro;
  final List<String> theory;
  final List<TourStepModel> tour;
}

class TourStepModel {
  const TourStepModel(
    this.title,
    this.text, {
    this.action,
    this.focus,
    this.seconds = 4,
  });

  final String title;
  final String text;
  final String? action;
  final String? focus;
  final double seconds;
}

class TopicPartModel {
  const TopicPartModel(this.index, this.name, this.colorValue);

  final int index;
  final String name;
  final int colorValue;
}
