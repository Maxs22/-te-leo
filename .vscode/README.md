# 🚀 Configuraciones de Desarrollo y Producción

## 📋 Configuraciones Disponibles

### 🚀 Te Leo - Desarrollo
- **Modo**: Debug
- **Elementos de Debug**: ✅ Visibles
- **Logs Detallados**: ✅ Habilitados
- **Variables de Entorno**:
  - `ENVIRONMENT=development`
  - `DEBUG_MODE=true`
  - `SHOW_DEBUG_ELEMENTS=true`

### 📦 Te Leo - Producción
- **Modo**: Release
- **Elementos de Debug**: ❌ Ocultos
- **Logs Detallados**: ❌ Deshabilitados
- **Variables de Entorno**:
  - `ENVIRONMENT=production`
  - `DEBUG_MODE=false`
  - `SHOW_DEBUG_ELEMENTS=false`

### 🔧 Te Leo - Profile
- **Modo**: Profile
- **Elementos de Debug**: ❌ Ocultos
- **Logs Detallados**: ❌ Deshabilitados
- **Variables de Entorno**:
  - `ENVIRONMENT=profile`
  - `DEBUG_MODE=false`
  - `SHOW_DEBUG_ELEMENTS=false`

## 🎯 Cómo Usar

### En VS Code:
1. Ve a la pestaña **Run and Debug** (Ctrl+Shift+D)
2. Selecciona la configuración deseada del dropdown
3. Presiona **F5** o el botón ▶️ para ejecutar

### Desde Terminal:
```bash
# Desarrollo
flutter run --dart-define=ENVIRONMENT=development --dart-define=DEBUG_MODE=true --dart-define=SHOW_DEBUG_ELEMENTS=true

# Producción
flutter run --release --dart-define=ENVIRONMENT=production --dart-define=DEBUG_MODE=false --dart-define=SHOW_DEBUG_ELEMENTS=false

# Profile
flutter run --profile --dart-define=ENVIRONMENT=profile --dart-define=DEBUG_MODE=false --dart-define=SHOW_DEBUG_ELEMENTS=false
```

## 🔧 Elementos de Debug

Los siguientes elementos solo se muestran en modo desarrollo:

- **Botón de Debug** en el AppBar del lector de documentos
- **Opciones de Debug** en el menú de configuraciones
- **Información de Servicios** en la consola
- **Logs Detallados** del TTS y otros servicios
- **Herramientas de Desarrollo** adicionales

## 📱 Diferencias por Modo

| Característica | Desarrollo | Producción | Profile |
|----------------|------------|------------|---------|
| Elementos de Debug | ✅ | ❌ | ❌ |
| Logs Detallados | ✅ | ❌ | ❌ |
| Hot Reload | ✅ | ❌ | ❌ |
| Performance | ⚠️ | ✅ | 🔧 |
| Debugging | ✅ | ❌ | ⚠️ |

## 🛠️ Personalización

Para agregar nuevas configuraciones, edita el archivo `.vscode/launch.json` y agrega nuevas entradas en el array `configurations`.
