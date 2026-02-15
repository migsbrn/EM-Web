import 'package:flutter/material.dart';
import 'responsive_design_system.dart';

/// Responsive Navigation System
/// Provides adaptive navigation components for different screen sizes
class ResponsiveNavigationSystem {
  
  /// Get responsive navigation type based on screen size
  static NavigationType getNavigationType(BuildContext context) {
    final screenType = ResponsiveDesignSystem.getScreenType(context);
    final isLandscape = ResponsiveDesignSystem.isLandscape(context);
    
    if (screenType == ScreenType.mobile && isLandscape) {
      return NavigationType.drawer;
    } else if (screenType == ScreenType.mobile) {
      return NavigationType.bottomNav;
    } else if (screenType == ScreenType.tablet) {
      return NavigationType.drawer;
    } else {
      return NavigationType.sidebar;
    }
  }
  
  /// Get responsive navigation items
  static List<NavigationItem> getNavigationItems() {
    return [
      NavigationItem(
        title: "Home",
        icon: Icons.home,
        route: "/home",
        color: Colors.blue,
      ),
      NavigationItem(
        title: "Lessons",
        icon: Icons.school,
        route: "/lessons",
        color: Colors.green,
      ),
      NavigationItem(
        title: "Assessments",
        icon: Icons.quiz,
        route: "/assessments",
        color: Colors.orange,
      ),
      NavigationItem(
        title: "Games",
        icon: Icons.games,
        route: "/games",
        color: Colors.purple,
      ),
      NavigationItem(
        title: "Profile",
        icon: Icons.person,
        route: "/profile",
        color: Colors.pink,
      ),
      NavigationItem(
        title: "Settings",
        icon: Icons.settings,
        route: "/settings",
        color: Colors.grey,
      ),
    ];
  }
}

enum NavigationType {
  bottomNav,
  drawer,
  sidebar,
}

class NavigationItem {
  final String title;
  final IconData icon;
  final String route;
  final Color color;
  
  NavigationItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.color,
  });
}

/// Responsive Main Layout Widget
class ResponsiveMainLayout extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final Function(int)? onNavigationChanged;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  
  const ResponsiveMainLayout({
    super.key,
    required this.child,
    this.currentIndex = 0,
    this.onNavigationChanged,
    this.title,
    this.actions,
    this.floatingActionButton,
  });
  
  @override
  State<ResponsiveMainLayout> createState() => _ResponsiveMainLayoutState();
}

class _ResponsiveMainLayoutState extends State<ResponsiveMainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutBuilder(
      builder: (context, screenType, constraints) {
        final navigationType = ResponsiveNavigationSystem.getNavigationType(context);
        final navigationItems = ResponsiveNavigationSystem.getNavigationItems();
        
        return Scaffold(
          key: _scaffoldKey,
          appBar: widget.title != null
              ? ResponsiveAppBar(
                  title: widget.title!,
                  actions: widget.actions,
                  leading: navigationType == NavigationType.drawer
                      ? IconButton(
                          icon: const ResponsiveIcon(icon: Icons.menu, size: 24),
                          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                        )
                      : null,
                )
              : null,
          drawer: navigationType == NavigationType.drawer
              ? ResponsiveDrawer(
                  currentIndex: widget.currentIndex,
                  onNavigationChanged: widget.onNavigationChanged,
                )
              : null,
          body: Row(
            children: [
              // Sidebar for desktop
              if (navigationType == NavigationType.sidebar)
                ResponsiveSidebar(
                  currentIndex: widget.currentIndex,
                  onNavigationChanged: widget.onNavigationChanged,
                ),
              
              // Main content
              Expanded(
                child: widget.child,
              ),
            ],
          ),
          bottomNavigationBar: navigationType == NavigationType.bottomNav
              ? ResponsiveBottomNavigationBar(
                  currentIndex: widget.currentIndex,
                  items: navigationItems.map((item) => BottomNavigationBarItem(
                    icon: ResponsiveIcon(icon: item.icon, size: 24),
                    label: item.title,
                  )).toList(),
                  onTap: widget.onNavigationChanged,
                )
              : null,
          floatingActionButton: widget.floatingActionButton,
        );
      },
    );
  }
}

/// Responsive Drawer Widget
class ResponsiveDrawer extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onNavigationChanged;
  
  const ResponsiveDrawer({
    super.key,
    required this.currentIndex,
    this.onNavigationChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    final navigationItems = ResponsiveNavigationSystem.getNavigationItems();
    
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            height: ResponsiveDesignSystem.getResponsiveHeight(context, 200),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: ResponsiveDesignSystem.getResponsivePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      "EasyMind",
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    ResponsiveSpacing(height: 8),
                    ResponsiveText(
                      "Learning Made Fun",
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Navigation items
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: navigationItems.length,
              itemBuilder: (context, index) {
                final item = navigationItems[index];
                final isSelected = currentIndex == index;
                
                return ListTile(
                  leading: ResponsiveIcon(
                    icon: item.icon,
                    size: 24,
                    color: isSelected ? item.color : Colors.grey.shade600,
                  ),
                  title: ResponsiveText(
                    item.title,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? item.color : Colors.black87,
                  ),
                  selected: isSelected,
                  selectedTileColor: item.color.withValues(alpha: 0.1),
                  onTap: () {
                    Navigator.of(context).pop();
                    onNavigationChanged?.call(index);
                  },
                );
              },
            ),
          ),
          
          // Footer
          Container(
            padding: ResponsiveDesignSystem.getResponsivePadding(context),
            child: Column(
              children: [
                const Divider(),
                ResponsiveText(
                  "Version 1.0.0",
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Responsive Sidebar Widget
class ResponsiveSidebar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onNavigationChanged;
  
  const ResponsiveSidebar({
    super.key,
    required this.currentIndex,
    this.onNavigationChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    final navigationItems = ResponsiveNavigationSystem.getNavigationItems();
    final sidebarWidth = ResponsiveDesignSystem.getResponsiveWidth(context, 0.2);
    
    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          right: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: ResponsiveDesignSystem.getResponsiveHeight(context, 120),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: ResponsiveDesignSystem.getResponsivePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      "EasyMind",
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    ResponsiveSpacing(height: 4),
                    ResponsiveText(
                      "Learning Made Fun",
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Navigation items
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: navigationItems.length,
              itemBuilder: (context, index) {
                final item = navigationItems[index];
                final isSelected = currentIndex == index;
                
                return Container(
                  margin: ResponsiveDesignSystem.getResponsiveMargin(context),
                  child: ListTile(
                    leading: ResponsiveIcon(
                      icon: item.icon,
                      size: 20,
                      color: isSelected ? item.color : Colors.grey.shade600,
                    ),
                    title: ResponsiveText(
                      item.title,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? item.color : Colors.black87,
                    ),
                    selected: isSelected,
                    selectedTileColor: item.color.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ResponsiveDesignSystem.getResponsiveBorderRadius(context, 8),
                      ),
                    ),
                    onTap: () => onNavigationChanged?.call(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Responsive Tab Bar Widget
class ResponsiveTabBar extends StatelessWidget {
  final List<String> tabs;
  final int currentIndex;
  final Function(int)? onTabChanged;
  final bool isScrollable;
  
  const ResponsiveTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    this.onTabChanged,
    this.isScrollable = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutBuilder(
      builder: (context, screenType, constraints) {
        return TabBar(
          tabs: tabs.map((tab) => Tab(
            child: ResponsiveText(
              tab,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          )).toList(),
          isScrollable: isScrollable || screenType == ScreenType.mobile,
          onTap: onTabChanged,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
        );
      },
    );
  }
}

/// Responsive Tab Bar View Widget
class ResponsiveTabBarView extends StatelessWidget {
  final List<Widget> children;
  final int currentIndex;
  final TabController? controller;
  
  const ResponsiveTabBarView({
    super.key,
    required this.children,
    required this.currentIndex,
    this.controller,
  });
  
  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: controller,
      children: children,
    );
  }
}

/// Responsive Floating Action Button Widget
class ResponsiveFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  
  const ResponsiveFloatingActionButton({
    super.key,
    this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutBuilder(
      builder: (context, screenType, constraints) {
        final responsiveSize = ResponsiveDesignSystem.getResponsiveIconSize(context, 24);
        
        return FloatingActionButton(
          onPressed: onPressed,
          tooltip: tooltip,
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          foregroundColor: foregroundColor ?? Colors.white,
          child: ResponsiveIcon(
            icon: icon,
            size: responsiveSize,
            color: foregroundColor ?? Colors.white,
          ),
        );
      },
    );
  }
}

/// Responsive Search Bar Widget
class ResponsiveSearchBar extends StatefulWidget {
  final String? hintText;
  final Function(String)? onSearch;
  final Function(String)? onChanged;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  
  const ResponsiveSearchBar({
    super.key,
    this.hintText,
    this.onSearch,
    this.onChanged,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
  });
  
  @override
  State<ResponsiveSearchBar> createState() => _ResponsiveSearchBarState();
}

class _ResponsiveSearchBarState extends State<ResponsiveSearchBar> {
  final TextEditingController _controller = TextEditingController();
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutBuilder(
      builder: (context, screenType, constraints) {
        return Container(
          padding: ResponsiveDesignSystem.getResponsivePadding(context),
          child: TextField(
            controller: _controller,
            enabled: widget.enabled,
            decoration: InputDecoration(
              hintText: widget.hintText ?? "Search...",
              prefixIcon: widget.prefixIcon ?? const ResponsiveIcon(icon: Icons.search, size: 20),
              suffixIcon: widget.suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveDesignSystem.getResponsiveBorderRadius(context, 12),
                ),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: widget.onChanged,
            onSubmitted: widget.onSearch,
          ),
        );
      },
    );
  }
}

/// Responsive Filter Chips Widget
class ResponsiveFilterChips extends StatelessWidget {
  final List<String> options;
  final List<String> selectedOptions;
  final Function(String, bool)? onSelectionChanged;
  final bool multiSelect;
  
  const ResponsiveFilterChips({
    super.key,
    required this.options,
    required this.selectedOptions,
    this.onSelectionChanged,
    this.multiSelect = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutBuilder(
      builder: (context, screenType, constraints) {
        return Wrap(
          spacing: ResponsiveDesignSystem.getResponsiveSpacing(context, 8),
          runSpacing: ResponsiveDesignSystem.getResponsiveSpacing(context, 8),
          children: options.map((option) {
            final isSelected = selectedOptions.contains(option);
            
            return FilterChip(
              label: ResponsiveText(
                option,
                fontSize: 14,
                color: isSelected ? Colors.white : Colors.black87,
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (multiSelect) {
                  onSelectionChanged?.call(option, selected);
                } else {
                  // Single select - clear others
                  for (final otherOption in options) {
                    if (otherOption != option) {
                      onSelectionChanged?.call(otherOption, false);
                    }
                  }
                  onSelectionChanged?.call(option, selected);
                }
              },
              backgroundColor: Colors.grey.shade200,
              selectedColor: Colors.blue,
              checkmarkColor: Colors.white,
            );
          }).toList(),
        );
      },
    );
  }
}
