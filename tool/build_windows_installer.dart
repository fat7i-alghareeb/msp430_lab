// Builds the Windows app and wraps it in a `setup.exe` with Inno Setup — free,
// open source, and the installer people expect: a wizard, a Start menu entry,
// an uninstaller.
//
//   dart run tool/build_windows_installer.dart
//   dart run tool/build_windows_installer.dart --skip-build   # reuse the last build
//   dart run tool/build_windows_installer.dart --iscc "D:\Tools\Inno Setup 6\ISCC.exe"
//
// Needs Inno Setup 6 (https://jrsoftware.org/isinfo.php — free) on a Windows
// PC. The result is `build/installer/<name>-<version>-setup.exe`.
//
// Windows shows its «unknown publisher» SmartScreen warning for an installer
// that is not code-signed, until enough people have downloaded it. Signing
// costs money; the Microsoft Store route (MSIX, `dart run msix:create
// --store`) has no warning and is free for individuals. docs/DESKTOP_SETUP.md
// compares them.
//
// Everything the script needs — name, version, title — is read from the project, so there is nothing to keep in step.
//
// ignore_for_file: avoid_print

import 'dart:io';

Future<void> main(List<String> args) async {
  if (!Platform.isWindows) {
    stderr.writeln('The installer is built on Windows.');
    exitCode = 1;
    return;
  }

  final skipBuild = args.contains('--skip-build');
  final isccArg = _valueOf(args, '--iscc');

  final project = _Project.read();

  if (!skipBuild) {
    print('Building the Windows app…');
    final build = await Process.start(
      'flutter',
      <String>['build', 'windows', '--release'],
      runInShell: true,
      mode: ProcessStartMode.inheritStdio,
    );
    if (await build.exitCode != 0) {
      stderr.writeln('flutter build windows failed.');
      exitCode = 1;
      return;
    }
  }

  final release = _releaseFolder(project.name);
  if (release == null) {
    stderr.writeln(
      'No Windows build found under build/windows. Run without --skip-build.',
    );
    exitCode = 1;
    return;
  }

  final output = Directory('build/installer')..createSync(recursive: true);
  final script = File('${output.path}/${project.name}.iss')
    ..writeAsStringSync(_script(project, release, output.absolute.path));
  print('Wrote ${script.path}');

  final iscc = _findIscc(isccArg);
  if (iscc == null) {
    stderr.writeln(
      'Inno Setup was not found. Install it (free) from '
      'https://jrsoftware.org/isdl.php, or point to it with --iscc. '
      'The script is ready at ${script.path}.',
    );
    exitCode = 1;
    return;
  }

  final compile = await Process.start(
    iscc,
    <String>[script.absolute.path],
    mode: ProcessStartMode.inheritStdio,
  );
  if (await compile.exitCode != 0) {
    stderr.writeln('Inno Setup failed.');
    exitCode = 1;
    return;
  }
  print(
    '\nDone: build/installer/${project.name}-${project.version}-setup.exe',
  );
}

class _Project {
  _Project({
    required this.name,
    required this.version,
    required this.title,
    required this.guid,
  });

  final String name;
  final String version;
  final String title;
  final String guid;

  static _Project read() {
    String read(String path) {
      final file = File(path);
      if (!file.existsSync()) {
        throw StateError('$path not found — run from the project root.');
      }
      return file.readAsStringSync();
    }

    String? first(String source, String pattern) =>
        RegExp(pattern, multiLine: true).firstMatch(source)?.group(1);

    final pubspec = read('pubspec.yaml');
    final config = read('lib/core/config/app_config.dart');

    final name = first(pubspec, r'^name:\s*(\S+)');
    // 1.2.3+4 → the part before the build number: Inno shows it to people.
    final version = first(pubspec, r'^version:\s*([^\s+]+)');
    final title = first(config, r'''appTitle\s*=\s*['"]([^'"]+)['"]''');
    final guid = first(config, r'''windowsToastGuid\s*=\s*\n?\s*['"]([^'"]+)['"]''');

    if (name == null || version == null || title == null) {
      throw StateError('Could not read name, version or title from the project.');
    }
    return _Project(
      name: name,
      version: version,
      title: title,
      guid: guid ?? '{{8F3B2C1A-5D4E-4A7B-9C6D-2E1F0A9B8C7D}',
    );
  }
}

String? _valueOf(List<String> args, String flag) {
  final index = args.indexOf(flag);
  return index >= 0 && index + 1 < args.length ? args[index + 1] : null;
}

/// Flutter writes the build to `build/windows/x64/runner/Release` (older
/// versions without the `x64` folder).
Directory? _releaseFolder(String name) {
  for (final path in <String>[
    'build/windows/x64/runner/Release',
    'build/windows/runner/Release',
  ]) {
    final dir = Directory(path);
    if (File('${dir.path}/$name.exe').existsSync()) return dir;
  }
  return null;
}

String? _findIscc(String? given) {
  final candidates = <String>[
    ?given,
    for (final base in <String?>[
      Platform.environment['ProgramFiles(x86)'],
      Platform.environment['ProgramFiles'],
      Platform.environment['LOCALAPPDATA'] == null
          ? null
          : '${Platform.environment['LOCALAPPDATA']}\\Programs',
    ])
      if (base != null) '$base\\Inno Setup 6\\ISCC.exe',
  ];
  for (final path in candidates) {
    if (File(path).existsSync()) return path;
  }
  // On the PATH?
  final result = Process.runSync('where', <String>['ISCC.exe'], runInShell: true);
  if (result.exitCode == 0) {
    final line = (result.stdout as String).split('\n').first.trim();
    if (line.isNotEmpty) return line;
  }
  return null;
}

String _script(_Project p, Directory release, String outputDir) {
  final exe = '${p.name}.exe';
  final source = release.absolute.path;
  final icon = File('windows/runner/resources/app_icon.ico');
  // Inno's own constants are single-braced: {app}, {group}, {autopf}.
  return '''
; Generated by tool/build_windows_installer.dart — edit the tool, not this.
[Setup]
; Any string works as the id; Inno uses it to recognise an earlier install of
; the SAME app, so an update replaces it instead of installing beside it.
; The project's own GUID: changing it makes Windows see a different app.
AppId=${p.guid}
AppName=${p.title}
AppVersion=${p.version}
AppPublisher=${p.title}
DefaultDirName={autopf}\\${p.title}
DefaultGroupName=${p.title}
OutputDir=$outputDir
OutputBaseFilename=${p.name}-${p.version}-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
; Flutter's Windows builds are 64-bit.
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Installs for the current user by default, no administrator prompt; the
; dialog offers «for all users» to anyone who wants it.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
UninstallDisplayIcon={app}\\$exe
${icon.existsSync() ? 'SetupIconFile=${icon.absolute.path}' : '; SetupIconFile: add windows/runner/resources/app_icon.ico'}

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; Flags: unchecked

[Files]
Source: "$source\\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{group}\\${p.title}"; Filename: "{app}\\$exe"
Name: "{autodesktop}\\${p.title}"; Filename: "{app}\\$exe"; Tasks: desktopicon

[Run]
Filename: "{app}\\$exe"; Description: "Launch ${p.title}"; Flags: nowait postinstall skipifsilent
''';
}
