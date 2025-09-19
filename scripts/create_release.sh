#!/bin/bash

# 🚀 Script para crear releases de Te Leo automáticamente
# Uso: ./scripts/create_release.sh 1.0.1 "Descripción del release"

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}🚀 Te Leo Release Creator${NC}"
    echo ""
    echo "Uso: $0 <version> [descripcion]"
    echo ""
    echo "Ejemplos:"
    echo "  $0 1.0.1                           # Release patch"
    echo "  $0 1.1.0 \"Nuevas características\"  # Release minor"
    echo "  $0 2.0.0 \"Cambios importantes\"     # Release major"
    echo ""
    echo "Formatos de versión soportados:"
    echo "  - 1.0.0 (major.minor.patch)"
    echo "  - 1.0.0+123 (con build number)"
}

# Validar argumentos
if [ $# -lt 1 ]; then
    show_help
    exit 1
fi

VERSION=$1
DESCRIPTION=${2:-"Nuevas mejoras y correcciones"}

# Validar formato de versión
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+(\+[0-9]+)?$ ]]; then
    echo -e "${RED}❌ Error: Formato de versión inválido${NC}"
    echo "Usa formato: major.minor.patch (ej: 1.0.1)"
    exit 1
fi

TAG="v$VERSION"

echo -e "${BLUE}🚀 Creando release Te Leo $VERSION${NC}"
echo ""

# Verificar que estamos en la rama main
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo -e "${YELLOW}⚠️  Advertencia: No estás en la rama main (actual: $CURRENT_BRANCH)${NC}"
    read -p "¿Continuar? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Verificar que no hay cambios sin commit
if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}❌ Error: Hay cambios sin commit${NC}"
    echo "Haz commit de tus cambios antes de crear el release"
    exit 1
fi

# Actualizar pubspec.yaml con la nueva versión
echo -e "${YELLOW}📝 Actualizando pubspec.yaml...${NC}"
if [ -f "pubspec.yaml" ]; then
    # Backup del archivo original
    cp pubspec.yaml pubspec.yaml.bak
    
    # Actualizar versión
    sed -i.tmp "s/^version: .*/version: $VERSION/" pubspec.yaml
    rm pubspec.yaml.tmp
    
    echo -e "${GREEN}✅ pubspec.yaml actualizado${NC}"
else
    echo -e "${RED}❌ Error: pubspec.yaml no encontrado${NC}"
    exit 1
fi

# Commit de la actualización de versión
echo -e "${YELLOW}📝 Creando commit de versión...${NC}"
git add pubspec.yaml
git commit -m "🔖 Bump version to $VERSION"

# Crear y push del tag
echo -e "${YELLOW}🏷️  Creando tag $TAG...${NC}"
git tag -a "$TAG" -m "Release $VERSION: $DESCRIPTION"

echo -e "${YELLOW}📤 Pusheando cambios y tag...${NC}"
git push origin main
git push origin "$TAG"

# Esperar un poco para que GitHub procese el tag
echo -e "${YELLOW}⏳ Esperando que GitHub procese el tag...${NC}"
sleep 5

# Verificar que el workflow se ejecutó
echo -e "${BLUE}🤖 GitHub Actions se ejecutará automáticamente${NC}"
echo ""
echo -e "${GREEN}✅ Release $VERSION creado exitosamente!${NC}"
echo ""
echo "📋 Próximos pasos:"
echo "1. Ve a: https://github.com/MaximoDev/te-leo/actions"
echo "2. Verifica que el workflow 'Build and Release' se esté ejecutando"
echo "3. Una vez completado, el release estará en:"
echo "   https://github.com/MaximoDev/te-leo/releases"
echo ""
echo "🔗 Enlaces útiles:"
echo "- Releases: https://github.com/MaximoDev/te-leo/releases"
echo "- Actions:  https://github.com/MaximoDev/te-leo/actions"
echo "- Tags:     https://github.com/MaximoDev/te-leo/tags"

# Mostrar información de la API que usará la app
echo ""
echo -e "${BLUE}🔧 Configuración de la app:${NC}"
echo "La app verificará actualizaciones en:"
echo "https://api.github.com/repos/MaximoDev/te-leo/releases/latest"
echo ""
echo "Respuesta esperada:"
echo "{"
echo "  \"tag_name\": \"$TAG\","
echo "  \"name\": \"Te Leo $VERSION\","
echo "  \"body\": \"$DESCRIPTION\","
echo "  \"assets\": [...]"
echo "}"
