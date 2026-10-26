import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../common/widgets/ds/app_content_width.dart';
import '../../../../../core/router/app_navigator.dart';
import '../../../../../utils/helpers/app_strings.dart';
import '../../states/topics_bloc.dart';
import '../widgets/topic_list_view.dart';

/// The «Topics» tab: the twelve topics by part, as the paper lists them.
class TopicsListScreen extends StatelessWidget {
  const TopicsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TopicsBloc, TopicsState>(
      builder: (context, state) {
        final topics = state.topics;
        if (topics.isEmpty) return const Center(child: CircularProgressIndicator());
        return SafeArea(
          bottom: false,
          child: AppContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    AppStrings.navTopics,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: TopicListView(
                    topics: topics,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 110),
                    onOpen: (t) => AppNavigator.push<void>(
                      context,
                      AppPage.topic,
                      params: <String, String>{'id': '${t.id}'},
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
}
