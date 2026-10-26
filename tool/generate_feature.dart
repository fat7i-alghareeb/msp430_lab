import 'dart:async';
import 'dart:convert';
import 'dart:io';

// Feature scaffolding generator.
//
// Usage:
//   dart run tool/generate_feature.dart product
//   dart run tool/generate_feature.dart "user profile"
//
// Flags:
//   --force / -f  Deletes the existing feature folder (if any) and recreates it.
//
// What you get (lib/features/<name>/):
//   data/     model · local data source · mapper · repository impl · params
//   domain/   entity · repository contract · facade
//   presentation/
//     states/ bloc + freezed event/state, one BlocStatus per operation
//     ui/screens/<name>_screen.dart   BlocProvider + body
//     ui/widgets/<name>_body.dart     skeleton list → rows revealed on
//                                     scroll · empty · failed with retry ·
//                                     pull to refresh (AppRefresh)
//     ui/widgets/<name>_card.dart     a SkeletonWidget: .success / .loading
//                                     over ONE layout
//   constants/
//
// Then: register the route (`AppPage` in core/router/app_routes.dart), add a
// height-parity line for the card to test/common/widgets/ds/
// skeleton_parity_test.dart, and write the feature's strings in
// assets/l10n/*.json (dart run tool/generate_app_strings.dart).

String _pluralizePascal(String pascal) {
  if (pascal.endsWith('y') && pascal.length > 1) {
    return '${pascal.substring(0, pascal.length - 1)}ies';
  }
  if (pascal.endsWith('s') || pascal.endsWith('x')) {
    return '${pascal}es';
  }
  if (pascal.endsWith('ch') || pascal.endsWith('sh')) {
    return '${pascal}es';
  }
  return '${pascal}s';
}

Future<void> main(List<String> args) async {
  _log('Feature generator starting...', icon: '🧩');

  final force = args.any((a) => a == '--force' || a == '-f');
  final rawName = _readFeatureName(args);
  final name = FeatureName.parse(rawName);

  final featureRoot = Directory('lib/features/${name.snake}');
  if (await featureRoot.exists()) {
    if (!force) {
      stderr.writeln('⚠️ Feature already exists: ${featureRoot.path}');
      stdout.write('Delete and recreate it? (y/N): ');
      final choice = stdin.readLineSync()?.trim().toLowerCase();
      if (choice != 'y' && choice != 'yes') {
        exitCode = 1;
        return;
      }
    }

    _log('Deleting existing feature folder...', icon: '🗑️');
    await featureRoot.delete(recursive: true);
  }

  try {
    _log('Generating files...', icon: '🛠️');
    await _writeFeatureFiles(name);

    _log('Created feature: ${name.snake}', icon: '✅');
    await _runBuildRunner();
  } catch (e) {
    stderr.writeln('❌ Generation failed: $e');
    exitCode = 1;
  }
}

void _log(String message, {String icon = '•'}) {
  stdout.writeln('$icon $message');
}

Future<void> _runBuildRunner() async {
  const cmd = ['run', 'build_runner', 'build', '--delete-conflicting-outputs'];
  _log('Running: dart ${cmd.join(' ')}', icon: '🏗️');
  final sw = Stopwatch()..start();

  final process = await Process.start('dart', cmd, runInShell: true);

  final heartbeat = Timer.periodic(
    const Duration(seconds: 5),
    (_) => stdout.writeln('⏳ build_runner still running...'),
  );

  unawaited(
    process.stdout
        .transform(const SystemEncoding().decoder)
        .transform(const LineSplitter())
        .forEach(stdout.writeln),
  );
  unawaited(
    process.stderr
        .transform(const SystemEncoding().decoder)
        .transform(const LineSplitter())
        .forEach(stderr.writeln),
  );

  final exit = await process.exitCode;
  heartbeat.cancel();
  if (exit != 0) {
    sw.stop();
    stderr.writeln(
      '❌ build_runner failed with exitCode=$exit (took ${sw.elapsed})',
    );
    exitCode = exit;
    return;
  }

  sw.stop();
  _log('build_runner finished successfully (took ${sw.elapsed}).', icon: '✅');
}

String _readFeatureName(List<String> args) {
  final nameArgs = args
      .where((e) => e.trim().isNotEmpty)
      .where((e) => e != '--force' && e != '-f')
      .toList();

  if (nameArgs.isNotEmpty) {
    return nameArgs.join(' ').trim();
  }

  stdout.write('Enter feature name: ');
  final input = stdin.readLineSync();
  if (input == null || input.trim().isEmpty) {
    stderr.writeln('Feature name is required');
    exitCode = 1;
    exit(1);
  }
  return input.trim();
}

final class FeatureName {
  FeatureName._({
    required this.raw,
    required this.snake,
    required this.pascal,
    required this.camel,
  });

  final String raw;
  final String snake;
  final String pascal;
  final String camel;

  static FeatureName parse(String raw) {
    final cleaned = raw.trim();

    final normalized = cleaned
        .replaceAll(RegExp(r'([a-z0-9])([A-Z])'), r'$1 $2')
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), ' ')
        .trim();

    final parts = normalized
        .split(RegExp(r'\s+'))
        .where((p) => p.trim().isNotEmpty)
        .map((p) => p.toLowerCase())
        .toList();

    if (parts.isEmpty) {
      throw ArgumentError('Invalid feature name: "$raw"');
    }

    var snake = parts.join('_');
    var pascal = parts.map(_capitalize).join();
    var camel = parts.first + parts.skip(1).map(_capitalize).join();

    if (!RegExp(r'^[a-zA-Z_]').hasMatch(snake)) {
      snake = 'feature_$snake';
    }
    if (!RegExp(r'^[A-Za-z_]').hasMatch(pascal)) {
      pascal = 'Feature$pascal';
    }
    if (!RegExp(r'^[a-zA-Z_]').hasMatch(camel)) {
      camel = 'feature$pascal';
    }

    return FeatureName._(raw: raw, snake: snake, pascal: pascal, camel: camel);
  }
}

String _capitalize(String input) {
  if (input.isEmpty) return '';
  if (input.length == 1) return input.toUpperCase();
  return input[0].toUpperCase() + input.substring(1);
}

Future<void> _writeFeatureFiles(FeatureName name) async {
  final base = 'lib/features/${name.snake}';

  Future<void> write(String path, String content) async {
    final file = File('$base/$path');
    if (await file.exists()) {
      throw StateError('File already exists: ${file.path}');
    }
    await file.create(recursive: true);
    await file.writeAsString(content);
  }

  final modelName = '${name.pascal}Model';
  final entityName = '${name.pascal}Entity';
  final repositoryName = '${name.pascal}Repository';
  final repositoryImplName = '${name.pascal}RepositoryImpl';
  final localName = '${name.pascal}LocalDataSource';
  final facadeName = '${name.pascal}Facade';
  final blocName = '${name.pascal}Bloc';
  final pluralPascal = _pluralizePascal(name.pascal);

  await write(
    'data/params/${name.snake}_params.dart',
    """class ${name.pascal}Params {
  const ${name.pascal}Params();
}
""",
  );

  await write(
    'data/datasources/${name.snake}_local_datasource.dart',
    """import 'package:injectable/injectable.dart';

import '../../../../core/error/global_error_handler.dart';
import '../models/${name.snake}_model.dart';

@lazySingleton
class $localName {
  const $localName();

  /// Content that ships with the app: no network, nothing to fail.
  Future<List<$modelName>> getAll$pluralPascal() {
    return rethrowAsAppException(() async {
      return const <$modelName>[];
    });
  }
}
""",
  );

  await write('data/models/${name.snake}_model.dart', """class $modelName {
  const $modelName({required this.id});

  final String id;
}
""");

  await write(
    'domain/entities/${name.snake}_entity.dart',
    """class $entityName {
  const $entityName({required this.id});

  final String id;
}
""",
  );

  await write(
    'data/mappers/${name.snake}_model_mapper.dart',
    """import '../../domain/entities/${name.snake}_entity.dart';
import '../models/${name.snake}_model.dart';

extension ${name.pascal}ModelMapper on $modelName {
  $entityName get toEntity => $entityName(id: id);
}
""",
  );

  await write(
    'domain/repositories/${name.snake}_repository.dart',
    """import '../../../../core/utils/result.dart';
import '../entities/${name.snake}_entity.dart';

abstract class $repositoryName {
  Future<Result<List<$entityName>>> getAll$pluralPascal();
}
""",
  );

  await write(
    'data/repositories/${name.snake}_repository_impl.dart',
    """import 'package:injectable/injectable.dart';

import '../../../../core/error/global_error_handler.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/${name.snake}_entity.dart';
import '../../domain/repositories/${name.snake}_repository.dart';
import '../datasources/${name.snake}_local_datasource.dart';
import '../mappers/${name.snake}_model_mapper.dart';

@LazySingleton(as: $repositoryName)
class $repositoryImplName implements $repositoryName {
  const $repositoryImplName(this._local);

  final $localName _local;

  @override
  Future<Result<List<$entityName>>> getAll$pluralPascal() {
    return runAsResult(() async {
      final models = await _local.getAll$pluralPascal();
      return models.map((e) => e.toEntity).toList();
    });
  }
}
""",
  );

  await write(
    'domain/facade/${name.snake}_facade.dart',
    """import 'package:injectable/injectable.dart';

import '../../../../core/utils/result.dart';
import '../entities/${name.snake}_entity.dart';
import '../repositories/${name.snake}_repository.dart';

@lazySingleton
class $facadeName {
  const $facadeName(this._repository);

  final $repositoryName _repository;

  Future<Result<List<$entityName>>> getAll$pluralPascal() {
    return _repository.getAll$pluralPascal();
  }
}
""",
  );

  await write(
    'presentation/states/${name.snake}_bloc.dart',
    """import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/bloc_status.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/${name.snake}_entity.dart';
import '../../domain/facade/${name.snake}_facade.dart';

part '${name.snake}_event.dart';
part '${name.snake}_state.dart';
part '${name.snake}_bloc.freezed.dart';

@injectable
class $blocName extends Bloc<${name.pascal}Event, ${name.pascal}State> {
  $blocName(this._facade) : super(const ${name.pascal}State()) {
    on<_Started>(_onStarted);
    on<_GetAllRequested>(_onGetAllRequested);
  }

  final $facadeName _facade;

  Future<void> _onStarted(_Started event, Emitter<${name.pascal}State> emit) {
    return _onGetAllRequested(const _GetAllRequested(), emit);
  }

  Future<void> _onGetAllRequested(
    _GetAllRequested event,
    Emitter<${name.pascal}State> emit,
  ) async {
    emit(state.copyWith(getAllState: const BlocStatus.loading()));

    final result = await _facade.getAll$pluralPascal();
    result.when(
      success: (data) => emit(state.copyWith(getAllState: BlocStatus.success(data))),
      failure: (message) => emit(state.copyWith(getAllState: BlocStatus.failure(message))),
    );
  }
}
""",
  );

  await write(
    'presentation/states/${name.snake}_event.dart',
    """part of '${name.snake}_bloc.dart';

@freezed
class ${name.pascal}Event with _\$${name.pascal}Event {
  const factory ${name.pascal}Event.started() = _Started;
  const factory ${name.pascal}Event.getAllRequested() = _GetAllRequested;
}
""",
  );

  await write(
    'presentation/states/${name.snake}_state.dart',
    """part of '${name.snake}_bloc.dart';

@freezed
abstract class ${name.pascal}State with _\$${name.pascal}State {
  const factory ${name.pascal}State({
    @Default(BlocStatus<List<$entityName>>.initial())
    BlocStatus<List<$entityName>> getAllState,
  }) = _${name.pascal}State;
}
""",
  );

  await write(
    'presentation/ui/screens/${name.snake}_screen.dart',
    """import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/injection/injectable.dart';
import '../../states/${name.snake}_bloc.dart';
import '../widgets/${name.snake}_body.dart';

/// Register it in `AppPage` (core/router/app_routes.dart) and open it with
/// `AppNavigator.push(context, AppPage.${name.camel})`. As a TAB, drop the
/// Scaffold: the shell owns it.
class ${name.pascal}Screen extends StatelessWidget {
  const ${name.pascal}Screen({super.key});

  /// Relative: pages are nested under the page that opens them.
  static const String pagePath = '${name.snake.replaceAll('_', '-')}';
  static const String pageName = '${name.pascal}Screen';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<$blocName>(
      create: (_) => getIt<$blocName>()..add(const ${name.pascal}Event.started()),
      child: Scaffold(
        appBar: AppBar(title: const Text('${name.pascal}')),
        body: const ${name.pascal}Body(),
      ),
    );
  }
}
""",
  );

  await write(
    'presentation/ui/widgets/${name.snake}_body.dart',
    """import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../common/widgets/ds/ds.dart';
import '../../../../../common/widgets/empty_state_widget.dart';
import '../../../../../common/widgets/failed_state_widget.dart';
import '../../../../../common/widgets/scroll_reveal.dart';
import '../../../../../core/utils/bloc_status.dart';
import '../../../../../utils/constants/design_constants.dart';
import '../../states/${name.snake}_bloc.dart';
import '${name.snake}_card.dart';

/// Every state of the list, in one place:
/// loading → skeleton rows (the card's own `.loading()`), success → rows
/// that rise in as they scroll into view, empty, failed with retry — and
/// pull to refresh on all of them.
class ${name.pascal}Body extends StatelessWidget {
  const ${name.pascal}Body({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<$blocName>();
    return BlocBuilder<$blocName, ${name.pascal}State>(
      buildWhen: (previous, current) =>
          previous.getAllState != current.getAllState,
      builder: (context, state) {
        final status = state.getAllState;
        if (status.isFailed) {
          return FailedStateWidget(
            message: status.errorMessage,
            onRetrying: () =>
                bloc.add(const ${name.pascal}Event.getAllRequested()),
          );
        }
        final items = status.getDataWhenSuccess;
        if (items != null && items.isEmpty) {
          return const EmptyStateWidget();
        }
        return AppRefresh(
          onRefresh: () async {
            bloc.add(const ${name.pascal}Event.getAllRequested());
            await bloc.stream.firstWhere((s) => !s.getAllState.isLoading);
          },
          child: ListView.separated(
            // Pull to refresh keeps working when the list is short.
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            itemCount: items?.length ?? 6,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.cardGap),
            itemBuilder: (context, index) => items == null
                ? const ${name.pascal}Card.loading()
                : ${name.pascal}Card.success(
                    item: items[index],
                  ).revealOnScroll(id: items[index].id),
          ),
        );
      },
    );
  }
}
""",
  );

  await write(
    'presentation/ui/widgets/${name.snake}_card.dart',
    """import 'package:flutter/material.dart';

import '../../../../../common/widgets/ds/ds.dart';
import '../../../domain/entities/${name.snake}_entity.dart';

/// One row. ONE layout, two constructors: `.loading()` swaps the leaves
/// (`SkeletonText`, `SkeletonBox`) and nothing else, so the skeleton can
/// never drift from the card. Add a height-parity line for it in
/// test/common/widgets/ds/skeleton_parity_test.dart.
class ${name.pascal}Card extends SkeletonWidget {
  const ${name.pascal}Card.success({super.key, required $entityName this.item})
    : super.success();

  const ${name.pascal}Card.loading({super.key}) : item = null, super.loading();

  final $entityName? item;

  @override
  Widget buildBody(BuildContext context) {
    final data = item;
    return AppCard(
      onTap: data == null ? null : () {},
      child: SkeletonText(
        data?.id,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}
""",
  );

  await write(
    'constants/${name.snake}_constants.dart',
    """abstract class ${name.pascal}Constants {
  static const String featureName = '${name.snake}';
}
""",
  );
}
