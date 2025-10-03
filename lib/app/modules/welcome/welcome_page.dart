import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'welcome_controller.dart';
import '../../core/theme/accessible_colors.dart';
import '../../../global_widgets/global_widgets.dart';
import '../../core/services/theme_service.dart';

/// Pantalla de bienvenida principal de Te Leo - Solo Onboarding
class WelcomePage extends GetView<WelcomeController> {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Acceder a la variable reactiva del ThemeService para activar la reactividad
      final themeService = Get.find<ThemeService>();
      themeService.themeMode; // Esto activa la reactividad
      
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: themeService.isDarkMode 
                ? AccessibleColors.darkGradient
                : AccessibleColors.lightGradient,
            ),
          ),
        child: Column(
          children: [
            // Espaciador superior
            const Spacer(flex: 2),
            
            // Mensaje de bienvenida
            Text(
              '¡Bienvenido a Te Leo!',
              style: TextStyle(
                color: AccessibleColors.getTextOnGradient(),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Tu asistente de lectura accesible',
              style: TextStyle(
                color: AccessibleColors.getTextOnGradient(isSecondary: true),
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Espaciador central
            const Spacer(flex: 1),
            
            // Logo de la aplicación en la parte inferior
            const AppLogoSplash(
              size: 150,
            ),
            
            const SizedBox(height: 20),
            
            // Botón para continuar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    controller.enterApp();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AccessibleColors.getTextOnGradient(),
                    foregroundColor: AccessibleColors.getContrastingTextColor(AccessibleColors.getTextOnGradient()),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Comenzar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            
            // Espaciador inferior
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
    });
  }
}