import 'package:args/command_runner.dart';
import 'package:depsub/console/commands/init.dart';
import 'package:depsub/console/commands/run.dart';

void main(List<String> arguments) {
  final commandRunner =
      CommandRunner('depsub', 'A tool for managing dependency substitutions')
        ..addCommand(InitCommand())
        ..addCommand(RunCommand());

  commandRunner.run(arguments);
}
