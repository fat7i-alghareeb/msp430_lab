import 'bootstrap.dart';
import 'app.dart';

/// [args] matter on desktop only: a second launch on Windows hands its
/// arguments — a link it was opened with — to the running window.
void main(List<String> args) async {
  await bootstrap(() async => const App(), args: args);
}
