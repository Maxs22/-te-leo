import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Estados posibles para cada palabra del texto
enum WordState {
  normal,      // Estado por defecto
  highlighted, // Palabra que se está reproduciendo actualmente
  selected,    // Palabra seleccionada por el usuario
  completed,   // Palabra ya reproducida
}

/// Información de una palabra individual en el texto
class WordInfo {
  final String text;
  final int startIndex;
  final int endIndex;
  final WordState state;
  final VoidCallback? onTap;

  const WordInfo({
    required this.text,
    required this.startIndex,
    required this.endIndex,
    this.state = WordState.normal,
    this.onTap,
  });

  WordInfo copyWith({
    String? text,
    int? startIndex,
    int? endIndex,
    WordState? state,
    VoidCallback? onTap,
  }) {
    return WordInfo(
      text: text ?? this.text,
      startIndex: startIndex ?? this.startIndex,
      endIndex: endIndex ?? this.endIndex,
      state: state ?? this.state,
      onTap: onTap ?? this.onTap,
    );
  }
}

/// Configuración de colores para el texto interactivo
class InteractiveTextColors {
  final Color normalColor;
  final Color highlightedColor;
  final Color highlightedBackground;
  final Color selectedColor;
  final Color selectedBackground;
  final Color completedColor;
  final Color completedBackground;

  const InteractiveTextColors({
    required this.normalColor,
    required this.highlightedColor,
    required this.highlightedBackground,
    required this.selectedColor,
    required this.selectedBackground,
    required this.completedColor,
    required this.completedBackground,
  });

  /// Colores por defecto basados en el tema actual
  factory InteractiveTextColors.defaultColors() {
    final theme = Get.theme;
    final isDark = theme.brightness == Brightness.dark;
    
    return InteractiveTextColors(
      normalColor: theme.colorScheme.onSurface,
      highlightedColor: isDark ? Colors.white : Colors.black,
      highlightedBackground: theme.colorScheme.primary.withValues(alpha: 0.3),
      selectedColor: isDark ? Colors.white : Colors.black,
      selectedBackground: theme.colorScheme.secondary.withValues(alpha: 0.2),
      completedColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      completedBackground: Colors.transparent,
    );
  }
}

/// Widget de texto interactivo con palabras seleccionables y resaltado
class InteractiveText extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;
  final int? currentWordIndex;
  final Function(int wordIndex, String word)? onWordTap;
  final InteractiveTextColors? colors;
  final double wordSpacing;
  final double lineSpacing;
  final TextAlign textAlign;
  final bool enableSelection;
  final bool enableHighlighting;
  final Duration animationDuration;
  final Set<int>? completedWordIndices;

  const InteractiveText({
    super.key,
    required this.text,
    this.textStyle,
    this.currentWordIndex,
    this.onWordTap,
    this.colors,
    this.wordSpacing = 2.0,
    this.lineSpacing = 1.5,
    this.textAlign = TextAlign.start,
    this.enableSelection = true,
    this.enableHighlighting = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.completedWordIndices,
  });

  @override
  State<InteractiveText> createState() => _InteractiveTextState();
}

class _InteractiveTextState extends State<InteractiveText>
    with TickerProviderStateMixin {
  late List<WordInfo> _words;
  late InteractiveTextColors _colors;
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;
  int? _selectedWordIndex;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _parseText();
    _updateColors();
  }

  @override
  void didUpdateWidget(InteractiveText oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.text != widget.text) {
      _parseText();
    }
    
    if (oldWidget.currentWordIndex != widget.currentWordIndex) {
      _animateHighlight();
    }
    
    if (oldWidget.colors != widget.colors) {
      _updateColors();
    }
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  /// Inicializa las animaciones
  void _initializeAnimations() {
    _highlightController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _highlightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeInOut,
    ));
  }

  /// Actualiza los colores basados en el tema
  void _updateColors() {
    _colors = widget.colors ?? InteractiveTextColors.defaultColors();
  }

  /// Parsea el texto en palabras individuales
  void _parseText() {
    _words = [];
    final words = widget.text.split(RegExp(r'\s+'));
    int currentIndex = 0;
    
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isNotEmpty) {
        // Encontrar la posición real de la palabra en el texto original
        final wordStart = widget.text.indexOf(word, currentIndex);
        final wordEnd = wordStart + word.length;
        
        _words.add(WordInfo(
          text: word,
          startIndex: wordStart,
          endIndex: wordEnd,
          onTap: widget.enableSelection 
              ? () => _onWordTapped(i, word)
              : null,
        ));
        
        currentIndex = wordEnd;
      }
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  /// Anima el resaltado de la palabra actual
  void _animateHighlight() {
    if (widget.enableHighlighting && widget.currentWordIndex != null) {
      _highlightController.forward();
    }
  }

  /// Maneja el toque en una palabra
  void _onWordTapped(int wordIndex, String word) {
    setState(() {
      _selectedWordIndex = wordIndex;
    });
    
    // Llamar al callback después de un breve delay para mostrar la selección
    Future.delayed(const Duration(milliseconds: 150), () {
      widget.onWordTap?.call(wordIndex, word);
      
      // Limpiar selección después de un tiempo
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _selectedWordIndex = null;
          });
        }
      });
    });
  }

  /// Obtiene el estado de una palabra específica
  WordState _getWordState(int index) {
    // Palabra seleccionada tiene prioridad
    if (_selectedWordIndex == index) {
      return WordState.selected;
    }
    
    // Palabra actualmente resaltada
    if (widget.currentWordIndex == index && widget.enableHighlighting) {
      return WordState.highlighted;
    }
    
    // Palabras completadas
    if (widget.completedWordIndices?.contains(index) == true) {
      return WordState.completed;
    }
    
    return WordState.normal;
  }

  /// Obtiene el estilo de texto para una palabra según su estado
  TextStyle _getWordStyle(WordState state) {
    final baseStyle = widget.textStyle ?? Get.theme.textTheme.bodyLarge!;
    
    switch (state) {
      case WordState.normal:
        return baseStyle.copyWith(color: _colors.normalColor);
      
      case WordState.highlighted:
        return baseStyle.copyWith(
          color: _colors.highlightedColor,
          fontWeight: FontWeight.w600,
        );
      
      case WordState.selected:
        return baseStyle.copyWith(
          color: _colors.selectedColor,
          fontWeight: FontWeight.w500,
        );
      
      case WordState.completed:
        return baseStyle.copyWith(
          color: _colors.completedColor,
        );
    }
  }

  /// Obtiene el color de fondo para una palabra según su estado
  Color? _getWordBackgroundColor(WordState state) {
    switch (state) {
      case WordState.highlighted:
        return _colors.highlightedBackground;
      case WordState.selected:
        return _colors.selectedBackground;
      case WordState.completed:
        return _colors.completedBackground;
      case WordState.normal:
        return null;
    }
  }

  /// Construye un widget para una palabra individual
  Widget _buildWord(WordInfo wordInfo, int index) {
    final state = _getWordState(index);
    final style = _getWordStyle(state);
    final backgroundColor = _getWordBackgroundColor(state);
    
    Widget wordWidget = Text(
      wordInfo.text,
      style: style,
    );
    
    // Agregar fondo si es necesario
    if (backgroundColor != null) {
      wordWidget = AnimatedBuilder(
        animation: _highlightAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            decoration: BoxDecoration(
              color: state == WordState.highlighted
                  ? Color.lerp(
                      Colors.transparent,
                      backgroundColor,
                      _highlightAnimation.value,
                    )
                  : backgroundColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: child,
          );
        },
        child: wordWidget,
      );
    }
    
    // Agregar funcionalidad táctil si está habilitada
    if (wordInfo.onTap != null) {
      wordWidget = GestureDetector(
        onTap: wordInfo.onTap,
        child: wordWidget,
      );
    }
    
    return wordWidget;
  }

  @override
  Widget build(BuildContext context) {
    if (_words.isEmpty) {
      return Text(
        widget.text,
        style: widget.textStyle,
        textAlign: widget.textAlign,
      );
    }
    
    return Wrap(
      spacing: widget.wordSpacing,
      runSpacing: widget.lineSpacing * 8, // Convertir a pixels aproximados
      alignment: _getWrapAlignment(widget.textAlign),
      children: _words.asMap().entries.map((entry) {
        final index = entry.key;
        final wordInfo = entry.value;
        return _buildWord(wordInfo, index);
      }).toList(),
    );
  }
  
  /// Convierte TextAlign a WrapAlignment
  WrapAlignment _getWrapAlignment(TextAlign textAlign) {
    switch (textAlign) {
      case TextAlign.left:
      case TextAlign.start:
        return WrapAlignment.start;
      case TextAlign.right:
      case TextAlign.end:
        return WrapAlignment.end;
      case TextAlign.center:
        return WrapAlignment.center;
      case TextAlign.justify:
        return WrapAlignment.spaceBetween;
    }
  }
}

/// Controlador para gestionar el estado del texto interactivo
class InteractiveTextController extends GetxController {
  final RxInt _currentWordIndex = (-1).obs;
  final RxSet<int> _completedWordIndices = RxSet<int>();
  final RxString _text = ''.obs;
  
  int get currentWordIndex => _currentWordIndex.value;
  Set<int> get completedWordIndices => _completedWordIndices;
  String get text => _text.value;
  
  /// Establece el texto a mostrar
  void setText(String newText) {
    _text.value = newText;
    _currentWordIndex.value = -1;
    _completedWordIndices.clear();
  }
  
  /// Establece la palabra actual que se está reproduciendo
  void setCurrentWord(int wordIndex) {
    if (wordIndex >= 0) {
      // Marcar palabras anteriores como completadas
      for (int i = 0; i < wordIndex; i++) {
        _completedWordIndices.add(i);
      }
    }
    _currentWordIndex.value = wordIndex;
  }
  
  /// Marca una palabra como completada
  void markWordCompleted(int wordIndex) {
    _completedWordIndices.add(wordIndex);
  }
  
  /// Limpia todas las marcas y vuelve al inicio
  void reset() {
    _currentWordIndex.value = -1;
    _completedWordIndices.clear();
  }
  
  /// Obtiene el índice de palabra basado en la posición del carácter
  int getWordIndexFromCharacterPosition(int characterPosition, String fullText) {
    final words = fullText.split(RegExp(r'\s+'));
    int currentPos = 0;
    
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final wordStart = fullText.indexOf(word, currentPos);
      final wordEnd = wordStart + word.length;
      
      if (characterPosition >= wordStart && characterPosition <= wordEnd) {
        return i;
      }
      
      currentPos = wordEnd;
    }
    
    return -1;
  }
}
