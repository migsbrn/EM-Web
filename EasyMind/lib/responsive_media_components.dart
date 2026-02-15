import 'package:flutter/material.dart';
import 'dart:async';
import 'responsive_design_system.dart';

/// Responsive Media Components
/// Provides adaptive media display components for different screen sizes
class ResponsiveMediaComponents {
  
  /// Get responsive image size based on screen type
  static Size getResponsiveImageSize(BuildContext context, Size baseSize) {
    final screenType = ResponsiveDesignSystem.getScreenType(context);
    final isLandscape = ResponsiveDesignSystem.isLandscape(context);
    
    double widthMultiplier = 1.0;
    double heightMultiplier = 1.0;
    
    switch (screenType) {
      case ScreenType.mobile:
        widthMultiplier = isLandscape ? 0.6 : 1.0;
        heightMultiplier = isLandscape ? 0.8 : 1.0;
        break;
      case ScreenType.tablet:
        widthMultiplier = 0.8;
        heightMultiplier = 0.9;
        break;
      case ScreenType.desktop:
        widthMultiplier = 0.6;
        heightMultiplier = 0.7;
        break;
    }
    
    return Size(
      baseSize.width * widthMultiplier,
      baseSize.height * heightMultiplier,
    );
  }
  
  /// Get responsive video aspect ratio
  static double getResponsiveVideoAspectRatio(BuildContext context) {
    final screenType = ResponsiveDesignSystem.getScreenType(context);
    final isLandscape = ResponsiveDesignSystem.isLandscape(context);
    
    if (isLandscape) {
      return 16 / 9; // Standard widescreen
    }
    
    switch (screenType) {
      case ScreenType.mobile:
        return 4 / 3; // More square for mobile portrait
      case ScreenType.tablet:
        return 3 / 2; // Slightly wider
      case ScreenType.desktop:
        return 16 / 9; // Full widescreen
    }
  }
}

/// Responsive Image Widget
class ResponsiveImage extends StatelessWidget {
  final String imagePath;
  final String? assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? color;
  final Widget? placeholder;
  final Widget? errorWidget;
  
  const ResponsiveImage({
    super.key,
    required this.imagePath,
    this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.color,
    this.placeholder,
    this.errorWidget,
  });
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutBuilder(
      builder: (context, screenType, constraints) {
        final responsiveWidth = width != null 
            ? ResponsiveDesignSystem.getResponsiveWidth(context, width!)
            : null;
        final responsiveHeight = height != null 
            ? ResponsiveDesignSystem.getResponsiveHeight(context, height!)
            : null;
        final responsiveBorderRadius = borderRadius != null
            ? BorderRadius.circular(
                ResponsiveDesignSystem.getResponsiveBorderRadius(
                  context, 
                  borderRadius!.topLeft.x,
                ),
              )
            : null;
        
        Widget imageWidget;
        
        if (assetPath != null) {
          imageWidget = Image.asset(
            assetPath!,
            width: responsiveWidth,
            height: responsiveHeight,
            fit: fit,
            color: color,
            errorBuilder: (context, error, stackTrace) {
              return errorWidget ?? Container(
                width: responsiveWidth,
                height: responsiveHeight,
                color: Colors.grey.shade300,
                child: const ResponsiveIcon(
                  icon: Icons.error_outline,
                  size: 48,
                  color: Colors.grey,
                ),
              );
            },
          );
        } else {
          imageWidget = Image.network(
            imagePath,
            width: responsiveWidth,
            height: responsiveHeight,
            fit: fit,
            color: color,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return placeholder ?? Container(
                width: responsiveWidth,
                height: responsiveHeight,
                color: Colors.grey.shade300,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return errorWidget ?? Container(
                width: responsiveWidth,
                height: responsiveHeight,
                color: Colors.grey.shade300,
                child: const ResponsiveIcon(
                  icon: Icons.error_outline,
                  size: 48,
                  color: Colors.grey,
                ),
              );
            },
          );
        }
        
        if (responsiveBorderRadius != null) {
          return ClipRRect(
            borderRadius: responsiveBorderRadius,
            child: imageWidget,
          );
        }
        
        return imageWidget;
      },
    );
  }
}

/// Responsive Video Widget
class ResponsiveVideoWidget extends StatelessWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final bool autoplay;
  final bool showControls;
  final double? aspectRatio;
  final VoidCallback? onTap;
  
  const ResponsiveVideoWidget({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.autoplay = false,
    this.showControls = true,
    this.aspectRatio,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutBuilder(
      builder: (context, screenType, constraints) {
        final responsiveAspectRatio = aspectRatio ?? 
            ResponsiveMediaComponents.getResponsiveVideoAspectRatio(context);
        
        return AspectRatio(
          aspectRatio: responsiveAspectRatio,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                ResponsiveDesignSystem.getResponsiveBorderRadius(context, 12),
              ),
              color: Colors.black,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                ResponsiveDesignSystem.getResponsiveBorderRadius(context, 12),
              ),
              child: Stack(
                children: [
                  // Video placeholder (in a real app, you'd use a video player)
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black,
                    child: thumbnailUrl != null
                        ? ResponsiveImage(
                            imagePath: thumbnailUrl!,
                            fit: BoxFit.cover,
                          )
                        : const Center(
                            child: ResponsiveIcon(
                              icon: Icons.play_circle_outline,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  
                  // Play button overlay
                  if (onTap != null)
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onTap,
                          child: const Center(
                            child: ResponsiveIcon(
                              icon: Icons.play_circle_filled,
                              size: 80,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Controls overlay
                  if (showControls)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: ResponsiveDesignSystem.getResponsivePadding(context),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            ResponsiveIcon(
                              icon: Icons.play_arrow,
                              size: 24,
                              color: Colors.white,
                            ),
                            ResponsiveSpacing(width: 8, isVertical: false),
                            Expanded(
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: 0.3, // Progress indicator
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            ResponsiveSpacing(width: 8, isVertical: false),
                            ResponsiveText(
                              "2:30",
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Responsive Audio Player Widget
class ResponsiveAudioPlayer extends StatefulWidget {
  final String audioUrl;
  final String title;
  final String? artist;
  final String? coverImageUrl;
  final bool showControls;
  final bool showProgress;
  
  const ResponsiveAudioPlayer({
    super.key,
    required this.audioUrl,
    required this.title,
    this.artist,
    this.coverImageUrl,
    this.showControls = true,
    this.showProgress = true,
  });
  
  @override
  State<ResponsiveAudioPlayer> createState() => _ResponsiveAudioPlayerState();
}

class _ResponsiveAudioPlayerState extends State<ResponsiveAudioPlayer> {
  bool _isPlaying = false;
  double _progress = 0.0;
  final Duration _duration = Duration.zero;
  final Duration _position = Duration.zero;
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutBuilder(
      builder: (context, screenType, constraints) {
        return ResponsiveCard(
          child: Column(
            children: [
              // Cover image and info
              Row(
                children: [
                  if (widget.coverImageUrl != null) ...[
                    ResponsiveImage(
                      imagePath: widget.coverImageUrl!,
                      width: 0.15,
                      height: 0.15,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    ResponsiveSpacing(width: 16, isVertical: false),
                  ],
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResponsiveText(
                          widget.title,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        if (widget.artist != null) ...[
                          ResponsiveSpacing(height: 4),
                          ResponsiveText(
                            widget.artist!,
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              
              ResponsiveSpacing(height: 16),
              
              // Progress bar
              if (widget.showProgress) ...[
                Column(
                  children: [
                    Slider(
                      value: _progress,
                      onChanged: (value) {
                        setState(() {
                          _progress = value;
                        });
                      },
                      activeColor: Colors.blue,
                      inactiveColor: Colors.grey.shade300,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ResponsiveText(
                          _formatDuration(_position),
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        ResponsiveText(
                          _formatDuration(_duration),
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ],
                ),
                ResponsiveSpacing(height: 16),
              ],
              
              // Controls
              if (widget.showControls)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        // Previous track
                      },
                      icon: const ResponsiveIcon(
                        icon: Icons.skip_previous,
                        size: 32,
                        color: Colors.grey,
                      ),
                    ),
                    ResponsiveSpacing(width: 16, isVertical: false),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isPlaying = !_isPlaying;
                        });
                      },
                      icon: ResponsiveIcon(
                        icon: _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        size: 48,
                        color: Colors.blue,
                      ),
                    ),
                    ResponsiveSpacing(width: 16, isVertical: false),
                    IconButton(
                      onPressed: () {
                        // Next track
                      },
                      icon: const ResponsiveIcon(
                        icon: Icons.skip_next,
                        size: 32,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}

/// Responsive Gallery Widget
class ResponsiveGallery extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final bool showThumbnails;
  final Function(int)? onImageChanged;
  
  const ResponsiveGallery({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.showThumbnails = true,
    this.onImageChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutBuilder(
      builder: (context, screenType, constraints) {
        return Column(
          children: [
            // Main image
            Expanded(
              child: PageView.builder(
                itemCount: imageUrls.length,
                onPageChanged: onImageChanged,
                itemBuilder: (context, index) {
                  return ResponsiveImage(
                    imagePath: imageUrls[index],
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
            
            // Thumbnails
            if (showThumbnails && imageUrls.length > 1) ...[
              ResponsiveSpacing(height: 16),
              SizedBox(
                height: ResponsiveDesignSystem.getResponsiveHeight(context, 80),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: ResponsiveDesignSystem.getResponsiveSpacing(context, 8),
                      ),
                      child: ResponsiveImage(
                        imagePath: imageUrls[index],
                        width: 0.2,
                        height: 0.2,
                        borderRadius: BorderRadius.circular(8),
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Responsive Carousel Widget
class ResponsiveCarousel extends StatefulWidget {
  final List<Widget> children;
  final double? height;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final bool showIndicators;
  final bool showArrows;
  final PageController? controller;
  
  const ResponsiveCarousel({
    super.key,
    required this.children,
    this.height,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.showIndicators = true,
    this.showArrows = true,
    this.controller,
  });
  
  @override
  State<ResponsiveCarousel> createState() => _ResponsiveCarouselState();
}

class _ResponsiveCarouselState extends State<ResponsiveCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _autoPlayTimer;
  
  @override
  void initState() {
    super.initState();
    _pageController = widget.controller ?? PageController();
    
    if (widget.autoPlay) {
      _startAutoPlay();
    }
  }
  
  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    if (widget.controller == null) {
      _pageController.dispose();
    }
    super.dispose();
  }
  
  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(widget.autoPlayInterval, (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutBuilder(
      builder: (context, screenType, constraints) {
        final responsiveHeight = widget.height ?? 
            ResponsiveDesignSystem.getResponsiveHeight(context, 200);
        
        return Column(
          children: [
            // Carousel content
            SizedBox(
              height: responsiveHeight,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemCount: widget.children.length,
                    itemBuilder: (context, index) {
                      return widget.children[index];
                    },
                  ),
                  
                  // Navigation arrows
                  if (widget.showArrows && widget.children.length > 1) ...[
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: IconButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const ResponsiveIcon(
                            icon: Icons.chevron_left,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: IconButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const ResponsiveIcon(
                            icon: Icons.chevron_right,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Indicators
            if (widget.showIndicators && widget.children.length > 1) ...[
              ResponsiveSpacing(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.children.length,
                  (index) => Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: ResponsiveDesignSystem.getResponsiveSpacing(context, 4),
                    ),
                    width: ResponsiveDesignSystem.getResponsiveSpacing(context, 8),
                    height: ResponsiveDesignSystem.getResponsiveSpacing(context, 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index 
                          ? Colors.blue 
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Responsive Document Viewer Widget
class ResponsiveDocumentViewer extends StatelessWidget {
  final String documentUrl;
  final String title;
  final String? description;
  final bool showDownloadButton;
  final bool showPrintButton;
  
  const ResponsiveDocumentViewer({
    super.key,
    required this.documentUrl,
    required this.title,
    this.description,
    this.showDownloadButton = true,
    this.showPrintButton = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutBuilder(
      builder: (context, screenType, constraints) {
        return ResponsiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  ResponsiveIcon(
                    icon: Icons.description,
                    size: 24,
                    color: Colors.blue,
                  ),
                  ResponsiveSpacing(width: 12, isVertical: false),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResponsiveText(
                          title,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        if (description != null) ...[
                          ResponsiveSpacing(height: 4),
                          ResponsiveText(
                            description!,
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              
              ResponsiveSpacing(height: 16),
              
              // Document preview placeholder
              Container(
                width: double.infinity,
                height: ResponsiveDesignSystem.getResponsiveHeight(context, 200),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(
                    ResponsiveDesignSystem.getResponsiveBorderRadius(context, 8),
                  ),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ResponsiveIcon(
                      icon: Icons.picture_as_pdf,
                      size: 48,
                      color: Colors.red,
                    ),
                    ResponsiveSpacing(height: 8),
                    ResponsiveText(
                      "PDF Document",
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    ResponsiveSpacing(height: 4),
                    ResponsiveText(
                      "Tap to view",
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
              
              ResponsiveSpacing(height: 16),
              
              // Action buttons
              Row(
                children: [
                  if (showDownloadButton)
                    Expanded(
                      child: ResponsiveButton(
                        text: "Download",
                        onPressed: () {
                          // Download functionality
                        },
                        backgroundColor: Colors.green,
                        icon: Icons.download,
                      ),
                    ),
                  if (showDownloadButton && showPrintButton)
                    ResponsiveSpacing(width: 12, isVertical: false),
                  if (showPrintButton)
                    Expanded(
                      child: ResponsiveButton(
                        text: "Print",
                        onPressed: () {
                          // Print functionality
                        },
                        backgroundColor: Colors.orange,
                        icon: Icons.print,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
