import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'ShapeAssessment.dart'; // Import the assessment page
import 'responsive_utils.dart';

// A new widget to handle the shape drawing and animation.
class ShapeAnimator extends StatefulWidget {
  final int shapeId;
  final int sideCount;
  final Color color;
  @override
  final Key key;

  const ShapeAnimator({
    required this.key,
    required this.shapeId,
    required this.sideCount,
    this.color = const Color(0xFF648BA2),
  }) : super(key: key);

  @override
  _ShapeAnimatorState createState() => _ShapeAnimatorState();
}

class _ShapeAnimatorState extends State<ShapeAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _highlightedSideIndex = 0;

  @override
  void initState() {
    super.initState();
    // Set a fixed duration for circle (5 seconds) and use sideCount for other shapes
    _controller = AnimationController(
      vsync: this,
      duration:
          widget.sideCount == 0
              ? const Duration(seconds: 5)
              : Duration(seconds: widget.sideCount),
    );

    // The animation progresses from 0.0 to the number of sides or 1.0 for circle
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.sideCount == 0 ? 1.0 : widget.sideCount.toDouble(),
    ).animate(_controller)..addListener(() {
      setState(() {
        // Update the highlighted side index based on animation progress
        _highlightedSideIndex =
            widget.sideCount == 0 ? 0 : _animation.value.floor();
      });
    });

    // Start the animation as soon as the widget is built.
    _controller.forward();
  }

  void replayAnimation() {
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // The custom painter that draws the shape and highlights.
        CustomPaint(
          size: Size(
            ResponsiveUtils.getResponsiveIconSize(context, mobile: 150),
            ResponsiveUtils.getResponsiveIconSize(context, mobile: 150),
          ),
          painter: ShapePainter(
            sideCount: widget.sideCount,
            highlightedSideIndex: _highlightedSideIndex,
            progress: _animation.value,
            color: widget.color,
          ),
        ),
        ResponsiveSpacing(mobileSpacing: 24),
        // A counter text that updates with the animation.
        ResponsiveText(
          // For a circle (0 sides in our logic), don't show a counter.
          widget.sideCount > 0
              ? 'Side: ${_highlightedSideIndex > widget.sideCount ? widget.sideCount : _highlightedSideIndex}'
              : 'I have 1 continuous edge!',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4A4E69),
          ),
          mobileFontSize: 24,
          tabletFontSize: 28,
          desktopFontSize: 32,
          largeDesktopFontSize: 36,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        ResponsiveSpacing(mobileSpacing: 16),
        // Replay button
        ElevatedButton(
          onPressed: replayAnimation,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF648BA2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 12),
              ),
            ),
          ),
          child: ResponsiveIcon(
            Icons.replay,
            color: Colors.white,
            mobileSize: 30,
            tabletSize: 32,
            desktopSize: 34,
            largeDesktopSize: 36,
          ),
        ),
      ],
    );
  }
}

// The painter class responsible for drawing the shapes.
class ShapePainter extends CustomPainter {
  final int sideCount;
  final int highlightedSideIndex;
  final double progress;
  final Color color;

  ShapePainter({
    required this.sideCount,
    required this.highlightedSideIndex,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Base paint for the shape outline
    final basePaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round;

    // Highlight paint for the currently counted side
    final highlightPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round;

    // Circle is a special case
    if (sideCount == 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      // Draw the full circle outline in grey
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, basePaint);
      // Animate the drawing of the circle's circumference
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        highlightPaint,
      );
      return;
    }

    if (sideCount < 3) return; // Cannot draw a shape with less than 3 sides

    final path = Path();
    final angle = (math.pi * 2) / sideCount;

    // Calculate the vertices of the polygon
    final vertices = List.generate(sideCount, (i) {
      final x = center.dx + radius * math.cos(angle * i - math.pi / 2);
      final y = center.dy + radius * math.sin(angle * i - math.pi / 2);
      return Offset(x, y);
    });

    // Draw the full shape outline in a light grey color first
    path.moveTo(vertices.first.dx, vertices.first.dy);
    for (int i = 0; i < vertices.length; i++) {
      path.lineTo(
        vertices[(i + 1) % sideCount].dx,
        vertices[(i + 1) % sideCount].dy,
      );
    }
    canvas.drawPath(path, basePaint);

    // Draw the highlighted sides one by one
    for (int i = 0; i < highlightedSideIndex && i < sideCount; i++) {
      final p1 = vertices[i];
      final p2 = vertices[(i + 1) % sideCount];

      double sideProgress = (progress - i).clamp(0.0, 1.0);

      // If it's the currently animating side, draw it partially
      if (i == highlightedSideIndex - 1) {
        canvas.drawLine(p1, Offset.lerp(p1, p2, sideProgress)!, highlightPaint);
      } else {
        // Otherwise, draw the full side
        canvas.drawLine(p1, p2, highlightPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Repaint whenever animation values change
  }
}

class ShapesActivityPage extends StatefulWidget {
  final String nickname;
  
  const ShapesActivityPage({super.key, required this.nickname});

  @override
  _ShapesActivityPageState createState() => _ShapesActivityPageState();
}

class _ShapesActivityPageState extends State<ShapesActivityPage> {
  final PageController _pageController = PageController();
  final FlutterTts _flutterTts = FlutterTts();
  int _currentPage = 0;

  // Updated shapes data structure.
  // 'sideCount' is used for the animator. A circle is a special case with 0.
  final List<Map<String, dynamic>> shapes = const [
    {
      'sides': 'I have 4 sides',
      'corners': 'I have 4 corners',
      'name': 'I am a square',
      'sideCount': 4,
    },
    {
      'sides': 'I have 3 sides',
      'corners': 'I have 3 corners',
      'name': 'I am a triangle',
      'sideCount': 3,
    },
    {
      'sides': 'I have 5 sides',
      'corners': 'I have 5 corners',
      'name': 'I am a pentagon',
      'sideCount': 5,
    },
    {
      'sides': 'I have 6 sides',
      'corners': 'I have 6 corners',
      'name': 'I am a hexagon',
      'sideCount': 6,
    },
    {
      'sides': 'I have 8 sides',
      'corners': 'I have 8 corners',
      'name': 'I am an octagon',
      'sideCount': 8,
    },
    {
      'sides': 'I have infinite sides',
      'corners': 'I have no corners',
      'name': 'I am a circle',
      'sideCount': 0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _loadProgress();
  }

  // Speak after the first frame is rendered.
  void _speakAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _playShapeSound(_currentPage);
      }
    });
  }

  void _initializeTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentPage = prefs.getInt('shapeIndex') ?? 0;
      _pageController.jumpToPage(_currentPage);
    });
    _speakAfterBuild(); // Speak after loading progress.
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('shapeIndex', _currentPage);
  }

  void _playShapeSound(int index) async {
    if (index < 0 || index >= shapes.length) return;
    await _flutterTts.stop();
    final shape = shapes[index];
    final text = '${shape['sides']}. ${shape['corners']}. ${shape['name']}';
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _nextPage() async {
    if (_currentPage < shapes.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _flutterTts.stop();
      _showCompletionDialog();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFFFFF6DC),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/star.png', height: 150, width: 150),
                    const SizedBox(height: 20),
                    const Text(
                      "What would you like to do next?",
                      style: TextStyle(
                        fontSize: 26,
                        color: Color(0xFF4C4F6B),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context); // Close dialog
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          await prefs.setInt('shapeIndex', 0);
                          _pageController.jumpToPage(0);
                          // The onPageChanged will handle the state update and sound
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4C4F6B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          "Restart Module",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShapeAssessment(nickname: widget.nickname),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3C7E71),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          "Take Assessment",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      body: SafeArea(
        child: Column(
          children: [
            ResponsiveSpacing(mobileSpacing: 20),
            Padding(
              padding: ResponsiveUtils.getResponsivePadding(context),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: ResponsiveUtils.getResponsiveIconSize(context, mobile: 140),
                  height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 50),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF648BA2),
                      padding: ResponsiveUtils.getResponsivePadding(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 12),
                        ),
                      ),
                    ),
                    child: ResponsiveText(
                      'Go Back',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      mobileFontSize: 18,
                      tabletFontSize: 20,
                      desktopFontSize: 22,
                      largeDesktopFontSize: 24,
                    ),
                  ),
                ),
              ),
            ),
            ResponsiveSpacing(mobileSpacing: 20),
            Padding(
              padding: ResponsiveUtils.getResponsivePadding(context),
              child: ResponsiveText(
                'Instruction: Watch the sides get counted one by one.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A4E69),
                ),
                mobileFontSize: 20,
                tabletFontSize: 22,
                desktopFontSize: 24,
                largeDesktopFontSize: 26,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ResponsiveSpacing(mobileSpacing: 16),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: shapes.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  _playShapeSound(index);
                  _saveProgress();
                },
                itemBuilder: (context, index) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - 200,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildShapePage(
                            shapes[index]['sides']!,
                            shapes[index]['corners']!,
                            shapes[index]['name']!,
                            shapes[index]['sideCount']!,
                            index,
                          ),
                          ResponsiveSpacing(
                            mobileSpacing: ResponsiveUtils.isSmallScreen(context) ? 10 : 20,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: _currentPage > 0 ? _previousPage : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF648BA2),
                                  padding: ResponsiveUtils.isSmallScreen(context)
                                    ? EdgeInsets.symmetric(
                                        horizontal: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16),
                                        vertical: ResponsiveUtils.getResponsiveSpacing(context, mobile: 8),
                                      )
                                    : ResponsiveUtils.getResponsivePadding(context),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 12),
                                    ),
                                  ),
                                ),
                                child: ResponsiveText(
                                  'Previous',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  mobileFontSize: 16,
                                  tabletFontSize: 18,
                                  desktopFontSize: 20,
                                  largeDesktopFontSize: 22,
                                ),
                              ),
                              ResponsiveSpacing(
                                mobileSpacing: ResponsiveUtils.isSmallScreen(context) ? 10 : 15,
                                isVertical: false,
                              ),
                              ElevatedButton(
                                onPressed: _nextPage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF648BA2),
                                  padding: ResponsiveUtils.isSmallScreen(context)
                                    ? EdgeInsets.symmetric(
                                        horizontal: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16),
                                        vertical: ResponsiveUtils.getResponsiveSpacing(context, mobile: 8),
                                      )
                                    : ResponsiveUtils.getResponsivePadding(context),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 12),
                                    ),
                                  ),
                                ),
                                child: ResponsiveText(
                                  'Next',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  mobileFontSize: 16,
                                  tabletFontSize: 18,
                                  desktopFontSize: 20,
                                  largeDesktopFontSize: 22,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShapePage(
    String sidesText,
    String cornersText,
    String shapeText,
    int sideCount,
    int index,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 20),
          ),
        ),
        child: Container(
          width: ResponsiveUtils.isSmallScreen(context) 
            ? screenWidth * 0.85 
            : screenWidth * 0.7,
          height: ResponsiveUtils.isSmallScreen(context) 
            ? screenHeight * 0.6 
            : screenHeight * 0.58,
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => _playShapeSound(index),
                  child: Container(
                    width: ResponsiveUtils.getResponsiveIconSize(context, mobile: 40),
                    height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 40),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 8),
                      ),
                    ),
                    child: ResponsiveIcon(
                      Icons.volume_up,
                      color: Colors.black,
                      mobileSize: 24,
                      tabletSize: 26,
                      desktopSize: 28,
                      largeDesktopSize: 30,
                    ),
                  ),
                ),
              ),
              ResponsiveSpacing(mobileSpacing: ResponsiveUtils.isSmallScreen(context) ? 3 : 5),
              // The new ShapeAnimator widget replaces the old Image.asset
              ShapeAnimator(
                // Use a ValueKey to ensure the widget rebuilds on page change
                key: ValueKey<int>(_currentPage),
                shapeId: index,
                sideCount: sideCount,
              ),
              ResponsiveSpacing(mobileSpacing: ResponsiveUtils.isSmallScreen(context) ? 12 : 16),
              ResponsiveText(
                sidesText,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                mobileFontSize: 24,
                tabletFontSize: 26,
                desktopFontSize: 28,
                largeDesktopFontSize: 30,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              ResponsiveSpacing(mobileSpacing: ResponsiveUtils.isSmallScreen(context) ? 4 : 6),
              ResponsiveText(
                cornersText,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                mobileFontSize: 20,
                tabletFontSize: 22,
                desktopFontSize: 24,
                largeDesktopFontSize: 26,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              ResponsiveSpacing(mobileSpacing: ResponsiveUtils.isSmallScreen(context) ? 2 : 4),
              ResponsiveText(
                shapeText,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                mobileFontSize: 20,
                tabletFontSize: 22,
                desktopFontSize: 24,
                largeDesktopFontSize: 26,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
