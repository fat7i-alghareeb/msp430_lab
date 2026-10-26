import '../../../../../common/imports/imports.dart';
import '../../../../../common/widgets/custom_scaffold/app_scaffold.dart';

/// A topic page, pushed over the shell. A placeholder that shows how a page
/// reads its path parameter; the real content comes with the feature.
class TopicScreen extends StatelessWidget {
  const TopicScreen({super.key, required this.topicId});

  static const String pagePath = 'topics/:id';
  static const String pageName = 'TopicScreen';
  static const String idParam = 'id';

  final String topicId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold.body(
      child: Center(child: Text(topicId)),
    );
  }
}
