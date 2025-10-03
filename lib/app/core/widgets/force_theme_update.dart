import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/theme_service.dart';

/// Widget simple que fuerza la reconstrucción cuando cambia el tema
class ForceThemeUpdate extends StatelessWidget {
  final Widget child;

  const ForceThemeUpdate({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeService>(
      builder: (themeService) {
        return child;
      },
    );
  }
}

/// Widget para Scaffolds que se reconstruyen con el tema
class ThemeScaffold extends StatelessWidget {
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  const ThemeScaffold({
    super.key,
    this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return ForceThemeUpdate(
      child: Scaffold(
        body: body,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        drawer: drawer,
        endDrawer: endDrawer,
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      ),
    );
  }
}
