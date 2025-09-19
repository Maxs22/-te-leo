import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/accessible_colors.dart';
import 'settings_controller.dart';
import '../../../global_widgets/global_widgets.dart';
import '../../data/models/configuracion_usuario.dart';
import '../../core/services/reading_reminder_service.dart';
import '../../core/services/app_update_service.dart';
import '../../core/models/voice_profiles.dart';

/// Página de configuraciones de Te Leo
/// Interfaz completa para gestionar todas las configuraciones del usuario
class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings_title'.tr),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'reset':
                  await controller.resetearConfiguraciones();
                  break;
                case 'export':
                  await controller.exportarConfiguraciones();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Exportar configuraciones'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: ListTile(
                  leading: Icon(Icons.restore, color: Colors.orange),
                  title: Text('Restaurar por defecto'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return TeLeoEmptyStates.cargandoDatos();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saludo personalizado
              _buildWelcomeHeader(),
              const SizedBox(height: 20),
              
              // Información del usuario
              _buildUserInfoSection(),
              const SizedBox(height: 24),

              // Configuraciones de apariencia
              _buildAppearanceSection(),
              const SizedBox(height: 24),

              // Configuraciones de voz
              _buildVoiceSection(),
              const SizedBox(height: 24),


              // Recordatorios de lectura
              _buildReadingRemindersSection(),
              const SizedBox(height: 24),

              // Configuraciones premium
              _buildPremiumSection(),
              const SizedBox(height: 24),

              // Sección de desarrollo (solo en debug)
              if (kDebugMode) ...[
                _buildDeveloperSection(),
                const SizedBox(height: 32),
              ] else
                const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  /// Sección de información del usuario
  Widget _buildUserInfoSection() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(
                  Icons.person,
                  size: 30,
                  color: Get.theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.configuracion.nombreUsuario,
                      style: Get.theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (controller.configuracion.email != null)
                      Text(
                        controller.configuracion.email!,
                        style: Get.theme.textTheme.bodyMedium?.copyWith(
                          color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    Text(
                      controller.configuracion.tienePremiumActivo ? 'Usuario Premium' : 'Usuario Gratuito',
                      style: Get.theme.textTheme.bodySmall?.copyWith(
                        color: controller.configuracion.tienePremiumActivo 
                            ? Colors.amber 
                            : Get.theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showEditUserDialog(),
                icon: const Icon(Icons.edit),
                tooltip: 'Editar información',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Sección de configuraciones de apariencia
  Widget _buildAppearanceSection() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'general'.tr,
            style: Get.theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Get.theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 16),

          // Selector de tema
          ListTile(
            leading: Icon(
              Icons.palette,
              color: Get.theme.colorScheme.primary,
            ),
            title: Text('theme'.tr),
            subtitle: Text(controller.textoTemaActual),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showThemeSelector(),
            contentPadding: EdgeInsets.zero,
          ),

          const Divider(),

          // Selector de idioma
          ListTile(
            leading: Icon(
              Icons.language,
              color: Get.theme.colorScheme.primary,
            ),
            title: Text('language'.tr),
            subtitle: Text(controller.textoIdiomaActual),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguageSelector(),
            contentPadding: EdgeInsets.zero,
          ),

          const Divider(),

          // Tamaño de fuente
          ListTile(
            leading: Icon(
              Icons.text_fields,
              color: Get.theme.colorScheme.primary,
            ),
            title: const Text('Tamaño de fuente'),
            subtitle: Text('${(controller.configuracion.tamanoFuente * 100).round()}%'),
            contentPadding: EdgeInsets.zero,
          ),
          Slider(
            value: controller.configuracion.tamanoFuente,
            min: 0.8,
            max: 1.5,
            divisions: 7,
            label: '${(controller.configuracion.tamanoFuente * 100).round()}%',
            onChanged: (value) async {
              await controller.actualizarConfiguracionAccesibilidad(
                tamanoFuente: value,
              );
            },
          ),

          // Alto contraste
          SwitchListTile(
            secondary: Icon(
              Icons.contrast,
              color: Get.theme.colorScheme.primary,
            ),
            title: const Text('Alto contraste'),
            subtitle: const Text('Mejora la visibilidad del texto'),
            value: controller.configuracion.modoAltoContraste,
            onChanged: (value) async {
              await controller.actualizarConfiguracionAccesibilidad(
                modoAltoContraste: value,
              );
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  /// Sección de configuraciones de voz con perfiles predefinidos
  Widget _buildVoiceSection() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título con botón de prueba
          Row(
            children: [
              Icon(
                Icons.record_voice_over,
                color: Get.theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'voice_settings'.tr,
                  style: Get.theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Get.theme.colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Selector de perfil de voz
          GetBuilder<SettingsController>(
            builder: (controller) {
              final currentLanguage = Get.locale?.languageCode ?? 'es';
              final voices = VoiceProfileManager.getVoicesForLanguage(currentLanguage);
              final currentVoiceId = controller.configuracion.vozSeleccionada;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'voice_profile'.tr,
                    style: Get.theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Get.theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Lista de voces como tarjetas
                  ...voices.map((voice) {
                    final isSelected = currentVoiceId == voice.id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected 
                            ? Get.theme.colorScheme.primary 
                            : AccessibleColors.getBorderColor(),
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected 
                          ? Get.theme.colorScheme.primary.withOpacity(0.1)
                          : Colors.transparent,
                      ),
                      child: ListTile(
                        title: Text(
                          voice.displayName,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: AccessibleColors.getInteractiveTextColor(isSelected: isSelected),
                          ),
                        ),
                        subtitle: Text(
                          voice.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: AccessibleColors.getSecondaryTextColor(),
                          ),
                        ),
                        trailing: isSelected 
                          ? Icon(Icons.check_circle, color: Get.theme.colorScheme.primary)
                          : Icon(Icons.radio_button_unchecked, color: Get.theme.colorScheme.outline),
                        onTap: () async {
                          // Actualizar configuración
                          await controller.actualizarConfiguracionTTS(
                            vozSeleccionada: voice.id,
                            velocidad: voice.defaultSpeed,
                            tono: voice.defaultPitch,
                          );
                          
                          // Reproducir automáticamente la voz seleccionada
                          await controller.probarVoz();
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Controles avanzados (velocidad, tono, volumen)
          ExpansionTile(
            leading: Icon(
              Icons.tune,
              color: Get.theme.colorScheme.secondary,
            ),
            title: Text(
              'advanced_voice_settings'.tr,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Get.theme.colorScheme.onSurface,
              ),
            ),
            children: [
              const SizedBox(height: 16),
              
              // Velocidad de voz
              _buildVoiceSlider(
                icon: Icons.speed,
                title: 'voice_speed'.tr,
                value: controller.configuracion.velocidadVoz,
                min: 0.1,
                max: 2.0,
                divisions: 19,
                onChanged: (value) async {
                  await controller.actualizarConfiguracionTTS(velocidad: value);
                },
              ),

              // Tono de voz
              _buildVoiceSlider(
                icon: Icons.tune,
                title: 'voice_pitch'.tr,
                value: controller.configuracion.tonoVoz,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                onChanged: (value) async {
                  await controller.actualizarConfiguracionTTS(tono: value);
                },
              ),

              // Volumen
              _buildVoiceSlider(
                icon: Icons.volume_up,
                title: 'voice_volume'.tr,
                value: controller.configuracion.volumenVoz,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                onChanged: (value) async {
                  await controller.actualizarConfiguracionTTS(volumen: value);
                },
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget helper para sliders de voz
  Widget _buildVoiceSlider({
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: Get.theme.colorScheme.primary),
            title: Text(title),
            subtitle: Text('${(value * 100).round()}%'),
            contentPadding: EdgeInsets.zero,
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: '${(value * 100).round()}%',
            onChanged: onChanged,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }


  /// Sección de configuraciones premium
  Widget _buildPremiumSection() {
    return ModernCard(
      gradient: controller.configuracion.tienePremiumActivo
          ? LinearGradient(
              colors: [
                Colors.amber.withValues(alpha: 0.1),
                Colors.amber.withValues(alpha: 0.05),
              ],
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
             const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              const SizedBox(width: 8),
              Text(
                'Te Leo Premium',
                style: Get.theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Get.theme.colorScheme.secondary,
                ),
              ),
              const Spacer(),
              if (!controller.configuracion.tienePremiumActivo)
                ModernButton(
                  text: 'Obtener Premium',
                  onPressed: controller.mostrarInfoPremium,
                  type: ModernButtonType.primary,
                  customColor: Colors.amber,
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Activo',
                    style: Get.theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (controller.configuracion.tienePremiumActivo) ...[
            Text(
              'Premium activo hasta: ${controller.configuracion.fechaExpiracionPremium?.day}/${controller.configuracion.fechaExpiracionPremium?.month}/${controller.configuracion.fechaExpiracionPremium?.year}',
              style: Get.theme.textTheme.bodyMedium?.copyWith(
                color: Colors.amber,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Días restantes: ${controller.configuracion.diasRestantesPremium}',
              style: Get.theme.textTheme.bodySmall,
            ),
          ] else ...[
            Text(
              'Desbloquea todas las características premium',
              style: Get.theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }


  /// Muestra diálogo para editar información del usuario
  void _showEditUserDialog() {
    Get.dialog(
      ModernDialog(
        titulo: 'Editar información',
        contenidoWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller.nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.emailController,
              decoration: const InputDecoration(
                labelText: 'Email (opcional)',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        textoBotonPrimario: 'Guardar',
        textoBotonSecundario: 'Cancelar',
        onBotonPrimario: () {
          Get.back();
          controller.actualizarInfoUsuario();
        },
      ),
    );
  }


  /// Muestra selector de voz
  void _showVoiceSelector() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        height: Get.height * 0.6,
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Text(
              'Seleccionar voz',
              style: Get.theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            Expanded(
              child: ListView.builder(
                itemCount: controller.vocesDisponibles.length,
                itemBuilder: (context, index) {
                  final voz = controller.vocesDisponibles[index];
                  final isSelected = controller.configuracion.vozSeleccionada == voz['name'];
                  
                  return ListTile(
                    title: Text(voz['name'] ?? 'Desconocida'),
                    subtitle: Text(voz['locale'] ?? ''),
                    trailing: isSelected
                        ? Icon(Icons.check, color: Get.theme.colorScheme.primary)
                        : null,
                    onTap: () {
                      Get.back();
                      controller.actualizarConfiguracionTTS(
                        vozSeleccionada: voz['name'],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getThemeIcon(TipoTema tema) {
    switch (tema) {
      case TipoTema.sistema:
        return Icons.brightness_auto;
      case TipoTema.claro:
        return Icons.light_mode;
      case TipoTema.oscuro:
        return Icons.dark_mode;
    }
  }

  String _getThemeText(TipoTema tema) {
    switch (tema) {
      case TipoTema.sistema:
        return 'Automático (sistema)';
      case TipoTema.claro:
        return 'Tema claro';
      case TipoTema.oscuro:
        return 'Tema oscuro';
    }
  }

  /// Sección de herramientas de desarrollo (solo en debug)
  Widget _buildDeveloperSection() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.developer_mode,
                color: Colors.purple,
              ),
              const SizedBox(width: 8),
              Text(
                'Herramientas de desarrollo',
                style: Get.theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Get.theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Debug Console
          ListTile(
            leading:const  Icon(
              Icons.terminal,
              color: Colors.purple,
            ),
            title: const Text('Debug Console'),
            subtitle: const Text('Ver logs y información de debug'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Get.to(() => const DebugConsolePage()),
            contentPadding: EdgeInsets.zero,
          ),

          const Divider(),

          // Verificar actualizaciones
          ListTile(
            leading: const Icon(
              Icons.system_update,
              color: Colors.green,
            ),
            title: const Text('Verificar actualizaciones'),
            subtitle: const Text('Buscar nuevas versiones'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => controller.checkForUpdates(),
            contentPadding: EdgeInsets.zero,
          ),

          const Divider(),

          // 🧪 PRUEBAS DE ACTUALIZACIONES (solo en debug)
          ListTile(
            leading: const Icon(
              Icons.science,
              color: Colors.orange,
            ),
            title: const Text('🧪 Simular actualización'),
            subtitle: const Text('Probar notificación de actualización'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showUpdateTestOptions(),
            contentPadding: EdgeInsets.zero,
          ),

          const Divider(),

          // Información de la app
          ListTile(
            leading: const Icon(
              Icons.info,
              color: Colors.purple,
            ),
            title: const Text('Información de la app'),
            subtitle: const Text('Versión, build, etc.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showAppInfo(),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  /// Muestra información de la aplicación
  void _showAppInfo() {
    Get.dialog(
      ModernDialog(
        titulo: 'Información de la aplicación',
        contenidoWidget: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Aplicación', 'Te Leo'),
            _buildInfoRow('Versión', '1.0.0+1'),
            _buildInfoRow('Modo', kDebugMode ? 'Debug' : 'Release'),
            _buildInfoRow('Framework', 'Flutter 3.x'),
            _buildInfoRow('Arquitectura', 'MVVM + GetX'),
            _buildInfoRow('Base de datos', 'SQLite'),
          ],
        ),
        textoBotonPrimario: 'Cerrar',
      ),
    );
  }

  /// Construye una fila de información
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Get.theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Get.theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra el selector de tema
  void _showThemeSelector() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'theme'.tr,
              style: Get.theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Opción Sistema
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: Text('theme_system'.tr),
              subtitle: Text('Sigue la configuración del sistema'),
              onTap: () {
                controller.cambiarTema(ThemeMode.system);
                Get.back();
              },
            ),
            
            // Opción Claro
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: Text('theme_light'.tr),
              subtitle: Text('Tema claro'),
              onTap: () {
                controller.cambiarTema(ThemeMode.light);
                Get.back();
              },
            ),
            
            // Opción Oscuro
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: Text('theme_dark'.tr),
              subtitle: Text('Tema oscuro'),
              onTap: () {
                controller.cambiarTema(ThemeMode.dark);
                Get.back();
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Muestra el selector de idioma
  void _showLanguageSelector() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'language'.tr,
              style: Get.theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Opción Español
            ListTile(
              leading: const Icon(Icons.language),
              title: Text('language_spanish'.tr),
              subtitle: const Text('Español'),
              onTap: () {
                controller.cambiarIdioma('es_ES');
                Get.back();
              },
            ),
            
            // Opción Inglés
            ListTile(
              leading: const Icon(Icons.language),
              title: Text('language_english'.tr),
              subtitle: const Text('English'),
              onTap: () {
                controller.cambiarIdioma('en_US');
                Get.back();
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Construye la sección de recordatorios de lectura
  Widget _buildReadingRemindersSection() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección
          Row(
            children: [
              Icon(
                Icons.notifications_outlined,
                color: Get.theme.colorScheme.secondary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'reading_reminders'.tr,
                style: Get.theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Get.theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Switch para activar/desactivar recordatorios
          GetBuilder<SettingsController>(
            builder: (controller) {
              final reminderService = Get.find<ReadingReminderService>();
              return ListTile(
                leading: Icon(
                  reminderService.isEnabled 
                    ? Icons.notifications_active 
                    : Icons.notifications_off,
                  color: Get.theme.colorScheme.primary,
                ),
                title: Text('enable_reading_reminders'.tr),
                subtitle: Text(
                  reminderService.isEnabled 
                    ? 'Los recordatorios están activados' 
                    : 'Los recordatorios están desactivados',
                  style: TextStyle(
                    color: reminderService.isEnabled 
                      ? Get.theme.colorScheme.primary 
                      : Get.theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                trailing: Obx(() => Switch(
                  value: reminderService.isEnabled,
                  onChanged: (value) async {
                    await reminderService.updateReminderSettings(enabled: value);
                  },
                )),
                onTap: () async {
                  await reminderService.updateReminderSettings(
                    enabled: !reminderService.isEnabled,
                  );
                },
                contentPadding: EdgeInsets.zero,
              );
            },
          ),

          const SizedBox(height: 12),

          // Configuración de intervalo
          GetBuilder<SettingsController>(
            builder: (controller) {
              final reminderService = Get.find<ReadingReminderService>();
              return ListTile(
                leading: Icon(
                  Icons.schedule,
                  color: reminderService.isEnabled 
                    ? Get.theme.colorScheme.primary 
                    : Get.theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                title: Text('reminder_interval'.tr),
                subtitle: Text(
                  '${reminderService.reminderIntervalHours} ${'reminder_interval_hours'.tr}',
                  style: TextStyle(
                    color: reminderService.isEnabled 
                      ? Get.theme.colorScheme.onSurface 
                      : Get.theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: reminderService.isEnabled 
                    ? Get.theme.colorScheme.onSurface 
                    : Get.theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                enabled: reminderService.isEnabled,
                onTap: reminderService.isEnabled 
                  ? () => _showIntervalSelector(reminderService) 
                  : null,
                contentPadding: EdgeInsets.zero,
              );
            },
          ),

          const SizedBox(height: 12),

          // Botón de notificación de prueba
          GetBuilder<SettingsController>(
            builder: (controller) {
              final reminderService = Get.find<ReadingReminderService>();
              return ListTile(
                leading: Icon(
                  Icons.send,
                  color: reminderService.isEnabled 
                    ? Get.theme.colorScheme.secondary 
                    : Get.theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                title: Text('send_test_notification'.tr),
                subtitle: Text(
                  'Enviar una notificación de prueba para verificar que funciona',
                  style: TextStyle(
                    color: reminderService.isEnabled 
                      ? Get.theme.colorScheme.onSurface.withOpacity(0.7) 
                      : Get.theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: reminderService.isEnabled 
                    ? Get.theme.colorScheme.onSurface 
                    : Get.theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                enabled: reminderService.isEnabled,
                onTap: reminderService.isEnabled 
                  ? () async {
                      await reminderService.sendTestNotification();
                      Get.snackbar(
                        '✅ Notificación enviada',
                        'Revisa tus notificaciones',
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 3),
                      );
                    } 
                  : null,
                contentPadding: EdgeInsets.zero,
              );
            },
          ),
        ],
      ),
    );
  }

  /// Muestra selector de intervalo de recordatorio
  void _showIntervalSelector(ReadingReminderService reminderService) {
    final intervals = [1, 6, 12, 24, 48, 72]; // horas
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'reminder_interval'.tr,
              style: Get.theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            ...intervals.map((hours) => ListTile(
              title: Text('$hours ${'reminder_interval_hours'.tr}'),
              trailing: reminderService.reminderIntervalHours == hours
                ? Icon(Icons.check, color: Get.theme.colorScheme.primary)
                : null,
              onTap: () async {
                await reminderService.updateReminderSettings(intervalHours: hours);
                Get.back();
              },
            )).toList(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Construye el header de bienvenida personalizado
  Widget _buildWelcomeHeader() {
    return GetBuilder<SettingsController>(
      builder: (controller) {
        final userName = controller.configuracion.nombreUsuario;
        final currentHour = DateTime.now().hour;
        
        // Determinar saludo según la hora
        String greeting;
        IconData greetingIcon;
        Color greetingColor;
        
        if (currentHour < 12) {
          greeting = Get.locale?.languageCode == 'en' 
            ? 'Good morning' 
            : 'Buenos días';
          greetingIcon = Icons.wb_sunny;
          greetingColor = Colors.orange;
        } else if (currentHour < 18) {
          greeting = Get.locale?.languageCode == 'en' 
            ? 'Good afternoon' 
            : 'Buenas tardes';
          greetingIcon = Icons.wb_sunny_outlined;
          greetingColor = Colors.amber;
        } else {
          greeting = Get.locale?.languageCode == 'en' 
            ? 'Good evening' 
            : 'Buenas noches';
          greetingIcon = Icons.nights_stay;
          greetingColor = Colors.indigo;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                greetingColor.withOpacity(0.1),
                greetingColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: greetingColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: greetingColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  greetingIcon,
                  color: greetingColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, $userName!',
                      style: Get.theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AccessibleColors.getPrimaryTextColor(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Get.locale?.languageCode == 'en'
                        ? 'Customize your Te Leo experience'
                        : 'Personaliza tu experiencia en Te Leo',
                      style: Get.theme.textTheme.bodyMedium?.copyWith(
                        color: AccessibleColors.getSecondaryTextColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🧪 Muestra opciones de prueba para actualizaciones (solo debug)
  void _showUpdateTestOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.science, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '🧪 Pruebas de Actualización',
                  style: Get.theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Solo disponible en modo desarrollo',
              style: Get.theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            
            // Simular actualización opcional
            ListTile(
              leading: const Icon(Icons.info, color: Colors.blue),
              title: const Text('Actualización Opcional'),
              subtitle: const Text('Simular actualización de parche (1.0.0 → 1.0.1)'),
              onTap: () {
                Get.back();
                _simulateUpdate(UpdateType.optional);
              },
            ),
            
            // Simular actualización recomendada
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text('Actualización Recomendada'),
              subtitle: const Text('Simular actualización menor (1.0.0 → 1.1.0)'),
              onTap: () {
                Get.back();
                _simulateUpdate(UpdateType.recommended);
              },
            ),
            
            // Simular actualización crítica
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.red),
              title: const Text('Actualización Crítica'),
              subtitle: const Text('Simular actualización mayor (1.0.0 → 2.0.0)'),
              onTap: () {
                Get.back();
                _simulateUpdate(UpdateType.critical);
              },
            ),
            
            const Divider(),
            
            // Probar todos los escenarios
            ListTile(
              leading: const Icon(Icons.play_arrow, color: Colors.green),
              title: const Text('Probar Todos los Escenarios'),
              subtitle: const Text('Ejecutar secuencia completa de pruebas'),
              onTap: () {
                Get.back();
                _testAllUpdateScenarios();
              },
            ),
            
            // Resetear estado
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.grey),
              title: const Text('Resetear Estado'),
              subtitle: const Text('Limpiar simulaciones anteriores'),
              onTap: () {
                Get.back();
                _resetUpdateState();
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 🧪 Simular actualización específica
  Future<void> _simulateUpdate(UpdateType updateType) async {
    try {
      final updateService = Get.find<AppUpdateService>();
      await updateService.simulateUpdateAvailable(updateType: updateType);
      
      Get.snackbar(
        '🧪 Simulación Iniciada',
        'Actualización ${updateType.name} simulada',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo iniciar la simulación: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  /// 🧪 Probar todos los escenarios de actualización
  Future<void> _testAllUpdateScenarios() async {
    try {
      final updateService = Get.find<AppUpdateService>();
      await updateService.testUpdateScenarios();
      
      Get.snackbar(
        '🧪 Pruebas Iniciadas',
        'Ejecutando secuencia completa de pruebas...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudieron ejecutar las pruebas: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  /// 🧪 Resetear estado de actualizaciones
  void _resetUpdateState() {
    try {
      final updateService = Get.find<AppUpdateService>();
      updateService.resetUpdateState();
      
      Get.snackbar(
        '🧪 Estado Reseteado',
        'Simulaciones limpiadas correctamente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.grey.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo resetear el estado: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }
}
