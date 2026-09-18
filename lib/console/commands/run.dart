import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';
import 'package:path/path.dart' as path;

import 'package:depsub/console/console_logger.dart';

class RunCommand extends Command {
  @override
  String get name => 'run';

  @override
  String get description =>
      'Override dependency versions in pubspec.yaml from local-deps.yaml';

  late final ConsoleLogger logger = ConsoleLogger();

  RunCommand() {
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
        help: 'Path to write backup file (default: deps-bkp.yaml)',
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

    final pubspecPath = path.normalize(path.join(root, 'pubspec.yaml'));
    final localDepsPath = path.normalize(path.join(root, 'local-deps.yaml'));
    final backupPath =
        backupOpt ?? path.normalize(path.join(root, 'deps-bkp.yaml'));

    if (!File(pubspecPath).existsSync()) {
      logger.error('pubspec.yaml not found at $pubspecPath');
      exitCode = 2;
      return;
    }

    if (!File(localDepsPath).existsSync()) {
      logger.error('local-deps.yaml not found at $localDepsPath');
      exitCode = 2;
      return;
    }

    final pubText = File(pubspecPath).readAsStringSync();
    final localText = File(localDepsPath).readAsStringSync();

    final pubYaml = loadYaml(pubText) as YamlMap;
    final localYaml = loadYaml(localText) as YamlMap;

    final editor = YamlEditor(pubText);

    final sections = <String>[];
    if (onlyDev) {
      sections.add('dev_dependencies');
    } else if (onlyProd) {
      sections.add('dependencies');
    } else {
      sections.addAll(['dependencies', 'dev_dependencies']);
    }

    // We'll build a backup of ORIGINAL values only for dependencies that are updated.
    // (Do this after computing `updated` so the backup contains only changed keys.)

    final added = <String>[];
    final updated = <String>[];
    final warnings = <String>[];

    for (final section in sections) {
      final localSection = localYaml.containsKey(section)
          ? localYaml[section]
          : null;
      if (localSection == null) continue;
      final localMap = localSection as YamlMap;

      final parentExists =
          pubYaml.containsKey(section) && pubYaml[section] is YamlMap;
      if (!parentExists) {
        editor.update([section], <String, dynamic>{});
      }

      for (final key in localMap.keys) {
        final valueNode = localMap[key];
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

    // Build backup containing only original values for updated keys
    final backup = <String, dynamic>{};
    for (final entry in updated) {
      final parts = entry.split(':');
      if (parts.length != 2) continue;
      final sec = parts[0];
      final key = parts[1];
      if (pubYaml.containsKey(sec) && pubYaml[sec] is YamlMap) {
        final sect = pubYaml[sec] as YamlMap;
        if (sect.containsKey(key)) {
          backup.putIfAbsent(sec, () => <String, dynamic>{});
          (backup[sec] as Map)[key.toString()] = _toPlain(sect[key]);
        }
      }
    }

    final backupYaml = _toYamlString(backup);

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
      logger.info('Backup that would be written to $backupPath:\n$backupYaml');
      logger.info('New pubspec.yaml would be:\n${editor.toString()}');
      return;
    }

    try {
      File(backupPath).writeAsStringSync(backupYaml);
      logger.success('Wrote backup to $backupPath');
    } catch (e) {
      logger.error('Failed to write backup to $backupPath: $e');
      exitCode = 3;
      return;
    }

    try {
      final tmpPath = '$pubspecPath.tmp';
      File(tmpPath).writeAsStringSync(editor.toString());
      File(tmpPath).renameSync(pubspecPath);
      logger.success('Updated pubspec.yaml at $pubspecPath');
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
      logger.error('Failed to write updated pubspec.yaml: $e');
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

  String _toYamlString(dynamic node, [int indent = 0]) {
    final buf = StringBuffer();
    final ind = '  ' * indent;
    if (node is Map) {
      for (final key in node.keys) {
        final val = node[key];
        if (val is Map || val is List) {
          buf.writeln('$ind$key:');
          buf.write(_toYamlString(val, indent + 1));
        } else if (val == null) {
          buf.writeln('$ind$key:');
        } else {
          buf.writeln('$ind$key: $val');
        }
      }
    } else if (node is List) {
      for (final item in node) {
        if (item is Map || item is List) {
          buf.writeln('$ind-');
          buf.write(_toYamlString(item, indent + 1));
        } else {
          buf.writeln('$ind- $item');
        }
      }
    } else {
      buf.writeln('$ind$node');
    }
    return buf.toString();
  }
}
