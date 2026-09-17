import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';
import 'package:path/path.dart' as p;

import 'package:depsub/console/console_logger.dart';

class RestoreCommand extends Command {
  @override
  String get name => 'restore';

  @override
  String get description =>
      'Restore dependency sections in pubspec.yaml from a backup file (deps-bkp.yaml)';

  late final ConsoleLogger logger = ConsoleLogger();

  RestoreCommand() {
    argParser
      ..addOption('root', defaultsTo: '.', help: 'Project root directory')
      ..addFlag(
        'dry-run',
        negatable: false,
        help: 'Show changes without writing',
      )
      ..addFlag(
        'only-dev',
        negatable: false,
        help: 'Only apply to dev_dependencies',
      )
      ..addFlag(
        'only-prod',
        negatable: false,
        help: 'Only apply to dependencies',
      )
      ..addOption(
        'backup',
        help: 'Path to backup file to read (default: deps-bkp.yaml)',
      );
  }

  @override
  void run() {
    final root = argResults?['root'] as String? ?? '.';
    final dryRun = argResults?['dry-run'] as bool? ?? false;
    final onlyDev = argResults?['only-dev'] as bool? ?? false;
    final onlyProd = argResults?['only-prod'] as bool? ?? false;
    final backupOpt = argResults?['backup'] as String?;

    if (onlyDev && onlyProd) {
      logger.error('Flags --only-dev and --only-prod are mutually exclusive.');
      exitCode = 2;
      return;
    }

    final pubspecPath = p.normalize(p.join(root, 'pubspec.yaml'));
    final backupPath = backupOpt ?? p.normalize(p.join(root, 'deps-bkp.yaml'));

    if (!File(pubspecPath).existsSync()) {
      logger.error('pubspec.yaml not found at $pubspecPath');
      exitCode = 2;
      return;
    }

    if (!File(backupPath).existsSync()) {
      logger.error('Backup file not found at $backupPath');
      exitCode = 2;
      return;
    }

    final pubText = File(pubspecPath).readAsStringSync();
    final backupText = File(backupPath).readAsStringSync();

    final pubYaml = loadYaml(pubText) as YamlMap;
    final backupYaml = loadYaml(backupText) as YamlMap;

    final editor = YamlEditor(pubText);

    final sections = <String>[];
    if (onlyDev) {
      sections.add('dev_dependencies');
    } else if (onlyProd) {
      sections.add('dependencies');
    } else {
      sections.addAll(['dependencies', 'dev_dependencies']);
    }

    final added = <String>[];
    final updated = <String>[];
    final warnings = <String>[];

    for (final section in sections) {
      final srcSection = backupYaml.containsKey(section)
          ? backupYaml[section]
          : null;
      if (srcSection == null) continue;
      final srcMap = srcSection as YamlMap;

      final parentExists =
          pubYaml.containsKey(section) && pubYaml[section] is YamlMap;
      if (!parentExists) {
        editor.update([section], <String, dynamic>{});
      }

      for (final key in srcMap.keys) {
        final valueNode = srcMap[key];
        final value = _toPlain(valueNode);

        final origSection =
            pubYaml.containsKey(section) && pubYaml[section] is YamlMap
            ? (pubYaml[section] as YamlMap)
            : null;

        final origValueNode =
            origSection != null && origSection.containsKey(key)
            ? origSection[key]
            : null;
        final origValue = _toPlain(origValueNode);

        final path = [section, key];
        try {
          editor.update(path, value);
        } catch (e) {
          final secMap = origSection != null
              ? _toPlain(origSection) as Map<String, dynamic>
              : <String, dynamic>{};
          secMap[key.toString()] = value;
          editor.update([section], secMap);
        }

        if (origValueNode == null) {
          added.add('$section:$key');
        } else if (origValue != value) {
          updated.add('$section:$key');
        }
      }
    }

    if (dryRun) {
      logger.info('Dry run mode - no files will be written.');
      if (added.isNotEmpty) {
        logger.info('Added: ${added.join(', ')}');
      }
      if (updated.isNotEmpty) {
        logger.info('Updated: ${updated.join(', ')}');
      }
      if (warnings.isNotEmpty) {
        logger.warning('Warnings: ${warnings.join(', ')}');
      }
      logger.info('pubspec.yaml would be:\n${editor.toString()}');
      return;
    }

    try {
      final tmpPath = '$pubspecPath.tmp';
      File(tmpPath).writeAsStringSync(editor.toString());
      File(tmpPath).renameSync(pubspecPath);
      logger.success('Restored pubspec.yaml at $pubspecPath from $backupPath');
      if (added.isNotEmpty) {
        logger.info('Added: ${added.join(', ')}');
      }
      if (updated.isNotEmpty) {
        logger.info('Updated: ${updated.join(', ')}');
      }
      if (warnings.isNotEmpty) {
        logger.warning('Warnings: ${warnings.join(', ')}');
      }
    } catch (e) {
      logger.error('Failed to write restored pubspec.yaml: $e');
      exitCode = 4;
      return;
    }
  }

  dynamic _toPlain(dynamic node) {
    if (node == null) return null;
    if (node is YamlMap) {
      final map = <String, dynamic>{};
      for (final k in node.keys) {
        map[k.toString()] = _toPlain(node[k]);
      }
      return map;
    }
    if (node is YamlList) {
      return node.map(_toPlain).toList();
    }
    return node;
  }
}
