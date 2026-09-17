import 'package:args/command_runner.dart';
import 'package:depsub/console/commands/init.dart';
import 'package:depsub/console/commands/run.dart';
import 'package:depsub/console/commands/restore.dart';

void main(List<String> arguments) {
  final commandRunner =
      CommandRunner('depsub', 'A tool for managing dependency substitutions')
        ..addCommand(InitCommand())
        ..addCommand(RunCommand())
        ..addCommand(RestoreCommand());

  commandRunner.run(arguments);
}
