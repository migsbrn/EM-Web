import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Responsive Design System for Flutter Mobile App
/// Provides adaptive layouts, flexible widgets, and responsive components
class ResponsiveDesignSystem {
  
  /// Breakpoints for different screen sizes
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  
  /// Get screen type based on width
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return ScreenType.mobile;
    } else if (width < tabletBreakpoint) {
      return ScreenType.tablet;
    } else {
      return ScreenType.desktop;
    }
  }
  
  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return const EdgeInsets.all(16);
      case ScreenType.tablet:
        return const EdgeInsets.all(24);
      case ScreenType.desktop:
        return const EdgeInsets.all(32);
    }
  }
  
  /// Get responsive margin based on screen size
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ScreenType.tablet:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case ScreenType.desktop:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }
  
  /// Get responsive font size based on screen size
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return baseFontSize;
      case ScreenType.tablet:
        return baseFontSize * 1.1;
      case ScreenType.desktop:
        return baseFontSize * 1.2;
    }
  }
  
  /// Get responsive icon size based on screen size
  static double getResponsiveIconSize(BuildContext context, double baseIconSize) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return baseIconSize;
      case ScreenType.tablet:
        return baseIconSize * 1.2;
      case ScreenType.desktop:
        return baseIconSize * 1.4;
    }
  }
  
  /// Get responsive button height based on screen size
  static double getResponsiveButtonHeight(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return 48;
      case ScreenType.tablet:
        return 56;
      case ScreenType.desktop:
        return 64;
    }
  }
  
  /// Get responsive spacing based on screen size
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return baseSpacing;
      case ScreenType.tablet:
        return baseSpacing * 1.2;
      case ScreenType.desktop:
        return baseSpacing * 1.4;
    }
  }
  
  /// Get responsive grid columns based on screen size
  static int getResponsiveColumns(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return 1;
      case ScreenType.tablet:
        return 2;
      case ScreenType.desktop:
        return 3;
    }
  }
  
  /// Get responsive card width based on screen size
  static double getResponsiveCardWidth(BuildContext context) {
    final screenType = getScreenType(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    switch (screenType) {
      case ScreenType.mobile:
        return (screenWidth - 32).toDouble(); // Full width minus padding
      case ScreenType.tablet:
        return ((screenWidth - 48) / 2).toDouble(); // Half width minus padding
      case ScreenType.desktop:
        return ((screenWidth - 64) / 3).toDouble(); // Third width minus padding
    }
  }
  
  /// Check if device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
  
  /// Get responsive height based on screen size and orientation
  static double getResponsiveHeight(BuildContext context, double baseHeight) {
    final screenType = getScreenType(context);
    final isLandscapeMode = isLandscape(context);
    
    if (isLandscapeMode) {
      return baseHeight * 0.8; // Reduce height in landscape
    }
    
    switch (screenType) {
      case ScreenType.mobile:
        return baseHeight;
      case ScreenType.tablet:
        return baseHeight * 1.1;
      case ScreenType.desktop:
        return baseHeight * 1.2;
    }
  }
  
  /// Get responsive width based on screen size
  static double getResponsiveWidth(BuildContext context, double baseWidth) {
    final screenType = getScreenType(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    switch (screenType) {
      case ScreenType.mobile:
        return (screenWidth * baseWidth).toDouble();
      case ScreenType.tablet:
        return (screenWidth * baseWidth * 0.8).toDouble();
      case ScreenType.desktop:
        return (screenWidth * baseWidth * 0.6).toDouble();
    }
  }
  
  /// Get responsive border radius based on screen size
  static double getResponsiveBorderRadius(BuildContext context, double baseRadius) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return baseRadius;
      case ScreenType.tablet:
        return baseRadius * 1.2;
      case ScreenType.desktop:
        return baseRadius * 1.4;
    }
  }
  
  /// Get responsive elevation based on screen size
  static double getResponsiveElevation(BuildContext context, double baseElevation) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return baseElevation;
      case ScreenType.tablet:
        return baseElevation * 1.2;
      case ScreenType.desktop:
        return baseElevation * 1.4;
    }
  }
}

enum ScreenType {
  mobile,
  tablet,
  desktop,
}

/// Responsive Container Widget
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double? width;
  final double? height;
  final BoxDecoration? decoration;
  final Alignment? alignment;
  
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.width,
    this.height,
    this.decoration,
    this.alignment,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width != null ? ResponsiveDesignSystem.getResponsiveWidth(context, width!) : null,
      height: height != null ? ResponsiveDesignSystem.getResponsiveHeight(context, height!) : null,
      padding: padding ?? ResponsiveDesignSystem.getResponsivePadding(context),
      margin: margin ?? ResponsiveDesignSystem.getResponsiveMargin(context),
      color: color,
      decoration: decoration,
      alignment: alignment,
      child: child,
    );
  }
}

/// Responsive Text Widget
class ResponsiveText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle? style;
  
  const ResponsiveText(
    this.text, {
    super.key,
    required this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.style,
  });
  
  @override
  Widget build(BuildContext context) {
    final responsiveFontSize = ResponsiveDesignSystem.getResponsiveFontSize(context, fontSize);
    
    return Text(
      text,
      style: style ?? TextStyle(
        fontSize: responsiveFontSize,
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Responsive Button Widget
class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final EdgeInsets? padding;
  final double? borderRadius;
  final IconData? icon;
  final bool isFullWidth;
  final bool isLoading;
  
  const ResponsiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.padding,
    this.borderRadius,
    this.icon,
    this.isFullWidth = true,
    this.isLoading = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final responsiveHeight = ResponsiveDesignSystem.getResponsiveButtonHeight(context);
    final responsiveFontSize = ResponsiveDesignSystem.getResponsiveFontSize(context, fontSize ?? 16);
    final responsiveBorderRadius = ResponsiveDesignSystem.getResponsiveBorderRadius(context, borderRadius ?? 8);
    final responsivePadding = padding ?? EdgeInsets.symmetric(
      horizontal: ResponsiveDesignSystem.getResponsiveSpacing(context, 16),
      vertical: ResponsiveDesignSystem.getResponsiveSpacing(context, 8),
    );
    
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: responsiveHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          foregroundColor: textColor ?? Colors.white,
          padding: responsivePadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsiveBorderRadius),
          ),
          elevation: ResponsiveDesignSystem.getResponsiveElevation(context, 2),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor ?? Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: ResponsiveDesignSystem.getResponsiveIconSize(context, 20),
                    ),
                    SizedBox(width: ResponsiveDesignSystem.getResponsiveSpacing(context, 8)),
                  ],
                  ResponsiveText(
                    text,
                    fontSize: responsiveFontSize,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? Colors.white,
                  ),
                ],
              ),
      ),
    );
  }
}

/// Responsive Card Widget
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double? elevation;
  final double? borderRadius;
  final VoidCallback? onTap;
  
  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final responsiveElevation = ResponsiveDesignSystem.getResponsiveElevation(context, elevation ?? 2);
    final responsiveBorderRadius = ResponsiveDesignSystem.getResponsiveBorderRadius(context, borderRadius ?? 12);
    final responsivePadding = padding ?? ResponsiveDesignSystem.getResponsivePadding(context);
    final responsiveMargin = margin ?? ResponsiveDesignSystem.getResponsiveMargin(context);
    
    return Card(
      elevation: responsiveElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(responsiveBorderRadius),
      ),
      color: color,
      margin: responsiveMargin,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(responsiveBorderRadius),
        child: Padding(
          padding: responsivePadding,
          child: child,
        ),
      ),
    );
  }
}

/// Responsive Grid Widget
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? crossAxisCount;
  final double? childAspectRatio;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.crossAxisCount,
    this.childAspectRatio,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });
  
  @override
  Widget build(BuildContext context) {
    final responsiveColumns = crossAxisCount ?? ResponsiveDesignSystem.getResponsiveColumns(context);
    final responsiveSpacing = ResponsiveDesignSystem.getResponsiveSpacing(context, spacing);
    final responsiveRunSpacing = ResponsiveDesignSystem.getResponsiveSpacing(context, runSpacing);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: responsiveColumns,
        crossAxisSpacing: responsiveSpacing,
        mainAxisSpacing: responsiveRunSpacing,
        childAspectRatio: childAspectRatio ?? 1.0,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Responsive List Widget
class ResponsiveList extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsets? padding;
  
  const ResponsiveList({
    super.key,
    required this.children,
    this.spacing = 16,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
  });
  
  @override
  Widget build(BuildContext context) {
    final responsiveSpacing = ResponsiveDesignSystem.getResponsiveSpacing(context, spacing);
    final responsivePadding = padding ?? ResponsiveDesignSystem.getResponsivePadding(context);
    
    return ListView.separated(
      physics: physics,
      shrinkWrap: shrinkWrap,
      padding: responsivePadding,
      itemCount: children.length,
      separatorBuilder: (context, index) => SizedBox(height: responsiveSpacing),
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Responsive Spacing Widget
class ResponsiveSpacing extends StatelessWidget {
  final double height;
  final double width;
  final bool isVertical;
  
  const ResponsiveSpacing({
    super.key,
    this.height = 16,
    this.width = 16,
    this.isVertical = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final responsiveHeight = ResponsiveDesignSystem.getResponsiveSpacing(context, height);
    final responsiveWidth = ResponsiveDesignSystem.getResponsiveSpacing(context, width);
    
    return SizedBox(
      height: isVertical ? responsiveHeight : 0,
      width: isVertical ? 0 : responsiveWidth,
    );
  }
}

/// Responsive Icon Widget
class ResponsiveIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  
  const ResponsiveIcon({
    super.key,
    required this.icon,
    required this.size,
    this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    final responsiveSize = ResponsiveDesignSystem.getResponsiveIconSize(context, size);
    
    return Icon(
      icon,
      size: responsiveSize,
      color: color,
    );
  }
}

/// Responsive AppBar Widget
class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool centerTitle;
  
  const ResponsiveAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final responsiveElevation = ResponsiveDesignSystem.getResponsiveElevation(context, elevation ?? 4);
    final responsiveFontSize = ResponsiveDesignSystem.getResponsiveFontSize(context, 20);
    
    return AppBar(
      title: ResponsiveText(
        title,
        fontSize: responsiveFontSize,
        fontWeight: FontWeight.w600,
        color: foregroundColor,
      ),
      actions: actions,
      leading: leading,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: responsiveElevation,
      centerTitle: centerTitle,
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Responsive Bottom Navigation Bar Widget
class ResponsiveBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final List<BottomNavigationBarItem> items;
  final ValueChanged<int>? onTap;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double? elevation;
  
  const ResponsiveBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.items,
    this.onTap,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation,
  });
  
  @override
  Widget build(BuildContext context) {
    final responsiveElevation = ResponsiveDesignSystem.getResponsiveElevation(context, elevation ?? 8);
    final screenType = ResponsiveDesignSystem.getScreenType(context);
    
    return BottomNavigationBar(
      currentIndex: currentIndex,
      items: items,
      onTap: onTap,
      backgroundColor: backgroundColor,
      selectedItemColor: selectedItemColor,
      unselectedItemColor: unselectedItemColor,
      elevation: responsiveElevation,
      type: screenType == ScreenType.mobile ? BottomNavigationBarType.fixed : BottomNavigationBarType.shifting,
      selectedFontSize: ResponsiveDesignSystem.getResponsiveFontSize(context, 12),
      unselectedFontSize: ResponsiveDesignSystem.getResponsiveFontSize(context, 10),
    );
  }
}

/// Responsive Dialog Widget
class ResponsiveDialog extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final double? maxWidth;
  final double? maxHeight;
  final EdgeInsets? padding;
  
  const ResponsiveDialog({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.maxWidth,
    this.maxHeight,
    this.padding,
  });
  
  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveDesignSystem.getScreenType(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    double dialogWidth;
    double dialogHeight;
    
    switch (screenType) {
      case ScreenType.mobile:
        dialogWidth = screenWidth * 0.9;
        dialogHeight = screenHeight * 0.6;
        break;
      case ScreenType.tablet:
        dialogWidth = screenWidth * 0.7;
        dialogHeight = screenHeight * 0.5;
        break;
      case ScreenType.desktop:
        dialogWidth = screenWidth * 0.5;
        dialogHeight = screenHeight * 0.4;
        break;
    }
    
    return Dialog(
      child: Container(
        width: maxWidth ?? dialogWidth,
        height: maxHeight ?? dialogHeight,
        padding: padding ?? ResponsiveDesignSystem.getResponsivePadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              ResponsiveText(
                title!,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),
              ResponsiveSpacing(height: 16),
            ],
            Expanded(child: child),
            if (actions != null) ...[
              ResponsiveSpacing(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Responsive Safe Area Widget
class ResponsiveSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
  
  const ResponsiveSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }
}

/// Responsive Orientation Builder Widget
class ResponsiveOrientationBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Orientation orientation) builder;
  
  const ResponsiveOrientationBuilder({
    super.key,
    required this.builder,
  });
  
  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: builder,
    );
  }
}

/// Responsive Layout Builder Widget
class ResponsiveLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenType screenType, BoxConstraints constraints) builder;
  
  const ResponsiveLayoutBuilder({
    super.key,
    required this.builder,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenType = ResponsiveDesignSystem.getScreenType(context);
        return builder(context, screenType, constraints);
      },
    );
  }
}
