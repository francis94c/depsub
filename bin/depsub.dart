import 'package:args/command_runner.dart';
import 'package:depsub/console/commands/init.dart';

void main(List<String> arguments) {
  final commandRunner = CommandRunner(
    'depsub',
    'A tool for managing dependency substitutions',
  )..addCommand(InitCommand());

  commandRunner.run(arguments);
}
