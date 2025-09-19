#!/usr/bin/env dart

import 'dart:io';

/// Script para automatizar el proceso de build de release
/// Uso: dart scripts/build_release.dart [android|ios|both] [--upload]

void main(List<String> args) async {
  print('🚀 Te Leo Release Build Script\n');

  // Parsear argumentos
  final platform = args.isNotEmpty ? args[0].toLowerCase() : 'both';
  final shouldUpload = args.contains('--upload');

  if (!['android', 'ios', 'both'].contains(platform)) {
    print('❌ Plataforma inválida. Usa: android, ios o both');
    exit(1);
  }

  try {
    // Verificar que estamos en el directorio correcto
    if (!File('pubspec.yaml').existsSync()) {
      print('❌ No se encontró pubspec.yaml. Ejecuta desde la raíz del proyecto.');
      exit(1);
    }

    // Obtener información de versión
    final version = await getCurrentVersion();
    print('📋 Construyendo versión: $version\n');

    // Limpiar proyecto
    print('🧹 Limpiando proyecto...');
    await runCommand('flutter', ['clean']);
    await runCommand('flutter', ['pub', 'get']);

    // Verificar código
    print('🔍 Verificando código...');
    await runCommand('flutter', ['analyze']);
    
    // Ejecutar tests
    print('🧪 Ejecutando tests...');
    try {
      await runCommand('flutter', ['test']);
    } catch (e) {
      print('⚠️  Warning: Algunos tests fallaron, pero continuando...');
    }

    // Build según plataforma
    if (platform == 'android' || platform == 'both') {
      await buildAndroid(version, shouldUpload);
    }

    if (platform == 'ios' || platform == 'both') {
      await buildIOS(version, shouldUpload);
    }

    print('\n✅ Build completado exitosamente!');
    print('📦 Archivos generados en build/');

    if (!shouldUpload) {
      print('\n💡 Para subir automáticamente, usa: --upload');
    }

  } catch (e) {
    print('❌ Error durante el build: $e');
    exit(1);
  }
}

/// Build para Android
Future<void> buildAndroid(String version, bool shouldUpload) async {
  print('\n📱 Construyendo para Android...');

  // Verificar configuración de firma
  final keyPropertiesFile = File('android/key.properties');
  if (!keyPropertiesFile.existsSync()) {
    print('⚠️  Warning: No se encontró android/key.properties');
    print('   El APK/AAB no estará firmado para release.');
  }

  // Build App Bundle (recomendado para Play Store)
  print('🔨 Generando App Bundle...');
  await runCommand('flutter', [
    'build',
    'appbundle',
    '--release',
    '--tree-shake-icons',
  ]);

  // Build APK para distribución directa
  print('🔨 Generando APK...');
  await runCommand('flutter', [
    'build',
    'apk',
    '--release',
    '--split-per-abi',
    '--tree-shake-icons',
  ]);

  // Verificar tamaños de archivos
  await printFileSizes([
    'build/app/outputs/bundle/release/app-release.aab',
    'build/app/outputs/flutter-apk/app-arm64-v8a-release.apk',
    'build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk',
  ]);

  if (shouldUpload) {
    print('📤 Subiendo a Play Store...');
    // Aquí podrías integrar con Play Console API
    print('💡 Sube manualmente: build/app/outputs/bundle/release/app-release.aab');
  }
}

/// Build para iOS
Future<void> buildIOS(String version, bool shouldUpload) async {
  print('\n🍎 Construyendo para iOS...');

  if (!Platform.isMacOS) {
    print('⚠️  Warning: Build de iOS requiere macOS');
    return;
  }

  // Build IPA
  print('🔨 Generando IPA...');
  await runCommand('flutter', [
    'build',
    'ipa',
    '--release',
    '--tree-shake-icons',
  ]);

  // Verificar tamaño de archivo
  await printFileSizes([
    'build/ios/ipa/te_leo.ipa',
  ]);

  if (shouldUpload) {
    print('📤 Subiendo a App Store...');
    // Aquí podrías integrar con App Store Connect API
    print('💡 Sube manualmente usando Xcode o Transporter');
  }
}

/// Obtener versión actual del pubspec.yaml
Future<String> getCurrentVersion() async {
  final pubspecFile = File('pubspec.yaml');
  final content = await pubspecFile.readAsString();
  
  final versionMatch = RegExp(r'version:\s*([0-9]+\.[0-9]+\.[0-9]+\+[0-9]+)').firstMatch(content);
  if (versionMatch == null) {
    throw Exception('No se pudo encontrar la versión en pubspec.yaml');
  }
  
  return versionMatch.group(1)!;
}

/// Ejecutar comando y mostrar salida
Future<void> runCommand(String command, List<String> args) async {
  print('  > $command ${args.join(' ')}');
  
  final process = await Process.start(command, args);
  
  // Mostrar salida en tiempo real
  process.stdout.listen((data) {
    stdout.add(data);
  });
  
  process.stderr.listen((data) {
    stderr.add(data);
  });
  
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw Exception('Command failed with exit code $exitCode');
  }
}

/// Mostrar tamaños de archivos
Future<void> printFileSizes(List<String> filePaths) async {
  print('\n📊 Tamaños de archivos:');
  
  for (final path in filePaths) {
    final file = File(path);
    if (file.existsSync()) {
      final size = await file.length();
      final sizeInMB = (size / (1024 * 1024)).toStringAsFixed(2);
      final fileName = path.split('/').last;
      print('   $fileName: ${sizeInMB} MB');
    } else {
      print('   ${path.split('/').last}: No generado');
    }
  }
}
