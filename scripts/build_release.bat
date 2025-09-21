@echo off
echo.
echo ==========================================
echo    🚀 Te Leo - Build de Produccion
echo ==========================================
echo.

REM Verificar que Flutter esté instalado
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Error: Flutter no encontrado en PATH
    echo    Instala Flutter y agregalo al PATH
    pause
    exit /b 1
)

echo ✅ Flutter detectado
echo.

REM Limpiar proyecto
echo 📦 Limpiando proyecto...
flutter clean
if errorlevel 1 (
    echo ❌ Error en flutter clean
    pause
    exit /b 1
)

REM Obtener dependencias
echo 📥 Obteniendo dependencias...
flutter pub get
if errorlevel 1 (
    echo ❌ Error en flutter pub get
    pause
    exit /b 1
)

REM Verificar configuración de release
echo.
echo ⚠️  VERIFICAR ANTES DE CONTINUAR:
echo    1. IDs de AdMob de producción configurados
echo    2. IDs de productos de suscripción actualizados
echo    3. Política de privacidad publicada
echo    4. Versión incrementada en pubspec.yaml
echo.
set /p continue="¿Continuar con el build? (s/n): "
if /i not "%continue%"=="s" (
    echo ❌ Build cancelado por el usuario
    pause
    exit /b 0
)

echo.
echo 🔨 Construyendo APK de release...
flutter build apk --release
if errorlevel 1 (
    echo ❌ Error construyendo APK
    pause
    exit /b 1
)

echo.
echo 🔨 Construyendo App Bundle de release...
flutter build appbundle --release
if errorlevel 1 (
    echo ❌ Error construyendo App Bundle
    pause
    exit /b 1
)

echo.
echo ==========================================
echo    ✅ BUILD COMPLETADO EXITOSAMENTE
echo ==========================================
echo.
echo 📁 Archivos generados:
echo    APK: build\app\outputs\flutter-apk\app-release.apk
echo    AAB: build\app\outputs\bundle\release\app-release.aab
echo.
echo 📋 Próximos pasos:
echo    1. Probar APK en dispositivos reales
echo    2. Subir AAB a Google Play Console
echo    3. Configurar testing interno
echo    4. Revisar metadatos de la tienda
echo.
echo 💡 Recomendación: Usa el AAB para Play Store
echo    (mejor optimización y tamaño más pequeño)
echo.

REM Abrir carpeta de salida
set /p open="¿Abrir carpeta de archivos generados? (s/n): "
if /i "%open%"=="s" (
    start "" "build\app\outputs"
)

echo.
echo ¡Listo para lanzar! 🚀
pause
