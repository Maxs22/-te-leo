import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'welcome_controller.dart';
import '../../core/theme/accessible_colors.dart';

/// Pantalla de bienvenida principal de Te Leo - Solo Onboarding
class WelcomePage extends GetView<WelcomeController> {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Get.isDarkMode 
              ? AccessibleColors.darkGradient
              : AccessibleColors.lightGradient,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}