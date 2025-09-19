@echo off
REM 🚀 Script rápido para crear releases de Te Leo
REM Uso: quick_release.bat 1.0.2 "Descripción del release"

setlocal enabledelayedexpansion

REM Colores para output
set "GREEN=[92m"
set "YELLOW=[93m"
set "RED=[91m"
set "BLUE=[94m"
set "NC=[0m"

REM Validar argumentos
if "%~1"=="" (
    echo %RED%❌ Error: Falta la versión%NC%
    echo.
    echo Uso: %0 ^<version^> [descripcion]
    echo.
    echo Ejemplos:
    echo   %0 1.0.1                           # Release patch
    echo   %0 1.1.0 "Nuevas características"  # Release minor
    echo   %0 2.0.0 "Cambios importantes"     # Release major
    exit /b 1
)

set VERSION=%~1
set DESCRIPTION=%~2
if "%DESCRIPTION%"=="" set DESCRIPTION=Nuevas mejoras y correcciones

set TAG=v%VERSION%

echo %BLUE%🚀 Creando release Te Leo %VERSION%%NC%
echo.

REM Verificar que no hay cambios sin commit
git diff-index --quiet HEAD -- >nul 2>&1
if errorlevel 1 (
    echo %RED%❌ Error: Hay cambios sin commit%NC%
    echo Haz commit de tus cambios antes de crear el release
    exit /b 1
)

REM Actualizar pubspec.yaml con la nueva versión
echo %YELLOW%📝 Actualizando pubspec.yaml...%NC%
powershell -Command "(Get-Content pubspec.yaml) -replace '^version: .*', 'version: %VERSION%' | Set-Content pubspec.yaml"

REM Commit de la actualización de versión
echo %YELLOW%📝 Creando commit de versión...%NC%
git add pubspec.yaml
git commit -m "🔖 Bump version to %VERSION%"

REM Crear y push del tag
echo %YELLOW%🏷️ Creando tag %TAG%...%NC%
git tag -a "%TAG%" -m "Release %VERSION%: %DESCRIPTION%"

echo %YELLOW%📤 Pusheando cambios y tag...%NC%
git push origin main
git push origin "%TAG%"

REM Esperar un poco para que GitHub procese el tag
echo %YELLOW%⏳ Esperando que GitHub procese el tag...%NC%
timeout /t 5 /nobreak >nul

echo.
echo %GREEN%✅ Release %VERSION% creado exitosamente!%NC%
echo.
echo 📋 Próximos pasos:
echo 1. Ve a: https://github.com/Maxs22/-te-leo/actions
echo 2. Verifica que el workflow 'Build and Release' se esté ejecutando
echo 3. Una vez completado, el release estará en:
echo    https://github.com/Maxs22/-te-leo/releases
echo.
echo 🔗 Enlaces útiles:
echo - Releases: https://github.com/Maxs22/-te-leo/releases
echo - Actions:  https://github.com/Maxs22/-te-leo/actions
echo - Tags:     https://github.com/Maxs22/-te-leo/tags
echo.
echo %BLUE%🔧 La app verificará actualizaciones en:%NC%
echo https://api.github.com/repos/Maxs22/-te-leo/releases/latest

pause
