# 🏪 Configuración de Google Play Store para Te Leo

## 🔧 **Paso 1: Crear cuenta de desarrollador**

1. **Google Play Console**: https://play.google.com/console/
2. **Pagar tarifa única**: $25 USD
3. **Verificar identidad**: Documento oficial requerido
4. **Configurar perfil**: Información fiscal y de pago

## 📱 **Paso 2: Crear aplicación**

### Información básica:
```
Nombre: Te Leo
Categoría: Educación
Público objetivo: Todas las edades
Política de privacidad: [URL requerida]
```

### Configuración de la app:
1. **App Bundle**: Usar `.aab` en lugar de `.apk`
2. **Firma de app**: Dejar que Google gestione la clave
3. **Versioning**: Seguir semantic versioning

## 💳 **Paso 3: Configurar In-App Purchases**

### Productos de suscripción:

#### Te Leo Premium Mensual
```
Product ID: te_leo_premium_monthly
Precio: $4.99 USD
Período: 1 mes
Prueba gratuita: 7 días
Descripción: "Documentos ilimitados, sin anuncios, funciones premium"
```

#### Te Leo Premium Anual  
```
Product ID: te_leo_premium_yearly
Precio: $24.99 USD (58% descuento)
Período: 12 meses
Prueba gratuita: 7 días
Descripción: "Documentos ilimitados, sin anuncios, funciones premium - Ahorra 58%"
```

### Configuración técnica:
1. **Habilitar Google Play Billing API** en Google Cloud Console
2. **Crear Service Account** para verificación de compras
3. **Descargar JSON key** para autenticación server-side

## 🔑 **Paso 4: Configurar IDs de productos**

Actualizar en `lib/app/core/services/subscription_service.dart`:

```dart
// Productos reales (reemplazar)
static const String monthlyProductId = 'te_leo_premium_monthly';
static const String yearlyProductId = 'te_leo_premium_yearly';
```

## 🧪 **Paso 5: Configurar cuentas de prueba**

### Testers internos:
1. **Agregar emails** en Play Console
2. **Crear track interno** para testing
3. **Subir APK de prueba** con compras habilitadas

### Compras de prueba:
```
Tarjeta de prueba: 4111 1111 1111 1111
CVV: Cualquier 3 dígitos
Fecha: Cualquier fecha futura
```

## 📋 **Paso 6: Información de la tienda**

### Descripción corta (80 caracteres):
```
"Lee documentos con voz AI. Escanea, escucha y organiza textos fácilmente."
```

### Descripción larga:
```
🎯 Te Leo - Tu Asistente Personal de Lectura

¿Tienes dificultades para leer textos largos? ¿Quieres escuchar documentos mientras haces otras tareas? Te Leo es la solución perfecta.

✨ CARACTERÍSTICAS PRINCIPALES:
• 📸 Escanea cualquier texto con la cámara
• 🎙️ Síntesis de voz natural y clara
• 📚 Organiza documentos en tu biblioteca personal
• 🎨 Interfaz moderna y accesible
• 🌙 Modo oscuro y claro

🚀 VERSIÓN GRATUITA:
• Hasta 5 documentos por mes
• Funciones básicas de lectura
• Soporte para múltiples idiomas

⭐ PREMIUM ($4.99/mes):
• Documentos ilimitados
• Sin anuncios
• Funciones avanzadas
• Soporte prioritario

🎯 PERFECTO PARA:
• Estudiantes que necesitan escuchar apuntes
• Personas con dislexia o dificultades de lectura
• Profesionales que quieren optimizar su tiempo
• Cualquiera que prefiera escuchar en lugar de leer

📱 Descarga Te Leo hoy y transforma tu forma de consumir información.
```

### Capturas de pantalla:
- **Feature Graphic**: 1024 x 500 px
- **Screenshots**: 5-8 imágenes mostrando funciones clave
- **Ícono**: 512 x 512 px, formato PNG

## 🔒 **Paso 7: Políticas y cumplimiento**

### Política de privacidad:
```
Datos recopilados:
- Documentos escaneados (almacenados localmente)
- Preferencias de usuario
- Métricas de uso anónimas
- No se comparten datos con terceros
```

### Permisos requeridos:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="com.android.vending.BILLING" />
```

## 📊 **Paso 8: Estrategia de monetización**

### Modelo Freemium:
- **Usuarios gratuitos**: 5 documentos/mes + anuncios
- **Usuarios premium**: Ilimitado + sin anuncios

### Proyección de ingresos:
```
1,000 usuarios activos/mes:
- 80% gratuitos (800): $200 en anuncios
- 20% premium (200): $1,000 en suscripciones
- Total estimado: $1,200/mes
```

### Optimización de conversión:
- **Prueba gratuita**: 7 días premium
- **Recordatorios suaves**: Al alcanzar límite
- **Valor claro**: Mostrar beneficios premium

## 🚀 **Paso 9: Proceso de lanzamiento**

### Pre-lanzamiento:
1. ✅ **Testing interno**: 2-3 semanas
2. 🔄 **Testing cerrado**: 50-100 usuarios, 1-2 semanas
3. 🔄 **Testing abierto**: 500+ usuarios, 1-2 semanas
4. 🔄 **Revisión de Google**: 1-3 días

### Lanzamiento:
1. **Lanzamiento gradual**: 5% → 20% → 50% → 100%
2. **Monitoreo**: Crashes, ANRs, reviews
3. **Actualizaciones**: Según feedback

## ⚠️ **Checklist antes de publicar**

- [ ] IDs de AdMob reales configurados
- [ ] Productos de suscripción creados
- [ ] Política de privacidad publicada
- [ ] Capturas de pantalla actualizadas
- [ ] Descripción optimizada
- [ ] Permisos justificados
- [ ] Testing completo en dispositivos reales
- [ ] Firma de release configurada
- [ ] Versión de producción compilada

## 📈 **Métricas post-lanzamiento**

### KPIs importantes:
- **Instalaciones**: Orgánicas vs pagadas
- **Retención**: D1, D7, D30
- **Conversión a premium**: %
- **Revenue per user**: ARPU
- **Rating**: Mantener >4.0 estrellas

### Herramientas de análisis:
- Google Play Console (métricas básicas)
- Firebase Analytics (comportamiento de usuario)
- AdMob (métricas de anuncios)
- Play Console (reviews y crashes)

## 🔄 **Próximos pasos**

1. ✅ Sistema de monetización implementado
2. 🔄 Crear cuenta Google Play Console
3. 🔄 Configurar productos de suscripción
4. 🔄 Preparar assets para la tienda
5. 🔄 Realizar testing interno
6. 🔄 Lanzar en modo de prueba
