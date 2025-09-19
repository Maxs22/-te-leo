#!/usr/bin/env dart

import 'dart:io';

/// Script para incrementar automáticamente la versión de la app
/// Uso: dart scripts/version_bump.dart [patch|minor|major] [--build-only]

void main(List<String> args) async {
  print('🚀 Te Leo Version Bump Script\n');

  // Parsear argumentos
  final versionType = args.isNotEmpty ? args[0].toLowerCase() : 'patch';
  final buildOnly = args.contains('--build-only');

  if (!['patch', 'minor', 'major'].contains(versionType) && !buildOnly) {
    print('❌ Tipo de versión inválido. Usa: patch, minor, major o --build-only');
    exit(1);
  }

  try {
    // Leer pubspec.yaml actual
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      print('❌ No se encontró pubspec.yaml');
      exit(1);
    }

    final content = await pubspecFile.readAsString();
    final lines = content.split('\n');

    // Encontrar línea de versión
    int versionLineIndex = -1;
    String currentVersionLine = '';

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].trim().startsWith('version:')) {
        versionLineIndex = i;
        currentVersionLine = lines[i];
        break;
      }
    }

    if (versionLineIndex == -1) {
      print('❌ No se encontró la línea de versión en pubspec.yaml');
      exit(1);
    }

    // Extraer versión actual
    final versionMatch = RegExp(r'version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)').firstMatch(currentVersionLine);
    if (versionMatch == null) {
      print('❌ Formato de versión inválido: $currentVersionLine');
      exit(1);
    }

    final currentVersion = versionMatch.group(1)!;
    final currentBuild = int.parse(versionMatch.group(2)!);

    print('📋 Versión actual: $currentVersion+$currentBuild');

    // Calcular nueva versión
    String newVersion;
    int newBuild;

    if (buildOnly) {
      newVersion = currentVersion;
      newBuild = currentBuild + 1;
    } else {
      final versionParts = currentVersion.split('.').map(int.parse).toList();
      
      switch (versionType) {
        case 'major':
          versionParts[0]++;
          versionParts[1] = 0;
          versionParts[2] = 0;
          break;
        case 'minor':
          versionParts[1]++;
          versionParts[2] = 0;
          break;
        case 'patch':
        default:
          versionParts[2]++;
          break;
      }
      
      newVersion = versionParts.join('.');
      newBuild = currentBuild + 1;
    }

    print('🔄 Nueva versión: $newVersion+$newBuild');

    // Actualizar pubspec.yaml
    lines[versionLineIndex] = 'version: $newVersion+$newBuild';
    await pubspecFile.writeAsString(lines.join('\n'));

    // Actualizar CHANGELOG.md
    await updateChangelog(newVersion, newBuild, versionType, buildOnly);

    // Crear git tag si es un release completo
    if (!buildOnly) {
      await createGitTag(newVersion);
    }

    print('✅ Versión actualizada exitosamente a $newVersion+$newBuild');
    print('📝 Changelog actualizado');
    
    if (!buildOnly) {
      print('🏷️  Git tag creado: v$newVersion');
    }

    // Mostrar próximos pasos
    print('\n📋 Próximos pasos:');
    print('1. Revisar los cambios en pubspec.yaml y CHANGELOG.md');
    print('2. Hacer commit de los cambios');
    print('3. Ejecutar: flutter build appbundle --release');
    print('4. Subir a las tiendas de aplicaciones');

  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

/// Actualizar CHANGELOG.md
Future<void> updateChangelog(String version, int buildNumber, String versionType, bool buildOnly) async {
  final changelogFile = File('CHANGELOG.md');
  
  String content = '';
  if (changelogFile.existsSync()) {
    content = await changelogFile.readAsString();
  } else {
    content = '# Changelog\n\nTodos los cambios notables de Te Leo se documentarán en este archivo.\n\n';
  }

  final now = DateTime.now();
  final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  
  String changeType = '';
  String changes = '';

  if (buildOnly) {
    changeType = '🔧 Build';
    changes = '- Incremento de build number para nueva distribución';
  } else {
    switch (versionType) {
      case 'major':
        changeType = '🚀 Major Release';
        changes = '''- Nuevas características principales
- Cambios importantes en la arquitectura
- Posibles cambios incompatibles''';
        break;
      case 'minor':
        changeType = '✨ Minor Release';
        changes = '''- Nuevas funcionalidades
- Mejoras de características existentes
- Cambios compatibles hacia atrás''';
        break;
      case 'patch':
      default:
        changeType = '🐛 Patch Release';
        changes = '''- Correcciones de bugs
- Mejoras de rendimiento
- Actualizaciones menores''';
        break;
    }
  }

  final newEntry = '''
## [$version+$buildNumber] - $dateStr

### $changeType
$changes

''';

  // Insertar nueva entrada después del header
  final lines = content.split('\n');
  int insertIndex = 0;
  
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].startsWith('## [') || lines[i].startsWith('###')) {
      insertIndex = i;
      break;
    }
  }
  
  if (insertIndex == 0) {
    // Si no hay entradas previas, agregar al final
    content += newEntry;
  } else {
    lines.insert(insertIndex, newEntry.trim());
    content = lines.join('\n');
  }

  await changelogFile.writeAsString(content);
}

/// Crear git tag
Future<void> createGitTag(String version) async {
  try {
    final result = await Process.run('git', ['tag', '-a', 'v$version', '-m', 'Release v$version']);
    if (result.exitCode != 0) {
      print('⚠️  Warning: No se pudo crear git tag: ${result.stderr}');
    }
  } catch (e) {
    print('⚠️  Warning: Git no disponible o error creando tag: $e');
  }
}
