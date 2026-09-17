import 'dart:io';

import 'package:test/test.dart';

void main() {
  test(
    'override-deps dry-run reports changes and does not write files',
    () async {
      final tempDir = await Directory.systemTemp.createTemp('depsub_test_');
      try {
        final pubspec = File('${tempDir.path}/pubspec.yaml');
        final local = File('${tempDir.path}/local-deps.yaml');

        await pubspec.writeAsString('''
name: sample
dependencies:
  cupertino_icons: ^1.0.2
dev_dependencies:
  test: ^1.0.0
''');

        await local.writeAsString('''
dependencies:
  cupertino_icons: ^1.0.8
dev_dependencies:

''');

        final result = await Process.run('dart', [
          'run',
          'bin/depsub.dart',
          'run',
          '--root',
          tempDir.path,
          '--dry-run',
        ], workingDirectory: Directory.current.path);

        expect(result.exitCode, equals(0));
        final out = '${result.stdout}${result.stderr}';
        expect(out, contains('Dry run mode'));
        expect(
          out,
          contains('Updated: dependencies:cupertino_icons'.split(':').first),
          reason: 'should mention updated key',
        );

        // ensure no backup file created
        final backup = File('${tempDir.path}/deps-bkp.yaml');
        expect(await backup.exists(), isFalse);
      } finally {
        await tempDir.delete(recursive: true);
      }
    },
  );
}
