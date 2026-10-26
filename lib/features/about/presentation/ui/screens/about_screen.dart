import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../common/widgets/ds/app_content_width.dart';
import '../../../../../utils/helpers/app_strings.dart';
import '../../../../topics/presentation/states/topics_bloc.dart';

/// The «About» tab: what the app is, its sources, and the topics with the
/// book's page numbers.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final topics = context.select((TopicsBloc b) => b.state.topics);
    return SafeArea(
      bottom: false,
      child: AppContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: <Widget>[
            Text(AppStrings.aboutTitle, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(AppStrings.aboutBody, style: text.bodyLarge?.copyWith(height: 1.6)),
            const SizedBox(height: 22),
            Text(AppStrings.aboutSources, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('• ${AppStrings.aboutBook}', textDirection: TextDirection.ltr, style: text.bodyMedium),
            Text('• ${AppStrings.aboutDatasheet}', style: text.bodyMedium),
            const SizedBox(height: 22),
            Text(AppStrings.aboutTopics, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            for (final t in topics)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: t.part.color,
                      child: Text(
                        '${t.indexInPart}',
                        style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(t.title, style: text.bodyMedium)),
                    Text(t.bookRef, style: text.bodySmall?.copyWith(color: muted)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
