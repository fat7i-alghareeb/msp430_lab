
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msp430_lab/core/injection/injectable.dart';
import 'package:msp430_lab/core/layout/app_layout_scope.dart';
import 'package:msp430_lab/core/theme/app_theme.dart';
import 'package:msp430_lab/features/home/presentation/ui/screens/home_screen.dart';
import 'package:msp430_lab/features/topics/presentation/states/topics_bloc.dart';
import 'package:msp430_lab/features/topics/presentation/ui/screens/topic_screen.dart';

/// Opens every topic and the home screen at a phone size and a Windows size,
/// lets the tour run, and checks nothing throws. With `--update-goldens` it
/// also writes a picture of each (`goldens/`), to look at the scenes.
void main() {
  setUpAll(() async {
    configureDependencies();
    for (final weight in <String>['Regular', 'Medium', 'Bold']) {
      final loader = FontLoader('Tajawal')
        ..addFont(rootBundle.load('assets/fonts/Tajawal-$weight.ttf'));
      await loader.load();
    }
  });

  const phone = Size(390, 800);
  const desktop = Size(1280, 800);

  Future<void> open(WidgetTester tester, Widget screen, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<TopicsBloc>(
        create: (_) => getIt<TopicsBloc>()..add(const TopicsEvent.started()),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: AppLayoutHost(child: child!),
          ),
          home: screen,
        ),
      ),
    );
    // Let the topics load and the tour run a few steps.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 12));
  }

  for (final (name, size) in <(String, Size)>[('phone', phone), ('desktop', desktop)]) {
    testWidgets('home on $name', (tester) async {
      await open(tester, const Scaffold(body: HomeScreen()), size);
      expect(tester.takeException(), isNull);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/home_$name.png'));
      await close(tester);
    });

    for (var id = 1; id <= 12; id++) {
      testWidgets('topic $id on $name', (tester) async {
        await open(tester, TopicScreen(topicId: '$id'), size);
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/topic_${id}_$name.png'),
        );
        await close(tester);
      });
    }
  }
}
