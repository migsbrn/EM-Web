import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'LearnShapeAssessment.dart';
import 'responsive_utils.dart';

class LearnShapes extends StatefulWidget {
  final String nickname;
  const LearnShapes({super.key, required this.nickname});

  @override
  _LearnShapesState createState() => _LearnShapesState();
}

class _LearnShapesState extends State<LearnShapes>
    with TickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  String? _animationDirection;

  int _currentIndex = 0;

  final List<Map<String, dynamic>> _items = [
    {'type': 'shape', 'name': 'Circle', 'image': 'assets/circle.png'},
    {
      'type': 'example',
      'description': 'A doughnut has the shape of a Circle.',
      'image': 'assets/doughnut1.png',
    },
    {'type': 'shape', 'name': 'Square', 'image': 'assets/square.png'},
    {
      'type': 'example',
      'description': 'A box has the shape of a Square.',
      'image': 'assets/box1.png',
    },
    {'type': 'shape', 'name': 'Triangle', 'image': 'assets/triangle.png'},
    {
      'type': 'example',
      'description': 'A slice of pizza has the shape of a Triangle.',
      'image': 'assets/pizza1.png',
    },
    {'type': 'shape', 'name': 'Rectangle', 'image': 'assets/rectangle.png'},
    {
      'type': 'example',
      'description': 'An envelope has the shape of a Rectangle.',
      'image': 'assets/envelope1.png',
    },
    {'type': 'shape', 'name': 'Star', 'image': 'assets/sta.png'},
    {
      'type': 'example',
      'description': 'A balloon has the shape of a Star.',
      'image': 'assets/balloons.png',
    },
  ];

  void _speakContent() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.4);
    await flutterTts.setPitch(1.0);
    final item = _items[_currentIndex];
    if (item['type'] == 'shape') {
      await flutterTts.speak(item['name']!);
    } else {
      await flutterTts.speak(item['description']!);
    }
  }

  void _nextShape() async {
    if (_currentIndex < _items.length - 1) {
      setState(() {
        _animationDirection = 'next';
        _currentIndex++;
      });
      await Future.delayed(const Duration(milliseconds: 400));
      _speakContent();
    } else {
      await flutterTts.stop();
      _showCompletionDialog();
    }
  }

  void _previousShape() async {
    if (_currentIndex > 0) {
      setState(() {
        _animationDirection = 'previous';
        _currentIndex--;
      });
      await Future.delayed(const Duration(milliseconds: 400));
      _speakContent();
    }
  }

  void _resetCurrentIndex() {
    setState(() {
      _animationDirection = null;
      _currentIndex = 0;
    });
  }

  void _showCompletionDialog() async {
    await flutterTts.stop();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: AnimationController(
              duration: const Duration(milliseconds: 400),
              vsync: this,
            )..forward(),
            curve: Curves.easeOutBack,
          ),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: const Color(0xFFFFF6DC),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: ResponsiveUtils.getResponsivePadding(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/star.png',
                      height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 120),
                      width: ResponsiveUtils.getResponsiveIconSize(context, mobile: 120),
                    ),
                    ResponsiveSpacing(mobileSpacing: 20),
                    ResponsiveText(
                      "What would you like to do next?",
                      style: TextStyle(
                        color: Color(0xFF4C4F6B),
                        fontWeight: FontWeight.w600,
                      ),
                      mobileFontSize: 20,
                      tabletFontSize: 22,
                      desktopFontSize: 24,
                      largeDesktopFontSize: 26,
                      textAlign: TextAlign.center,
                    ),
                    ResponsiveSpacing(mobileSpacing: 30),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDialogButton(
                          label: "Restart Module",
                          color: Color(0xFF4C4F6B),
                          onPressed: () {
                            _resetCurrentIndex();
                            Navigator.pop(context);
                            _speakContent();
                          },
                        ),
                        ResponsiveSpacing(mobileSpacing: 20),
                        _buildDialogButton(
                          label: "Take Assessment",
                          color: Color(0xFF3C7E71),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LearnShapeAssessment(nickname: widget.nickname),
                              ),
                            );
                          },
                        ),
                      ],
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

  Widget _buildDialogButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 50),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 12),
            ),
          ),
          padding: ResponsiveUtils.getResponsivePadding(context),
        ),
        child: ResponsiveText(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          mobileFontSize: 16,
          tabletFontSize: 18,
          desktopFontSize: 20,
          largeDesktopFontSize: 22,
        ),
      ),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = _items[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      body: SafeArea(
        child: ResponsiveWidget(
          mobile: _buildLayout(context, item),
          tablet: _buildLayout(context, item),
          desktop: _buildLayout(context, item),
          largeDesktop: _buildLayout(context, item),
        ),
      ),
    );
  }

  Widget _buildLayout(BuildContext context, Map<String, dynamic> item) {
    return SingleChildScrollView(
      child: Padding(
        padding: ResponsiveUtils.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ResponsiveSpacing(mobileSpacing: 20),
            _buildBackButton(context),
            ResponsiveSpacing(mobileSpacing: 20),
            _buildTitle(context),
            ResponsiveSpacing(mobileSpacing: 20),
            _buildContentCard(context, item),
            ResponsiveSpacing(mobileSpacing: 30),
            _buildNavigationButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Align(
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
    );
  }

  Widget _buildTitle(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 800),
      child: ResponsiveText(
        'Learn the Shapes',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF4A4E69),
        ),
        mobileFontSize: 28,
        tabletFontSize: 32,
        desktopFontSize: 36,
        largeDesktopFontSize: 40,
      ),
    );
  }

  Widget _buildContentCard(BuildContext context, Map<String, dynamic> item) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final offsetAnimation = Tween<Offset>(
          begin: _animationDirection == 'next'
              ? const Offset(1.0, 0.0)
              : _animationDirection == 'previous'
                  ? const Offset(-1.0, 0.0)
                  : const Offset(0.0, 0.0),
          end: const Offset(0.0, 0.0),
        ).animate(animation);
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Container(
        key: ValueKey<int>(_currentIndex),
        width: ResponsiveUtils.isSmallScreen(context)
            ? MediaQuery.of(context).size.width * 0.9
            : ResponsiveUtils.getResponsiveIconSize(context, mobile: 600),
        height: ResponsiveUtils.isSmallScreen(context)
            ? MediaQuery.of(context).size.height * 0.45
            : ResponsiveUtils.getResponsiveIconSize(context, mobile: 600),
        padding: ResponsiveUtils.getResponsivePadding(context),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 16),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ResponsiveText(
                  item['type'] == 'shape' ? item['name']! : 'Example',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4E69),
                  ),
                  mobileFontSize: 40,
                  tabletFontSize: 45,
                  desktopFontSize: 50,
                  largeDesktopFontSize: 55,
                ),
                ResponsiveSpacing(mobileSpacing: 10, isVertical: false),
                IconButton(
                  icon: ResponsiveIcon(
                    Icons.volume_up,
                    color: Color(0xFF648BA2),
                    mobileSize: 40,
                    tabletSize: 45,
                    desktopSize: 45,
                    largeDesktopSize: 50,
                  ),
                  onPressed: _speakContent,
                ),
              ],
            ),

            ResponsiveSpacing(mobileSpacing: 20),

            AnimatedScale(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              scale: 1.0,
              child: Image.asset(
                item['image']!,
                height: ResponsiveUtils.isSmallScreen(context)
                    ? 200
                    : 350,
                width: ResponsiveUtils.isSmallScreen(context)
                    ? 200
                    : 350,
                fit: BoxFit.contain,
              ),
            ),

            if (item['type'] == 'example') ...[
              ResponsiveSpacing(mobileSpacing: 25),

              ResponsiveText(
                item['description']!,
                style: TextStyle(
                  color: Color(0xFF4A4E69),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                mobileFontSize: 30,
                tabletFontSize: 35,
                desktopFontSize: 40,
                largeDesktopFontSize: 40,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 🔥 UPDATED — BIGGER PREVIOUS / NEXT BUTTONS
  // ------------------------------------------------------------
  Widget _buildNavigationButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _currentIndex == 0 ? null : _previousShape,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _currentIndex == 0 ? Colors.grey : const Color(0xFF648BA2),
            padding: EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 40,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: ResponsiveText(
            'Previous',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            mobileFontSize: 26,
            tabletFontSize: 30,
            desktopFontSize: 34,
            largeDesktopFontSize: 38,
          ),
        ),

        ResponsiveSpacing(mobileSpacing: 20, isVertical: false),

        ElevatedButton(
          onPressed: _nextShape,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF648BA2),
            padding: EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 40,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: ResponsiveText(
            'Next',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            mobileFontSize: 26,
            tabletFontSize: 30,
            desktopFontSize: 34,
            largeDesktopFontSize: 38,
          ),
        ),
      ],
    );
  }
}
