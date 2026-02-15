import 'package:flutter/material.dart';
import 'responsive_design_system.dart';

/// Responsive Theme System
/// Provides adaptive themes and styling for different screen sizes
class ResponsiveThemeSystem {
  
  /// Get responsive theme data based on screen type
  static ThemeData getResponsiveTheme(BuildContext context, {bool isDark = false}) {
    final screenType = ResponsiveDesignSystem.getScreenType(context);
    
    final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();
    
    return baseTheme.copyWith(
      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      
      // Typography
      textTheme: _getResponsiveTextTheme(screenType, isDark),
      
      // App bar theme
      appBarTheme: _getResponsiveAppBarTheme(screenType, isDark),
      
      // Card theme
      cardTheme: _getResponsiveCardThemeData(screenType, isDark),
      
      // Button themes
      elevatedButtonTheme: _getResponsiveElevatedButtonTheme(screenType, isDark),
      textButtonTheme: _getResponsiveTextButtonTheme(screenType, isDark),
      outlinedButtonTheme: _getResponsiveOutlinedButtonTheme(screenType, isDark),
      
      // Input decoration theme
      inputDecorationTheme: _getResponsiveInputDecorationTheme(screenType, isDark),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: _getResponsiveBottomNavigationBarTheme(screenType, isDark),
      
      // Drawer theme
      drawerTheme: _getResponsiveDrawerTheme(screenType, isDark),
      
      // Dialog theme
      dialogTheme: _getResponsiveDialogThemeData(screenType, isDark),
      
      // Chip theme
      chipTheme: _getResponsiveChipTheme(screenType, isDark),
      
      // Icon theme
      iconTheme: _getResponsiveIconTheme(screenType, isDark),
      
      // Floating action button theme
      floatingActionButtonTheme: _getResponsiveFloatingActionButtonTheme(screenType, isDark),
    );
  }
  
  // Helper methods for theme components
  static TextTheme _getResponsiveTextTheme(ScreenType screenType, bool isDark) {
    final baseSize = isDark ? 1.0 : 1.0;
    final multiplier = _getTextSizeMultiplier(screenType);
    
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57 * baseSize * multiplier,
        fontWeight: FontWeight.w400,
        color: isDark ? Colors.white : Colors.black87,
      ),
      displayMedium: TextStyle(
        fontSize: 45 * baseSize * multiplier,
        fontWeight: FontWeight.w400,
        color: isDark ? Colors.white : Colors.black87,
      ),
      displaySmall: TextStyle(
        fontSize: 36 * baseSize * multiplier,
        fontWeight: FontWeight.w400,
        color: isDark ? Colors.white : Colors.black87,
      ),
      headlineLarge: TextStyle(
        fontSize: 32 * baseSize * multiplier,
        fontWeight: FontWeight.w400,
        color: isDark ? Colors.white : Colors.black87,
      ),
      headlineMedium: TextStyle(
        fontSize: 28 * baseSize * multiplier,
        fontWeight: FontWeight.w400,
        color: isDark ? Colors.white : Colors.black87,
      ),
      headlineSmall: TextStyle(
        fontSize: 24 * baseSize * multiplier,
        fontWeight: FontWeight.w400,
        color: isDark ? Colors.white : Colors.black87,
      ),
      titleLarge: TextStyle(
        fontSize: 22 * baseSize * multiplier,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : Colors.black87,
      ),
      titleMedium: TextStyle(
        fontSize: 16 * baseSize * multiplier,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : Colors.black87,
      ),
      titleSmall: TextStyle(
        fontSize: 14 * baseSize * multiplier,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : Colors.black87,
      ),
      bodyLarge: TextStyle(
        fontSize: 16 * baseSize * multiplier,
        fontWeight: FontWeight.w400,
        color: isDark ? Colors.white : Colors.black87,
      ),
      bodyMedium: TextStyle(
        fontSize: 14 * baseSize * multiplier,
        fontWeight: FontWeight.w400,
        color: isDark ? Colors.white : Colors.black87,
      ),
      bodySmall: TextStyle(
        fontSize: 12 * baseSize * multiplier,
        fontWeight: FontWeight.w400,
        color: isDark ? Colors.white70 : Colors.black54,
      ),
      labelLarge: TextStyle(
        fontSize: 14 * baseSize * multiplier,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : Colors.black87,
      ),
      labelMedium: TextStyle(
        fontSize: 12 * baseSize * multiplier,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : Colors.black87,
      ),
      labelSmall: TextStyle(
        fontSize: 11 * baseSize * multiplier,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white70 : Colors.black54,
      ),
    );
  }
  
  static AppBarTheme _getResponsiveAppBarTheme(ScreenType screenType, bool isDark) {
    final elevation = _getElevationMultiplier(screenType);
    
    return AppBarTheme(
      elevation: 4 * elevation,
      centerTitle: screenType == ScreenType.mobile,
      titleTextStyle: TextStyle(
        fontSize: 20 * _getTextSizeMultiplier(screenType),
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black87,
      ),
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
      foregroundColor: isDark ? Colors.white : Colors.black87,
      iconTheme: IconThemeData(
        size: 24 * _getIconSizeMultiplier(screenType),
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }
  
  static CardThemeData _getResponsiveCardThemeData(ScreenType screenType, bool isDark) {
    final elevation = _getElevationMultiplier(screenType);
    final borderRadius = _getBorderRadiusMultiplier(screenType);
    
    return CardThemeData(
      elevation: 2 * elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12 * borderRadius),
      ),
      color: isDark ? Colors.grey.shade800 : Colors.white,
      shadowColor: isDark ? Colors.black : Colors.grey.shade400,
    );
  }
  
  static ElevatedButtonThemeData _getResponsiveElevatedButtonTheme(ScreenType screenType, bool isDark) {
    final borderRadius = _getBorderRadiusMultiplier(screenType);
    final elevation = _getElevationMultiplier(screenType);
    
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2 * elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8 * borderRadius),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 16 * _getSpacingMultiplier(screenType),
          vertical: 12 * _getSpacingMultiplier(screenType),
        ),
        textStyle: TextStyle(
          fontSize: 16 * _getTextSizeMultiplier(screenType),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  static TextButtonThemeData _getResponsiveTextButtonTheme(ScreenType screenType, bool isDark) {
    final borderRadius = _getBorderRadiusMultiplier(screenType);
    
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8 * borderRadius),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 16 * _getSpacingMultiplier(screenType),
          vertical: 12 * _getSpacingMultiplier(screenType),
        ),
        textStyle: TextStyle(
          fontSize: 16 * _getTextSizeMultiplier(screenType),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  static OutlinedButtonThemeData _getResponsiveOutlinedButtonTheme(ScreenType screenType, bool isDark) {
    final borderRadius = _getBorderRadiusMultiplier(screenType);
    
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8 * borderRadius),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 16 * _getSpacingMultiplier(screenType),
          vertical: 12 * _getSpacingMultiplier(screenType),
        ),
        textStyle: TextStyle(
          fontSize: 16 * _getTextSizeMultiplier(screenType),
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          width: 1,
        ),
      ),
    );
  }
  
  static InputDecorationTheme _getResponsiveInputDecorationTheme(ScreenType screenType, bool isDark) {
    final borderRadius = _getBorderRadiusMultiplier(screenType);
    
    return InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8 * borderRadius),
        borderSide: BorderSide(
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8 * borderRadius),
        borderSide: BorderSide(
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8 * borderRadius),
        borderSide: BorderSide(
          color: Colors.blue,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8 * borderRadius),
        borderSide: BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
      filled: true,
      fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16 * _getSpacingMultiplier(screenType),
        vertical: 12 * _getSpacingMultiplier(screenType),
      ),
      labelStyle: TextStyle(
        fontSize: 16 * _getTextSizeMultiplier(screenType),
        color: isDark ? Colors.white70 : Colors.black54,
      ),
      hintStyle: TextStyle(
        fontSize: 16 * _getTextSizeMultiplier(screenType),
        color: isDark ? Colors.white54 : Colors.black38,
      ),
    );
  }
  
  static BottomNavigationBarThemeData _getResponsiveBottomNavigationBarTheme(ScreenType screenType, bool isDark) {
    final elevation = _getElevationMultiplier(screenType);
    
    return BottomNavigationBarThemeData(
      elevation: 8 * elevation,
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
      selectedItemColor: Colors.blue,
      unselectedItemColor: isDark ? Colors.white54 : Colors.black54,
      selectedLabelStyle: TextStyle(
        fontSize: 12 * _getTextSizeMultiplier(screenType),
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12 * _getTextSizeMultiplier(screenType),
        fontWeight: FontWeight.w500,
      ),
      type: screenType == ScreenType.mobile 
          ? BottomNavigationBarType.fixed 
          : BottomNavigationBarType.shifting,
    );
  }
  
  static DrawerThemeData _getResponsiveDrawerTheme(ScreenType screenType, bool isDark) {
    final elevation = _getElevationMultiplier(screenType);
    
    return DrawerThemeData(
      elevation: 16 * elevation,
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16 * _getBorderRadiusMultiplier(screenType)),
          bottomRight: Radius.circular(16 * _getBorderRadiusMultiplier(screenType)),
        ),
      ),
    );
  }
  
  static DialogThemeData _getResponsiveDialogThemeData(ScreenType screenType, bool isDark) {
    final borderRadius = _getBorderRadiusMultiplier(screenType);
    final elevation = _getElevationMultiplier(screenType);
    
    return DialogThemeData(
      elevation: 24 * elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16 * borderRadius),
      ),
      backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
      titleTextStyle: TextStyle(
        fontSize: 20 * _getTextSizeMultiplier(screenType),
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black87,
      ),
      contentTextStyle: TextStyle(
        fontSize: 16 * _getTextSizeMultiplier(screenType),
        color: isDark ? Colors.white70 : Colors.black54,
      ),
    );
  }
  
  static ChipThemeData _getResponsiveChipTheme(ScreenType screenType, bool isDark) {
    final borderRadius = _getBorderRadiusMultiplier(screenType);
    
    return ChipThemeData(
      backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
      selectedColor: Colors.blue,
      labelStyle: TextStyle(
        fontSize: 14 * _getTextSizeMultiplier(screenType),
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : Colors.black87,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16 * borderRadius),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 12 * _getSpacingMultiplier(screenType),
        vertical: 8 * _getSpacingMultiplier(screenType),
      ),
    );
  }
  
  static IconThemeData _getResponsiveIconTheme(ScreenType screenType, bool isDark) {
    return IconThemeData(
      size: 24 * _getIconSizeMultiplier(screenType),
      color: isDark ? Colors.white : Colors.black87,
    );
  }
  
  static FloatingActionButtonThemeData _getResponsiveFloatingActionButtonTheme(ScreenType screenType, bool isDark) {
    final elevation = _getElevationMultiplier(screenType);
    
    return FloatingActionButtonThemeData(
      elevation: 6 * elevation,
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16 * _getBorderRadiusMultiplier(screenType)),
      ),
    );
  }
  
  // Multiplier helper methods
  static double _getTextSizeMultiplier(ScreenType screenType) {
    switch (screenType) {
      case ScreenType.mobile:
        return 1.0;
      case ScreenType.tablet:
        return 1.1;
      case ScreenType.desktop:
        return 1.2;
    }
  }
  
  static double _getIconSizeMultiplier(ScreenType screenType) {
    switch (screenType) {
      case ScreenType.mobile:
        return 1.0;
      case ScreenType.tablet:
        return 1.2;
      case ScreenType.desktop:
        return 1.4;
    }
  }
  
  static double _getSpacingMultiplier(ScreenType screenType) {
    switch (screenType) {
      case ScreenType.mobile:
        return 1.0;
      case ScreenType.tablet:
        return 1.2;
      case ScreenType.desktop:
        return 1.4;
    }
  }
  
  static double _getBorderRadiusMultiplier(ScreenType screenType) {
    switch (screenType) {
      case ScreenType.mobile:
        return 1.0;
      case ScreenType.tablet:
        return 1.2;
      case ScreenType.desktop:
        return 1.4;
    }
  }
  
  static double _getElevationMultiplier(ScreenType screenType) {
    switch (screenType) {
      case ScreenType.mobile:
        return 1.0;
      case ScreenType.tablet:
        return 1.2;
      case ScreenType.desktop:
        return 1.4;
    }
  }
}

/// Responsive Theme Widget
class ResponsiveThemeWidget extends StatelessWidget {
  final Widget child;
  final bool isDark;
  
  const ResponsiveThemeWidget({
    super.key,
    required this.child,
    this.isDark = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ResponsiveThemeSystem.getResponsiveTheme(context, isDark: isDark),
      child: child,
    );
  }
}

/// Responsive Theme Builder Widget
class ResponsiveThemeBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ThemeData theme, bool isDark) builder;
  final bool isDark;
  
  const ResponsiveThemeBuilder({
    super.key,
    required this.builder,
    this.isDark = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = ResponsiveThemeSystem.getResponsiveTheme(context, isDark: isDark);
    return builder(context, theme, isDark);
  }
}

/// Responsive Color Scheme
class ResponsiveColorScheme {
  static const Map<String, Color> primaryColors = {
    'blue': Colors.blue,
    'green': Colors.green,
    'orange': Colors.orange,
    'purple': Colors.purple,
    'pink': Colors.pink,
    'red': Colors.red,
    'teal': Colors.teal,
    'indigo': Colors.indigo,
  };
  
  static const Map<String, Color> accentColors = {
    'lightBlue': Colors.lightBlue,
    'lightGreen': Colors.lightGreen,
    'amber': Colors.amber,
    'deepPurple': Colors.deepPurple,
    'deepOrange': Colors.deepOrange,
    'cyan': Colors.cyan,
    'lime': Colors.lime,
    'brown': Colors.brown,
  };
  
  static Color getPrimaryColor(String colorName) {
    return primaryColors[colorName] ?? Colors.blue;
  }
  
  static Color getAccentColor(String colorName) {
    return accentColors[colorName] ?? Colors.lightBlue;
  }
  
  static List<Color> getColorPalette(String baseColor) {
    final primary = getPrimaryColor(baseColor);
    final accent = getAccentColor(baseColor);
    
    // Create MaterialColor swatches for proper shade access
    final primarySwatch = MaterialColor(primary.value, {
      50: primary.withValues(alpha: 0.1),
      100: primary.withValues(alpha: 0.2),
      200: primary.withValues(alpha: 0.3),
      300: primary.withValues(alpha: 0.4),
      400: primary.withValues(alpha: 0.5),
      500: primary,
      600: primary.withValues(alpha: 0.7),
      700: primary.withValues(alpha: 0.8),
      800: primary.withValues(alpha: 0.9),
      900: primary.withValues(alpha: 1.0),
    });
    
    final accentSwatch = MaterialColor(accent.value, {
      50: accent.withValues(alpha: 0.1),
      100: accent.withValues(alpha: 0.2),
      200: accent.withValues(alpha: 0.3),
      300: accent.withValues(alpha: 0.4),
      400: accent.withValues(alpha: 0.5),
      500: accent,
      600: accent.withValues(alpha: 0.7),
      700: accent.withValues(alpha: 0.8),
      800: accent.withValues(alpha: 0.9),
      900: accent.withValues(alpha: 1.0),
    });
    
    return [
      primarySwatch.shade50,
      primarySwatch.shade100,
      primarySwatch.shade200,
      primarySwatch.shade300,
      primarySwatch.shade400,
      primarySwatch.shade500,
      primarySwatch.shade600,
      primarySwatch.shade700,
      primarySwatch.shade800,
      primarySwatch.shade900,
      accentSwatch.shade100,
      accentSwatch.shade200,
      accentSwatch.shade400,
      accentSwatch.shade700,
    ];
  }
}

/// Responsive Animation System
class ResponsiveAnimationSystem {
  
  /// Get responsive animation duration based on screen type
  static Duration getResponsiveDuration(BuildContext context, Duration baseDuration) {
    final screenType = ResponsiveDesignSystem.getScreenType(context);
    
    switch (screenType) {
      case ScreenType.mobile:
        return baseDuration;
      case ScreenType.tablet:
        return Duration(milliseconds: (baseDuration.inMilliseconds * 1.2).round());
      case ScreenType.desktop:
        return Duration(milliseconds: (baseDuration.inMilliseconds * 1.4).round());
    }
  }
  
  /// Get responsive animation curve based on screen type
  static Curve getResponsiveCurve(BuildContext context) {
    final screenType = ResponsiveDesignSystem.getScreenType(context);
    
    switch (screenType) {
      case ScreenType.mobile:
        return Curves.easeInOut;
      case ScreenType.tablet:
        return Curves.easeOutBack;
      case ScreenType.desktop:
        return Curves.elasticOut;
    }
  }
  
  /// Get responsive animation controller duration
  static Duration getResponsiveControllerDuration(BuildContext context, Duration baseDuration) {
    return getResponsiveDuration(context, baseDuration);
  }
}

/// Responsive Animation Widget
class ResponsiveAnimatedContainer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onAnimationComplete;
  
  const ResponsiveAnimatedContainer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.onAnimationComplete,
  });
  
  @override
  State<ResponsiveAnimatedContainer> createState() => _ResponsiveAnimatedContainerState();
}

class _ResponsiveAnimatedContainerState extends State<ResponsiveAnimatedContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ResponsiveAnimationSystem.getResponsiveControllerDuration(context, widget.duration),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: ResponsiveAnimationSystem.getResponsiveCurve(context),
    ));
    
    _controller.forward().then((_) {
      widget.onAnimationComplete?.call();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Opacity(
            opacity: _animation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}
