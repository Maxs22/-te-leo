# 🚀 Guía de Releases para Te Leo

## 📋 Configuración Inicial

### 1. Configurar el repositorio
```bash
# Clonar o inicializar
git clone https://github.com/MaximoDev/te-leo.git
cd te-leo

# O si es nuevo:
git init
git remote add origin https://github.com/MaximoDev/te-leo.git
```

### 2. Configurar permisos del script
```bash
chmod +x scripts/create_release.sh
```

### 3. Verificar configuración de GitHub Actions
- Ve a: `Settings` → `Actions` → `General`
- Asegúrate que `Allow GitHub Actions to create and approve pull requests` esté habilitado

## 🎯 Crear un Release

### Método Automático (Recomendado)
```bash
# Release patch (1.0.0 → 1.0.1)
./scripts/create_release.sh 1.0.1 "Correcciones menores"

# Release minor (1.0.0 → 1.1.0)  
./scripts/create_release.sh 1.1.0 "Nuevas características"

# Release major (1.0.0 → 2.0.0)
./scripts/create_release.sh 2.0.0 "Cambios importantes"
```

### Método Manual
```bash
# 1. Actualizar versión en pubspec.yaml
version: 1.0.1+2

# 2. Commit y tag
git add .
git commit -m "🔖 Bump version to 1.0.1"
git tag -a v1.0.1 -m "Release 1.0.1"
git push origin main --tags
```

## 📱 Lo que hace el workflow automáticamente

### 🤖 GitHub Actions ejecutará:
1. **Build Android APK** (Ubuntu runner)
2. **Build iOS IPA** (macOS runner) 
3. **Crear Release** con archivos adjuntos
4. **Generar Release Notes** automáticas
5. **Notificar** que el release está listo

### 📦 Archivos generados:
- `te-leo-v1.0.1.apk` (Android)
- `te-leo-v1.0.1.ipa` (iOS)
- Release notes en Markdown
- Tag git con metadata

## 🔧 API de GitHub que usa la app

### Endpoint:
```
GET https://api.github.com/repos/MaximoDev/te-leo/releases/latest
```

### Respuesta esperada:
```json
{
  "tag_name": "v1.0.1",
  "name": "Te Leo 1.0.1",
  "body": "🎉 Nueva versión...",
  "published_at": "2024-01-15T10:30:00Z",
  "assets": [
    {
      "name": "te-leo-v1.0.1.apk",
      "browser_download_url": "https://github.com/.../te-leo-v1.0.1.apk"
    }
  ]
}
```

## 🧪 Probar en Desarrollo

### 1. Simular actualización disponible:
- Ir a `Configuraciones` → `Herramientas de desarrollo`
- Tocar `🧪 Simular actualización`
- Elegir tipo de actualización

### 2. Verificar API real:
```bash
# Verificar último release
curl -s https://api.github.com/repos/MaximoDev/te-leo/releases/latest | jq .tag_name

# Ver todos los releases
curl -s https://api.github.com/repos/MaximoDev/te-leo/releases | jq '.[].tag_name'
```

## 📋 Checklist antes del Release

- [ ] ✅ Código tested y funcionando
- [ ] 📝 Changelog actualizado
- [ ] 🔢 Versión actualizada en `pubspec.yaml`
- [ ] 🧪 Probado en modo desarrollo
- [ ] 📱 APK/IPA compilando correctamente
- [ ] 🔒 Permisos de GitHub configurados

## 🚨 Troubleshooting

### Error: "Resource not accessible by integration"
**Solución**: Ve a `Settings` → `Actions` → `General` → Habilitar permisos

### Error: "Tag already exists"
**Solución**: 
```bash
git tag -d v1.0.1      # Borrar local
git push --delete origin v1.0.1  # Borrar remoto
```

### Build falla en iOS
**Solución**: Verificar que el proyecto iOS esté correctamente configurado

### APK no se encuentra
**Solución**: Verificar que `flutter build apk --release` funcione localmente

## 📞 Soporte

Si tienes problemas:
1. Revisa los logs en: `https://github.com/MaximoDev/te-leo/actions`
2. Verifica la configuración de permisos
3. Prueba el build localmente primero
