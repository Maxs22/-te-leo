import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/theme_service.dart';

/// Widget global que envuelve todas las páginas para asegurar reactividad del tema
class GlobalThemeWrapper extends StatelessWidget {
  final Widget child;

  const GlobalThemeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Acceder a la variable reactiva del ThemeService para activar la reactividad
      final themeService = Get.find<ThemeService>();
      themeService.themeMode; // Esto activa la reactividad

      // Este builder se ejecutará cada vez que cambie el tema
      return child;
    });
  }
}

/// Widget que fuerza la reconstrucción cuando cambia el tema
class ThemeRebuilder extends StatelessWidget {
  final Widget child;
  final String? tag;

  const ThemeRebuilder({super.key, required this.child, this.tag});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Acceder a la variable reactiva del ThemeService para activar la reactividad
      final themeService = Get.find<ThemeService>();
      themeService.themeMode; // Esto activa la reactividad

      // Forzar reconstrucción completa
      return child;
    });
  }
}

/// Widget para textos que deben ser reactivos al tema
class ReactiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ReactiveText(this.text, {super.key, this.style, this.textAlign, this.maxLines, this.overflow});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeService>(
      builder: (themeService) {
        return Text(text, style: style, textAlign: textAlign, maxLines: maxLines, overflow: overflow);
      },
    );
  }
}

/// Widget para iconos que deben ser reactivos al tema
class ReactiveIconWidget extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double? size;
  final String? semanticLabel;

  const ReactiveIconWidget(this.icon, {super.key, this.color, this.size, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeService>(
      builder: (themeService) {
        return Icon(icon, color: color, size: size, semanticLabel: semanticLabel);
      },
    );
  }
}

/// Widget para contenedores que deben ser reactivos al tema
class ReactiveContainer extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Decoration? decoration;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  const ReactiveContainer({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.color,
    this.decoration,
    this.width,
    this.height,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeService>(
      builder: (themeService) {
        return Container(
          padding: padding,
          margin: margin,
          color: color,
          decoration: decoration,
          width: width,
          height: height,
          alignment: alignment,
          child: child,
        );
      },
    );
  }
}

/// Widget para AppBars que deben ser reactivos al tema
class ReactiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final double? elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool centerTitle;

  const ReactiveAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.elevation,
    this.backgroundColor,
    this.foregroundColor,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeService>(
      builder: (themeService) {
        return AppBar(
          title: title,
          actions: actions,
          leading: leading,
          automaticallyImplyLeading: automaticallyImplyLeading,
          bottom: bottom,
          elevation: elevation,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          centerTitle: centerTitle,
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Widget para Scaffolds que deben ser reactivos al tema
class ReactiveScaffold extends StatelessWidget {
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  const ReactiveScaffold({
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
    return Obx(() {
      // Acceder a la variable reactiva del ThemeService para activar la reactividad
      final themeService = Get.find<ThemeService>();
      themeService.themeMode; // Esto activa la reactividad

      return Scaffold(
        body: body,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        drawer: drawer,
        endDrawer: endDrawer,
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      );
    });
  }
}

/// Mixin para páginas que necesitan ser completamente reactivas al tema
mixin ReactivePageMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    // Registrar esta página para actualizaciones de tema
    Get.find<ThemeService>().addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    Get.find<ThemeService>().removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {
        // Forzar reconstrucción cuando cambie el tema
      });
    }
  }
}
