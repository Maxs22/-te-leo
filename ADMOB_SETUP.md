# 📱 Configuración de AdMob para Te Leo

## 🔧 **Paso 1: Crear cuenta de AdMob**

1. **Ir a AdMob Console**: https://apps.admob.com/
2. **Crear cuenta** con tu cuenta de Google
3. **Agregar aplicación**:
   - Nombre: `Te Leo`
   - Plataforma: `Android` / `iOS`
   - Store: `Google Play` / `App Store`

## 🎯 **Paso 2: Crear unidades de anuncio**

### Banner Ad (320x50)
```
Nombre: Te Leo Banner
Formato: Banner
Tamaño: 320x50
```

### Interstitial Ad
```
Nombre: Te Leo Intersticial
Formato: Intersticial
```

## 🔑 **Paso 3: Obtener IDs reales**

### Android
1. **App ID**: Reemplazar en `android/app/src/main/AndroidManifest.xml`
   ```xml
   <meta-data
       android:name="com.google.android.gms.ads.APPLICATION_ID"
       android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
   ```

2. **Ad Unit IDs**: Actualizar en `lib/app/core/services/ads_service.dart`
   ```dart
   // IDs de producción (reemplazar)
   static const String _bannerAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
   static const String _interstitialAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
   ```

### iOS
1. **Info.plist**: Agregar en `ios/Runner/Info.plist`
   ```xml
   <key>GADApplicationIdentifier</key>
   <string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
   ```

## 💰 **Paso 4: Configurar pagos**

1. **Información fiscal**: Completar en AdMob Console
2. **Método de pago**: Agregar cuenta bancaria
3. **Umbral de pago**: Configurar (mínimo $100 USD)

## 📊 **Paso 5: Optimización de ingresos**

### Estrategia de anuncios implementada:
- **Banners**: En home page para usuarios gratuitos
- **Intersticiales**: Cada 3 documentos escaneados
- **Sin anuncios**: Para usuarios premium

### Estimación de ingresos:
- **eCPM promedio**: $0.50 - $2.00 USD
- **CTR esperado**: 1-3%
- **RPM**: $0.10 - $1.00 por 1000 impresiones

### Fórmula de ingresos:
```
Ingresos diarios = (Usuarios activos × Sesiones × Anuncios por sesión × eCPM) / 1000
```

## 🧪 **Paso 6: Pruebas**

### IDs de prueba actuales (ya implementados):
```dart
// Android Test IDs
Banner: 'ca-app-pub-3940256099942544/6300978111'
Interstitial: 'ca-app-pub-3940256099942544/1033173712'

// iOS Test IDs  
Banner: 'ca-app-pub-3940256099942544/2934735716'
Interstitial: 'ca-app-pub-3940256099942544/4411468910'
```

### Probar en desarrollo:
1. Usar opciones de prueba en Configuraciones → Desarrollo
2. Verificar que los anuncios cargan correctamente
3. Confirmar que usuarios premium no ven anuncios

## 🚀 **Paso 7: Lanzamiento**

1. **Cambiar a IDs de producción** antes de subir a Play Store
2. **Activar mediación** en AdMob Console para maximizar ingresos
3. **Monitorear métricas** las primeras semanas
4. **Ajustar frecuencia** de anuncios según feedback

## 📈 **Métricas importantes a monitorear**

- **Fill Rate**: % de solicitudes de anuncios exitosas
- **eCPM**: Ingresos por 1000 impresiones
- **CTR**: Tasa de clics
- **Retention**: Retención de usuarios después de mostrar anuncios
- **Conversion to Premium**: % usuarios que se vuelven premium

## ⚠️ **Políticas importantes**

1. **No hacer clic** en tus propios anuncios
2. **No solicitar clics** a los usuarios
3. **Respetar límites** de frecuencia de anuncios
4. **Contenido apropiado** para todas las edades
5. **Cumplir GDPR/CCPA** para usuarios europeos/californianos

## 🔄 **Próximos pasos**

1. ✅ Sistema básico implementado
2. 🔄 Crear cuenta AdMob real
3. 🔄 Reemplazar IDs de prueba
4. 🔄 Configurar In-App Purchases
5. 🔄 Subir a Play Store para revisión
