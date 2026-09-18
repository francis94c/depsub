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
  cupertino_icons: ^1.0.8
dev_dependencies:
''');

      logger.success(
        'Initialized local substitution file: ${localSubstitutionFile.path}',
      );

      final gitIgnoreFile = File('.gitignore');

      if (!gitIgnoreFile.existsSync()) {
        gitIgnoreFile.createSync();
        gitIgnoreFile.writeAsStringSync(
          'local-deps.yaml\n',
          mode: FileMode.append,
        );
        gitIgnoreFile.writeAsStringSync(
          'deps-bkp.yaml\n',
          mode: FileMode.append,
        );
        logger.success(
          'Updated .gitignore with local-deps.yaml and deps-bkp.yaml',
        );
      } else {
        if (!gitIgnoreFile.readAsStringSync().contains('local-deps.yaml')) {
          gitIgnoreFile.writeAsStringSync(
            'local-deps.yaml\n',
            mode: FileMode.append,
          );
          logger.success('Updated .gitignore with local-deps.yaml');
        }
        if (!gitIgnoreFile.readAsStringSync().contains('deps-bkp.yaml')) {
          gitIgnoreFile.writeAsStringSync(
            'deps-bkp.yaml\n',
            mode: FileMode.append,
          );
          logger.success('Updated .gitignore with deps-bkp.yaml');
        }
      }

      return;
    }

    logger.warning(
      'Local substitution file already exists: ${localSubstitutionFile.path}',
    );
  }
}
