import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:depsub/console/console_logger.dart';

class InitCommand extends Command {
  @override
  String get description =>
      'Initialize flutter project with necessary substitution files';

  @override
  String get name => "init";

  late final ConsoleLogger logger = ConsoleLogger();

  @override
  void run() {
    final localSubstitutionFile = File('local-deps.yaml');

    if (!localSubstitutionFile.existsSync()) {
      localSubstitutionFile.createSync();

      localSubstitutionFile.writeAsStringSync('''dependencies:
  - cupertino_icons: ^1.0.8
dev_dependencies:
''');

      logger.success(
        'Initialized local substitution file: ${localSubstitutionFile.path}',
      );

      return;
    }

    logger.warning(
      'Local substitution file already exists: ${localSubstitutionFile.path}',
    );
  }
}
