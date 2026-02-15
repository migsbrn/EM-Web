import 'package:flutter/material.dart';

/// Responsive utility class for handling different screen sizes and orientations
class ResponsiveUtils {
  // Breakpoints for different screen sizes
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double largeDesktopBreakpoint = 1600;

  /// Get screen type based on width
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return ScreenType.mobile;
    } else if (width < tabletBreakpoint) {
      return ScreenType.tablet;
    } else if (width < desktopBreakpoint) {
      return ScreenType.desktop;
    } else {
      return ScreenType.largeDesktop;
    }
  }

  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return getScreenType(context) == ScreenType.mobile;
  }

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    return getScreenType(context) == ScreenType.tablet;
  }

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return getScreenType(context) == ScreenType.desktop;
  }

  /// Check if current screen is large desktop
  static bool isLargeDesktop(BuildContext context) {
    return getScreenType(context) == ScreenType.largeDesktop;
  }

  /// Check if current screen is small (mobile or small tablet)
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < tabletBreakpoint;
  }

  /// Check if current screen is large (desktop or larger)
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return const EdgeInsets.all(16.0);
      case ScreenType.tablet:
        return const EdgeInsets.all(24.0);
      case ScreenType.desktop:
        return const EdgeInsets.all(32.0);
      case ScreenType.largeDesktop:
        return const EdgeInsets.all(40.0);
    }
  }

  /// Get responsive horizontal padding
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return const EdgeInsets.symmetric(horizontal: 16.0);
      case ScreenType.tablet:
        return const EdgeInsets.symmetric(horizontal: 24.0);
      case ScreenType.desktop:
        return const EdgeInsets.symmetric(horizontal: 32.0);
      case ScreenType.largeDesktop:
        return const EdgeInsets.symmetric(horizontal: 40.0);
    }
  }

  /// Get responsive vertical padding
  static EdgeInsets getResponsiveVerticalPadding(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return const EdgeInsets.symmetric(vertical: 16.0);
      case ScreenType.tablet:
        return const EdgeInsets.symmetric(vertical: 24.0);
      case ScreenType.desktop:
        return const EdgeInsets.symmetric(vertical: 32.0);
      case ScreenType.largeDesktop:
        return const EdgeInsets.symmetric(vertical: 40.0);
    }
  }

  /// Get responsive font size based on screen size
  static double getResponsiveFontSize(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet ?? mobile * 1.1;
      case ScreenType.desktop:
        return desktop ?? mobile * 1.2;
      case ScreenType.largeDesktop:
        return largeDesktop ?? mobile * 1.3;
    }
  }

  /// Get responsive icon size
  static double getResponsiveIconSize(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet ?? mobile * 1.2;
      case ScreenType.desktop:
        return desktop ?? mobile * 1.4;
      case ScreenType.largeDesktop:
        return largeDesktop ?? mobile * 1.6;
    }
  }

  /// Get responsive spacing
  static double getResponsiveSpacing(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet ?? mobile * 1.2;
      case ScreenType.desktop:
        return desktop ?? mobile * 1.4;
      case ScreenType.largeDesktop:
        return largeDesktop ?? mobile * 1.6;
    }
  }

  /// Get responsive grid columns based on screen size
  static int getResponsiveGridColumns(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return 1;
      case ScreenType.tablet:
        return 2;
      case ScreenType.desktop:
        return 3;
      case ScreenType.largeDesktop:
        return 4;
    }
  }

  /// Get responsive card width
  static double getResponsiveCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenType = getScreenType(context);
    
    switch (screenType) {
      case ScreenType.mobile:
        return screenWidth - 32; // Full width minus padding
      case ScreenType.tablet:
        return (screenWidth - 72) / 2; // Two columns with spacing
      case ScreenType.desktop:
        return (screenWidth - 96) / 3; // Three columns with spacing
      case ScreenType.largeDesktop:
        return (screenWidth - 120) / 4; // Four columns with spacing
    }
  }

  /// Get responsive container constraints
  static BoxConstraints getResponsiveConstraints(BuildContext context) {
    final screenType = getScreenType(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    switch (screenType) {
      case ScreenType.mobile:
        return BoxConstraints(
          maxWidth: screenWidth,
          minWidth: screenWidth,
        );
      case ScreenType.tablet:
        return BoxConstraints(
          maxWidth: screenWidth * 0.8,
          minWidth: screenWidth * 0.6,
        );
      case ScreenType.desktop:
        return BoxConstraints(
          maxWidth: screenWidth * 0.7,
          minWidth: screenWidth * 0.5,
        );
      case ScreenType.largeDesktop:
        return BoxConstraints(
          maxWidth: screenWidth * 0.6,
          minWidth: screenWidth * 0.4,
        );
    }
  }

  /// Get responsive border radius
  static double getResponsiveBorderRadius(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet ?? mobile * 1.2;
      case ScreenType.desktop:
        return desktop ?? mobile * 1.4;
      case ScreenType.largeDesktop:
        return largeDesktop ?? mobile * 1.6;
    }
  }

  /// Check if device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if device is in portrait orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Get responsive app bar height
  static double getResponsiveAppBarHeight(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return kToolbarHeight;
      case ScreenType.tablet:
        return kToolbarHeight * 1.1;
      case ScreenType.desktop:
        return kToolbarHeight * 1.2;
      case ScreenType.largeDesktop:
        return kToolbarHeight * 1.3;
    }
  }

  /// Get responsive bottom navigation bar height
  static double getResponsiveBottomNavHeight(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return kBottomNavigationBarHeight;
      case ScreenType.tablet:
        return kBottomNavigationBarHeight * 1.1;
      case ScreenType.desktop:
        return kBottomNavigationBarHeight * 1.2;
      case ScreenType.largeDesktop:
        return kBottomNavigationBarHeight * 1.3;
    }
  }
}

/// Screen type enumeration
enum ScreenType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// Responsive widget that adapts its child based on screen size
class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveUtils.getScreenType(context);
    
    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }
}

/// Responsive text widget that adapts font size based on screen size
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double? mobileFontSize;
  final double? tabletFontSize;
  final double? desktopFontSize;
  final double? largeDesktopFontSize;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.mobileFontSize,
    this.tabletFontSize,
    this.desktopFontSize,
    this.largeDesktopFontSize,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = ResponsiveUtils.getResponsiveFontSize(
      context,
      mobile: mobileFontSize ?? 14.0,
      tablet: tabletFontSize,
      desktop: desktopFontSize,
      largeDesktop: largeDesktopFontSize,
    );

    return Text(
      text,
      style: style?.copyWith(fontSize: fontSize) ?? TextStyle(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Responsive icon widget that adapts icon size based on screen size
class ResponsiveIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double? mobileSize;
  final double? tabletSize;
  final double? desktopSize;
  final double? largeDesktopSize;

  const ResponsiveIcon(
    this.icon, {
    super.key,
    this.color,
    this.mobileSize,
    this.tabletSize,
    this.desktopSize,
    this.largeDesktopSize,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = ResponsiveUtils.getResponsiveIconSize(
      context,
      mobile: mobileSize ?? 24.0,
      tablet: tabletSize,
      desktop: desktopSize,
      largeDesktop: largeDesktopSize,
    );

    return Icon(
      icon,
      color: color,
      size: iconSize,
    );
  }
}

/// Responsive spacing widget
class ResponsiveSpacing extends StatelessWidget {
  final double mobileSpacing;
  final double? tabletSpacing;
  final double? desktopSpacing;
  final double? largeDesktopSpacing;
  final bool isVertical;

  const ResponsiveSpacing({
    super.key,
    required this.mobileSpacing,
    this.tabletSpacing,
    this.desktopSpacing,
    this.largeDesktopSpacing,
    this.isVertical = true,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveUtils.getResponsiveSpacing(
      context,
      mobile: mobileSpacing,
      tablet: tabletSpacing,
      desktop: desktopSpacing,
      largeDesktop: largeDesktopSpacing,
    );

    return SizedBox(
      width: isVertical ? 0 : spacing,
      height: isVertical ? spacing : 0,
    );
  }
}
